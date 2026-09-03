import 'package:flutter/foundation.dart';
import '../../../core/storage/hive_storage.dart';
import '../models/progression.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../core/network/sync_service.dart';

extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T? lastWhereOrNull(bool Function(T element) test) {
    for (int i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}

class ProgressionService extends ChangeNotifier {
  static const Duration _cacheTtl = Duration(minutes: 5);

  DateTime? _lastSyncTime;
  bool _isSyncingAll = false;
  final Set<String> _syncingMangaIds = {};

  String get _currentUserId => getIt<MangaApiService>().userId ?? '';

  Future<void> saveProgression(MangaProgression progression) async {
    // 1. Update local cache (merge) and notify UI immediately
    await _updateLocalCache(progression, overwrite: false, notify: true);

    // 2. Try API
    final apiService = getIt<MangaApiService>();
    final payload = progression.toApiRequest(_currentUserId);
    try {
      final response = await apiService.updateUserProgression(payload);
      if (response.isNotEmpty) {
        final updatedProgression = MangaProgression.fromMap(response);
        await _updateLocalCache(
          updatedProgression.copyWith(
            manga: progression.manga ?? updatedProgression.manga,
          ),
          overwrite: true,
          notify: false,
        );
      }
    } catch (e) {
      // 3. Queue for sync if failed
      getIt<SyncService>().enqueueAction(
        'progression_update',
        payload,
      );
    }
  }

  Future<MangaProgression?> getProgression(
    String mangaId, {
    bool syncFromApi = false,
  }) async {
    // 1. Return local cache immediately
    final progressions = await _loadFromLocalCache();
    final local = progressions.firstWhereOrNull((p) => p.mangaId == mangaId);

    // 2. Background sync only if explicitly requested or if no local data
    if ((syncFromApi || local == null) && !_syncingMangaIds.contains(mangaId)) {
      syncProgressionFromApi(mangaId);
    }

    return local;
  }

  Future<MangaProgression?> syncProgressionFromApi(String mangaId) async {
    if (_currentUserId.isEmpty || _syncingMangaIds.contains(mangaId)) {
      final local = await _loadFromLocalCache();
      return local.firstWhereOrNull((p) => p.mangaId == mangaId);
    }
    _syncingMangaIds.add(mangaId);

    try {
      final apiService = getIt<MangaApiService>();
      final syncService = getIt<SyncService>();
      final isPendingSync = syncService
          .getPendingMangaIdsForType('progression_update')
          .contains(mangaId);
      final localList = await _loadFromLocalCache();
      final local = localList.firstWhereOrNull((p) => p.mangaId == mangaId);

      final data = await apiService.getProgressionForManga(_currentUserId, mangaId);
      if (data != null) {
        final remoteProgression = MangaProgression.fromMap(data);

        // Conflict resolution: if local has newer offline progress pending sync, preserve local
        if (local != null &&
            local.lastReadAt.isAfter(remoteProgression.lastReadAt) &&
            isPendingSync) {
          return local;
        }

        final merged = remoteProgression.copyWith(
          manga: remoteProgression.manga ?? local?.manga,
        );
        await _updateLocalCache(merged, overwrite: true, notify: true);
        return merged;
      } else {
        // If deleted on remote (e.g. from Device A) and not pending sync locally
        if (!isPendingSync && local != null) {
          await deleteProgression(mangaId);
          return null;
        }
      }
    } catch (_) {
    } finally {
      _syncingMangaIds.remove(mangaId);
    }
    final local = await _loadFromLocalCache();
    return local.firstWhereOrNull((p) => p.mangaId == mangaId);
  }

  Future<List<MangaProgression>> getAllProgressions({
    bool forceSync = false,
  }) async {
    final local = await _loadFromLocalCache();

    final isStale = _lastSyncTime == null ||
        DateTime.now().difference(_lastSyncTime!) > _cacheTtl;

    if (forceSync || (isStale && local.isEmpty)) {
      _syncAllProgressionsFromApi();
    }

    return local;
  }

  Future<void> refreshFromApi() async {
    await _syncAllProgressionsFromApi();
  }

  Future<void> _syncAllProgressionsFromApi() async {
    if (_currentUserId.isEmpty || _isSyncingAll) return;
    _isSyncingAll = true;

    try {
      final apiService = getIt<MangaApiService>();
      final syncService = getIt<SyncService>();
      final data = await apiService.getUserProgression(_currentUserId);
      _lastSyncTime = DateTime.now();

      final apiProgressions = data
          .map((json) => MangaProgression.fromMap(json))
          .toList();

      final localList = await _loadFromLocalCache();
      final localMap = {for (final p in localList) p.mangaId: p};
      final pendingSyncMangaIds =
          syncService.getPendingMangaIdsForType('progression_update');

      final List<MangaProgression> merged = [];
      final apiMangaIds = <String>{};

      for (final apiProg in apiProgressions) {
        apiMangaIds.add(apiProg.mangaId);
        final local = localMap[apiProg.mangaId];

        if (local == null) {
          // New progression from remote (e.g. read on Device A)
          merged.add(apiProg);
        } else {
          // Conflict resolution: compare timestamps
          if (local.lastReadAt.isAfter(apiProg.lastReadAt) &&
              pendingSyncMangaIds.contains(local.mangaId)) {
            // Local device read newer chapter offline
            merged.add(local);
          } else {
            // Server (e.g. Device A) is newer or equal
            merged.add(apiProg.copyWith(
              manga: apiProg.manga ?? local.manga,
            ));
          }
        }
      }

      // Check items that exist locally but NOT on server:
      for (final local in localList) {
        if (!apiMangaIds.contains(local.mangaId)) {
          if (pendingSyncMangaIds.contains(local.mangaId)) {
            // Read offline on this device, waiting to be synced to server
            merged.add(local);
          } else {
            // Deleted from server (e.g. removed on Device A) -> remove from Hive
            try {
              await HiveStorage.progressionBox.delete(local.mangaId);
            } catch (_) {}
          }
        }
      }

      await _saveAllToLocalCache(merged, notify: true);
      syncService.syncPendingActions();
    } catch (_) {
    } finally {
      _isSyncingAll = false;
    }
  }

  Future<void> deleteProgression(String mangaId) async {
    final progressions = await _loadFromLocalCache();
    progressions.removeWhere((p) => p.mangaId == mangaId);
    _memoryCache = List<MangaProgression>.from(progressions);
    try {
      await HiveStorage.progressionBox.delete(mangaId);
    } catch (_) {}
    notifyListeners();
  }

  List<MangaProgression>? _memoryCache;

  Future<void> clearAllProgressions() async {
    try {
      await HiveStorage.progressionBox.clear();
    } catch (_) {}
    _memoryCache = [];
    _lastSyncTime = null;
    notifyListeners();
  }

  Future<void> _updateLocalCache(
    MangaProgression progression, {
    bool overwrite = false,
    bool notify = true,
  }) async {
    final progressions = await _loadFromLocalCache();
    final index = progressions.indexWhere(
      (p) => p.mangaId == progression.mangaId,
    );

    MangaProgression targetProgression;
    if (index >= 0) {
      if (overwrite) {
        progressions[index] = progression;
        targetProgression = progression;
      } else {
        final existing = progressions[index];
        final updatedLogs = List<UserChapterLog>.from(existing.chapterLogs);

        for (final newLog in progression.chapterLogs) {
          final logIndex = updatedLogs.indexWhere(
            (l) => l.chapterId == newLog.chapterId,
          );
          if (logIndex >= 0) {
            final existingLog = updatedLogs[logIndex];
            updatedLogs[logIndex] = UserChapterLog(
              id: newLog.id.isEmpty ? existingLog.id : newLog.id,
              chapterId: newLog.chapterId,
              chapterNumber: newLog.chapterNumber,
              lastReadPage: newLog.lastReadPage,
              totalPages: newLog.totalPages,
              isCompleted: newLog.isCompleted,
              readingTimeSeconds: newLog.readingTimeSeconds,
              lastReadAt: newLog.lastReadAt,
            );
          } else {
            updatedLogs.add(newLog);
          }
        }

        final totalReadingTime = updatedLogs.fold<int>(
          0,
          (sum, log) => sum + log.readingTimeSeconds,
        );

        targetProgression = existing.copyWith(
          chapterLogs: updatedLogs,
          totalReadingTime: totalReadingTime,
          lastReadAt: progression.lastReadAt,
          manga: progression.manga ?? existing.manga,
        );
        progressions[index] = targetProgression;
      }
    } else {
      progressions.add(progression);
      targetProgression = progression;
    }

    _memoryCache = List<MangaProgression>.from(progressions);
    if (notify) {
      notifyListeners();
    }
    try {
      await HiveStorage.progressionBox.put(targetProgression.mangaId, targetProgression.toJson());
    } catch (_) {}
  }

  Future<void> _saveAllToLocalCache(
    List<MangaProgression> progressions, {
    bool notify = true,
  }) async {
    _memoryCache = List<MangaProgression>.from(progressions);
    if (notify) {
      notifyListeners();
    }
    try {
      final box = HiveStorage.progressionBox;
      await box.clear();
      final map = <String, dynamic>{};
      for (final p in progressions) {
        map[p.mangaId] = p.toJson();
      }
      await box.putAll(map);
    } catch (_) {}
  }

  Future<List<MangaProgression>> _loadFromLocalCache() async {
    if (_memoryCache != null) {
      return List<MangaProgression>.from(_memoryCache!);
    }
    try {
      final box = HiveStorage.progressionBox;
      final list = <MangaProgression>[];
      for (final value in box.values) {
        if (value is String) {
          try {
            list.add(MangaProgression.fromJson(value));
          } catch (_) {}
        }
      }
      _memoryCache = list;
      return List<MangaProgression>.from(list);
    } catch (_) {
      return [];
    }
  }
}


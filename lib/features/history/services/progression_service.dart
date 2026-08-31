import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _progressionKey = 'manga_progression';
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
      final data = await apiService.getProgressionForManga(_currentUserId, mangaId);
      if (data != null) {
        final progression = MangaProgression.fromMap(data);
        await _updateLocalCache(progression, overwrite: true, notify: true);
        return progression;
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
      final data = await apiService.getUserProgression(_currentUserId);
      _lastSyncTime = DateTime.now();

      final apiProgressions = data
          .map((json) => MangaProgression.fromMap(json))
          .toList();

      final localList = await _loadFromLocalCache();
      final localMap = {for (final p in localList) p.mangaId: p};

      final merged = apiProgressions.map((apiProg) {
        final local = localMap[apiProg.mangaId];
        return apiProg.copyWith(
          manga: apiProg.manga ?? local?.manga,
        );
      }).toList();

      // If there are local progressions not yet on remote, retain them
      final apiMangaIds = apiProgressions.map((e) => e.mangaId).toSet();
      for (final local in localList) {
        if (!apiMangaIds.contains(local.mangaId)) {
          merged.add(local);
        }
      }

      await _saveAllToLocalCache(merged, notify: true);
      getIt<SyncService>().syncPendingActions();
    } catch (_) {
    } finally {
      _isSyncingAll = false;
    }
  }

  Future<void> deleteProgression(String mangaId) async {
    final progressions = await _loadFromLocalCache();
    progressions.removeWhere((p) => p.mangaId == mangaId);
    await _saveAllToLocalCache(progressions, notify: true);
  }

  List<MangaProgression>? _memoryCache;

  Future<void> clearAllProgressions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressionKey);
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

    if (index >= 0) {
      if (overwrite) {
        progressions[index] = progression;
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

        progressions[index] = existing.copyWith(
          chapterLogs: updatedLogs,
          totalReadingTime: totalReadingTime,
          lastReadAt: progression.lastReadAt,
          manga: progression.manga ?? existing.manga,
        );
      }
    } else {
      progressions.add(progression);
    }
    await _saveAllToLocalCache(progressions, notify: notify);
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
      final prefs = await SharedPreferences.getInstance();
      final jsonList = progressions.map((p) => p.toJson()).toList();
      await prefs.setStringList(_progressionKey, jsonList);
    } catch (_) {}
  }

  Future<List<MangaProgression>> _loadFromLocalCache() async {
    if (_memoryCache != null) {
      return List<MangaProgression>.from(_memoryCache!);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_progressionKey) ?? [];
      final list = <MangaProgression>[];
      for (final json in jsonList) {
        try {
          list.add(MangaProgression.fromJson(json));
        } catch (_) {}
      }
      _memoryCache = list;
      return List<MangaProgression>.from(list);
    } catch (_) {
      return [];
    }
  }
}


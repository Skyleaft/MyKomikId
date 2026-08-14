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

class ProgressionService {
  static const _progressionKey = 'manga_progression';

  String get _currentUserId => getIt<MangaApiService>().userId ?? '';

  Future<void> saveProgression(MangaProgression progression) async {
    // 1. Update local cache (merge)
    await _updateLocalCache(progression, overwrite: false);

    // 2. Try API
    final apiService = getIt<MangaApiService>();
    final payload = progression.toApiRequest(_currentUserId);
    try {
      final response = await apiService.updateUserProgression(payload);
      final updatedProgression = MangaProgression.fromMap(response);
      await _updateLocalCache(updatedProgression, overwrite: true);
    } catch (e) {
      // 3. Queue for sync if failed
      getIt<SyncService>().enqueueAction(
        'progression_update',
        payload,
      );
    }
  }

  Future<MangaProgression?> getProgression(String mangaId) async {
    // 1. Return local cache immediately
    final progressions = await _loadFromLocalCache();
    final local = progressions.firstWhereOrNull((p) => p.mangaId == mangaId);

    // 2. Background sync from API
    _syncProgressionFromApi(mangaId);

    return local;
  }

  Future<void> _syncProgressionFromApi(String mangaId) async {
    try {
      final apiService = getIt<MangaApiService>();
      final data = await apiService.getProgressionForManga(_currentUserId, mangaId);
      if (data != null) {
        final progression = MangaProgression.fromMap(data);
        await _updateLocalCache(progression, overwrite: true);
      }
    } catch (_) {}
  }

  Future<List<MangaProgression>> getAllProgressions() async {
    final local = await _loadFromLocalCache();
    _syncAllProgressionsFromApi();
    return local;
  }

  Future<void> refreshFromApi() async {
    await _syncAllProgressionsFromApi();
  }

  Future<void> _syncAllProgressionsFromApi() async {
    try {
      final apiService = getIt<MangaApiService>();
      final data = await apiService.getUserProgression(_currentUserId);
      final progressions = data
          .map((json) => MangaProgression.fromMap(json))
          .toList();

      await _saveAllToLocalCache(progressions);
      getIt<SyncService>().syncPendingActions();
    } catch (_) {}
  }

  Future<void> deleteProgression(String mangaId) async {
    final progressions = await _loadFromLocalCache();
    progressions.removeWhere((p) => p.mangaId == mangaId);
    await _saveAllToLocalCache(progressions);
  }

  Future<void> clearAllProgressions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressionKey);
  }

  Future<void> _updateLocalCache(
    MangaProgression progression, {
    bool overwrite = false,
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
        );
      }
    } else {
      progressions.add(progression);
    }
    await _saveAllToLocalCache(progressions);
  }

  Future<void> _saveAllToLocalCache(List<MangaProgression> progressions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = progressions.map((p) => p.toJson()).toList();
    await prefs.setStringList(_progressionKey, jsonList);
  }

  Future<List<MangaProgression>> _loadFromLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_progressionKey) ?? [];
    return jsonList.map((json) => MangaProgression.fromJson(json)).toList();
  }
}

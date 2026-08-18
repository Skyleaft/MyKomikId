import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_detail.dart';

/// Caches [MangaDetail] objects locally using SharedPreferences with TTL timestamps
/// so the app can display detail pages while offline and know when cache is stale.
class MangaDetailService {
  static const _prefix = 'manga_detail_';
  static const _timePrefix = 'manga_detail_time_';
  static const Duration defaultTtl = Duration(hours: 6);

  String _key(String mangaId) => '$_prefix$mangaId';
  String _timeKey(String mangaId) => '$_timePrefix$mangaId';

  /// Persist a [MangaDetail] to local storage along with current timestamp.
  Future<void> saveDetail(MangaDetail detail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_key(detail.id), detail.toJson()),
        prefs.setInt(_timeKey(detail.id), DateTime.now().millisecondsSinceEpoch),
      ]);
    } catch (_) {}
  }

  /// Retrieve a cached [MangaDetail] by [mangaId], or `null` if none exists.
  Future<MangaDetail?> getDetail(String mangaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key(mangaId));
      if (json == null) return null;
      return MangaDetail.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Check if the cache for [mangaId] is expired based on [ttl].
  Future<bool> isCacheStale(String mangaId, {Duration ttl = defaultTtl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimeMs = prefs.getInt(_timeKey(mangaId));
      if (savedTimeMs == null) return true;

      final savedTime = DateTime.fromMillisecondsSinceEpoch(savedTimeMs);
      return DateTime.now().difference(savedTime) > ttl;
    } catch (_) {
      return true;
    }
  }

  /// Remove a cached detail entry.
  Future<void> removeDetail(String mangaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_key(mangaId)),
        prefs.remove(_timeKey(mangaId)),
      ]);
    } catch (_) {}
  }

  /// Clears older cached entries if cache count exceeds [maxEntries] to avoid storage bloat.
  Future<void> pruneOldCache({int maxEntries = 50}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().where((k) => k.startsWith(_timePrefix)).toList();
      if (allKeys.length <= maxEntries) return;

      final entries = <MapEntry<String, int>>[];
      for (final key in allKeys) {
        final val = prefs.getInt(key);
        if (val != null) entries.add(MapEntry(key, val));
      }

      // Sort by timestamp ascending (oldest first)
      entries.sort((a, b) => a.value.compareTo(b.value));

      final itemsToRemoveCount = entries.length - maxEntries;
      for (int i = 0; i < itemsToRemoveCount; i++) {
        final timeKey = entries[i].key;
        final mangaId = timeKey.substring(_timePrefix.length);
        await removeDetail(mangaId);
      }
    } catch (_) {}
  }
}

import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../core/storage/hive_storage.dart';
import '../models/manga_detail.dart';

/// Caches [MangaDetail] objects locally using Hive with TTL timestamps
/// so the app can display detail pages while offline and know when cache is stale.
class MangaDetailService {
  static const Duration defaultTtl = Duration(hours: 6);

  Box<dynamic> get _box => HiveStorage.mangaDetailBox;

  /// Persist a [MangaDetail] to local storage along with current timestamp.
  Future<void> saveDetail(MangaDetail detail) async {
    try {
      await _box.put(detail.id, {
        'json': detail.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  /// Retrieve a cached [MangaDetail] by [mangaId], or `null` if none exists.
  Future<MangaDetail?> getDetail(String mangaId) async {
    try {
      final data = _box.get(mangaId);
      if (data == null) return null;
      if (data is Map) {
        final json = data['json'] as String?;
        if (json == null) return null;
        return MangaDetail.fromJson(json);
      } else if (data is String) {
        return MangaDetail.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Check if the cache for [mangaId] is expired based on [ttl].
  Future<bool> isCacheStale(String mangaId, {Duration ttl = defaultTtl}) async {
    try {
      final data = _box.get(mangaId);
      if (data == null) return true;
      int? savedTimeMs;
      if (data is Map) {
        savedTimeMs = data['timestamp'] as int?;
      }
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
      await _box.delete(mangaId);
    } catch (_) {}
  }

  /// Clear all cached detail entries.
  Future<void> clearAll() async {
    try {
      await _box.clear();
    } catch (_) {}
  }

  /// Clears older cached entries if cache count exceeds [maxEntries] to avoid storage bloat.
  Future<void> pruneOldCache({int maxEntries = 50}) async {
    try {
      if (_box.length <= maxEntries) return;

      final entries = <MapEntry<dynamic, int>>[];
      for (final key in _box.keys) {
        final val = _box.get(key);
        if (val is Map && val['timestamp'] is int) {
          entries.add(MapEntry(key, val['timestamp'] as int));
        } else {
          entries.add(MapEntry(key, 0));
        }
      }

      // Sort by timestamp ascending (oldest first)
      entries.sort((a, b) => a.value.compareTo(b.value));

      final itemsToRemoveCount = entries.length - maxEntries;
      for (int i = 0; i < itemsToRemoveCount; i++) {
        await _box.delete(entries[i].key);
      }
    } catch (_) {}
  }
}

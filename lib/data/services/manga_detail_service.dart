import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_detail.dart';

/// Caches [MangaDetail] objects locally using SharedPreferences so the app
/// can display detail pages while offline.
class MangaDetailService {
  static const _prefix = 'manga_detail_';

  String _key(String mangaId) => '$_prefix$mangaId';

  /// Persist a [MangaDetail] to local storage.
  Future<void> saveDetail(MangaDetail detail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(detail.id), detail.toJson());
  }

  /// Retrieve a cached [MangaDetail] by [mangaId], or `null` if none exists.
  Future<MangaDetail?> getDetail(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key(mangaId));
    if (json == null) return null;
    try {
      return MangaDetail.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Remove a cached detail entry.
  Future<void> removeDetail(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(mangaId));
  }
}

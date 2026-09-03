import '../../../core/storage/hive_storage.dart';
import '../models/library_manga.dart';
import '../../history/models/progression.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../core/network/sync_service.dart';
import '../../../core/services/notification_service.dart';

class LibraryService {

  String get _currentUserId => getIt<MangaApiService>().userId ?? '';

  Future<void> addToLibrary(LibraryManga manga) async {
    // 1. Update local cache immediately
    await _updateLocalCache(manga, isRemoving: false);

    // 2. Subscribe to FCM topic for chapter updates
    getIt<NotificationService>().subscribeToMangaTopic(manga.id);

    // 3. Try API
    final apiService = getIt<MangaApiService>();
    final payload = manga.toApiRequest(_currentUserId);
    try {
      await apiService.addToUserLibrary(payload);
    } catch (e) {
      // 4. Queue for sync if failed
      getIt<SyncService>().enqueueAction('library_add', payload);
    }
  }

  Future<void> updateStatus(String mangaId, String newStatus) async {
    final libraryManga = await getLibraryManga(mangaId);
    if (libraryManga == null) return;

    final updated = libraryManga.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    // 1. Update local cache immediately
    await _updateLocalCache(updated, isRemoving: false);

    // 2. Try API
    final apiService = getIt<MangaApiService>();
    final payload = updated.toApiRequest(_currentUserId);
    try {
      await apiService.addToUserLibrary(payload);
    } catch (e) {
      getIt<SyncService>().enqueueAction('library_add', payload);
    }
  }

  Future<void> removeFromLibrary(String mangaId) async {
    final libraryManga = await getLibraryManga(mangaId);
    final targetId = (libraryManga?.userLibraryId.isNotEmpty ?? false)
        ? libraryManga!.userLibraryId
        : mangaId;

    // 1. Update local cache immediately
    await _updateLocalCacheById(mangaId, isRemoving: true);

    // 2. Unsubscribe from FCM topic
    getIt<NotificationService>().unsubscribeFromMangaTopic(mangaId);

    // 3. Try API
    final apiService = getIt<MangaApiService>();
    try {
      await apiService.removeFromUserLibrary(targetId);
    } catch (e) {
      // 4. Queue for sync if failed
      getIt<SyncService>().enqueueAction('library_remove', {
        'mangaId': targetId,
      });
    }
  }

  Future<void> toggleFavorite(String mangaId) async {
    final libraryManga = await getLibraryManga(mangaId);
    if (libraryManga == null) return;

    final updated = libraryManga.copyWith(
      isFavorite: !libraryManga.isFavorite,
      updatedAt: DateTime.now(),
    );

    // 1. Update local cache immediately
    await _updateLocalCache(updated, isRemoving: false);

    // 2. Try API
    final apiService = getIt<MangaApiService>();
    final payload = updated.toApiRequest(_currentUserId);
    try {
      await apiService.addToUserLibrary(payload);
    } catch (e) {
      // 3. Queue for sync if failed
      getIt<SyncService>().enqueueAction('library_add', payload);
    }
  }

  Future<LibraryManga?> getLibraryManga(String mangaId) async {
    final localLibrary = await _loadFromLocalCache();
    _syncLibraryItemFromApi(mangaId);
    try {
      return localLibrary.firstWhere((m) => m.id == mangaId);
    } catch (_) {
      return null;
    }
  }

  static const Duration _cacheTtl = Duration(minutes: 5);
  DateTime? _lastSyncTime;

  Future<List<LibraryManga>> getAllLibraryMangas({
    bool forceSync = false,
  }) async {
    final apiService = getIt<MangaApiService>();
    final syncService = getIt<SyncService>();

    // 1. Return local cache immediately for instant offline access
    final localLibrary = await _loadFromLocalCache();

    final isStale = _lastSyncTime == null ||
        DateTime.now().difference(_lastSyncTime!) > _cacheTtl;

    // 2. Sync with API only if forced or if cache is stale & empty
    if (forceSync || (isStale && localLibrary.isEmpty)) {
      _syncLibraryFromApi(apiService, syncService);
    }

    return localLibrary;
  }

  bool _isSyncing = false;

  Future<void> _syncLibraryFromApi(
    MangaApiService apiService,
    SyncService syncService,
  ) async {
    final userId = _currentUserId;
    if (userId.isEmpty || _isSyncing) return;
    _isSyncing = true;

    try {
      final libraryData = await apiService.getUserLibrary(userId: userId);
      final progressionData = await apiService.getUserProgression(userId);
      _lastSyncTime = DateTime.now();

      final progressions = progressionData
          .map((e) => MangaProgression.fromMap(e))
          .toList();

      final library = libraryData.map((e) {
        final libraryModel = LibraryManga.fromMap(e);
        MangaProgression? progression;
        try {
          progression = progressions.firstWhere(
            (p) => p.mangaId == libraryModel.id,
          );
        } catch (_) {}

        if (progression != null) {
          return libraryModel.copyWith(
            currentChapter: progression.currentChapter,
            currentPage: progression.currentPage,
            totalPages: progression.totalPages,
            isCompleted: progression.isCompleted,
          );
        }
        return libraryModel;
      }).toList();

      await _saveAllToLocalCache(library);

      // Synchronize FCM topics for all items currently in user library
      getIt<NotificationService>().syncLibraryTopics(
        library.map((m) => m.id).toList(),
      );

      syncService.syncPendingActions();
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncLibraryItemFromApi(String mangaId) async {
    try {
      final apiService = getIt<MangaApiService>();
      final userId = _currentUserId;
      final libraryData = await apiService.getUserLibrary(
        userId: userId,
        search: mangaId,
      );

      if (libraryData.isNotEmpty) {
        final fetchedModel = LibraryManga.fromMap(libraryData.first);
        final localLibrary = await _loadFromLocalCache();
        final index = localLibrary.indexWhere((m) => m.id == fetchedModel.id);
        if (index >= 0) {
          localLibrary[index] = fetchedModel;
        } else {
          localLibrary.add(fetchedModel);
        }
        await _saveAllToLocalCache(localLibrary);
      }
    } catch (_) {}
  }

  Future<void> refreshFromApi() async {
    final apiService = getIt<MangaApiService>();
    final syncService = getIt<SyncService>();
    await _syncLibraryFromApi(apiService, syncService);
  }

  Future<bool> isInLibrary(String mangaId) async {
    final localLibrary = await _loadFromLocalCache();
    final inLocal = localLibrary.any((m) => m.id == mangaId);
    _syncLibraryItemFromApi(mangaId);
    return inLocal;
  }

  Future<void> updateMangaProgress(
    String mangaId,
    double currentChapter,
    int currentPage,
    int totalPages,
    bool isCompleted, {
    String chapterId = '',
    int readingTimeSeconds = 0,
  }) async {
    final apiService = getIt<MangaApiService>();
    final payload = {
      'userId': _currentUserId,
      'mangaId': mangaId,
      'chapterId': chapterId,
      'chapterNumber': currentChapter,
      'lastReadPage': currentPage,
      'totalPages': totalPages,
      'isCompleted': isCompleted,
      'readingTimeSeconds': readingTimeSeconds,
    };

    final library = await _loadFromLocalCache();
    final index = library.indexWhere((m) => m.id == mangaId);
    if (index >= 0) {
      library[index] = library[index].copyWith(
        currentChapter: currentChapter,
        currentPage: currentPage,
        totalPages: totalPages,
        isCompleted: isCompleted,
      );
      await _saveAllToLocalCache(library);
    }

    try {
      await apiService.updateUserProgression(payload);
    } catch (e) {
      getIt<SyncService>().enqueueAction('progression_update', payload);
    }
  }

  List<LibraryManga>? _memoryCache;

  Future<void> clearLibrary() async {
    try {
      await HiveStorage.libraryBox.clear();
    } catch (_) {}
    _memoryCache = [];
    await getIt<NotificationService>().clearAllSubscribedTopics();
  }

  Future<void> _updateLocalCache(
    LibraryManga manga, {
    required bool isRemoving,
  }) async {
    final library = await _loadFromLocalCache();
    final index = library.indexWhere((m) => m.id == manga.id);

    if (isRemoving) {
      if (index >= 0) library.removeAt(index);
      try {
        await HiveStorage.libraryBox.delete(manga.id);
      } catch (_) {}
    } else {
      if (index >= 0) {
        library[index] = manga;
      } else {
        library.add(manga);
      }
      try {
        await HiveStorage.libraryBox.put(manga.id, manga.toJson());
      } catch (_) {}
    }
    _memoryCache = List<LibraryManga>.from(library);
  }

  Future<void> _updateLocalCacheById(
    String mangaId, {
    required bool isRemoving,
  }) async {
    final library = await _loadFromLocalCache();
    final index = library.indexWhere((m) => m.id == mangaId);

    if (isRemoving && index >= 0) {
      library.removeAt(index);
      try {
        await HiveStorage.libraryBox.delete(mangaId);
      } catch (_) {}
      _memoryCache = List<LibraryManga>.from(library);
    }
  }

  Future<void> _saveAllToLocalCache(List<LibraryManga> library) async {
    _memoryCache = List<LibraryManga>.from(library);
    try {
      final box = HiveStorage.libraryBox;
      await box.clear();
      final map = <String, dynamic>{};
      for (final manga in library) {
        map[manga.id] = manga.toJson();
      }
      await box.putAll(map);
    } catch (_) {}
  }

  Future<List<LibraryManga>> _loadFromLocalCache() async {
    if (_memoryCache != null) {
      return List<LibraryManga>.from(_memoryCache!);
    }
    try {
      final box = HiveStorage.libraryBox;
      final list = <LibraryManga>[];
      for (final value in box.values) {
        if (value is String) {
          try {
            list.add(LibraryManga.fromJson(value));
          } catch (_) {}
        }
      }
      _memoryCache = list;
      return List<LibraryManga>.from(list);
    } catch (_) {
      return [];
    }
  }
}

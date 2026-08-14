import 'package:flutter/foundation.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../core/models/manga_summary.dart';
import '../../history/models/progression.dart';
import '../../history/services/progression_service.dart';
import '../../library/models/library_manga.dart';
import '../../library/services/library_service.dart';
import '../models/manga_detail.dart';
import '../services/manga_detail_service.dart';

class MangaDetailController extends ChangeNotifier {
  final MangaDetail manga;
  final MangaApiService _apiService;
  final ProgressionService _progressionService;
  final LibraryService _libraryService;
  final MangaDetailService _detailService;

  List<Chapter> _chapters = [];
  bool _isLoadingChapters = true;
  bool _isInLibrary = false;
  bool _isFavorite = false;
  MangaProgression? _progression;
  List<MangaSummary> _recommendations = [];
  bool _isLoadingRecommendations = false;
  String? _recommendationErrorMessage;
  String? _recommendationStatus;
  String? _recommendationType;
  List<String> _recommendationGenres = [];
  bool _isAscending = false;
  String _searchQuery = '';

  List<Chapter> get chapters => _chapters;
  bool get isLoadingChapters => _isLoadingChapters;
  bool get isInLibrary => _isInLibrary;
  bool get isFavorite => _isFavorite;
  MangaProgression? get progression => _progression;
  List<MangaSummary> get recommendations => _recommendations;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  String? get recommendationErrorMessage => _recommendationErrorMessage;
  String? get recommendationStatus => _recommendationStatus;
  String? get recommendationType => _recommendationType;
  List<String> get recommendationGenres =>
      List.unmodifiable(_recommendationGenres);
  int get recommendationFilterCount =>
      (_recommendationStatus != null ? 1 : 0) +
      (_recommendationType != null ? 1 : 0) +
      _recommendationGenres.length;
  bool get hasRecommendationFilters => recommendationFilterCount > 0;
  bool get isAscending => _isAscending;
  String get searchQuery => _searchQuery;

  MangaDetailController({
    required this.manga,
    MangaApiService? apiService,
    ProgressionService? progressionService,
    LibraryService? libraryService,
    MangaDetailService? detailService,
  }) : _apiService = apiService ?? getIt<MangaApiService>(),
       _progressionService = progressionService ?? getIt<ProgressionService>(),
       _libraryService = libraryService ?? getIt<LibraryService>(),
       _detailService = detailService ?? getIt<MangaDetailService>() {
    _chapters = List.from(manga.chapters);
    _sortChapters();
  }

  Future<void> init() async {
    await Future.wait([
      _loadChapters(),
      _loadProgression(),
      _checkIfInLibrary(),
    ]);
  }

  List<Chapter> get filteredChapters {
    if (_searchQuery.isEmpty) return _chapters;
    return _chapters.where((c) {
      final titleMatch = c.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final numberMatch = c.chapterNumber.toString().contains(_searchQuery);
      return titleMatch || numberMatch;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSort() {
    _isAscending = !_isAscending;
    _sortChapters();
    notifyListeners();
  }

  void _sortChapters() {
    _chapters.sort((a, b) {
      if (_isAscending) {
        return a.chapterNumber.compareTo(b.chapterNumber);
      } else {
        return b.chapterNumber.compareTo(a.chapterNumber);
      }
    });
  }

  Future<void> refreshProgression() async {
    _progression = await _progressionService.getProgression(manga.id);
    notifyListeners();
  }

  Future<void> _loadProgression() async {
    _progression = await _progressionService.getProgression(manga.id);
    notifyListeners();
  }

  Future<void> _loadChapters() async {
    // 1. Load from local cache first for instant offline display
    final cached = await _detailService.getDetail(manga.id);
    if (cached != null && cached.chapters.isNotEmpty) {
      _chapters = cached.chapters;
      _sortChapters();
      _isLoadingChapters = false;
      notifyListeners();
    }

    // 2. Background sync from API
    try {
      final chaptersData = await _apiService.getMangaChapters(manga.id);
      _chapters = chaptersData.map((e) => Chapter.fromMap(e)).toList();
      _sortChapters();
      _isLoadingChapters = false;

      final freshDetail = _buildUpdatedDetail(_chapters);
      await _detailService.saveDetail(freshDetail);
      notifyListeners();
    } catch (_) {
      if (_chapters.isEmpty) {
        _isLoadingChapters = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    _isLoadingChapters = true;
    notifyListeners();

    try {
      final chaptersData = await _apiService.getMangaChapters(manga.id);
      _chapters = chaptersData.map((e) => Chapter.fromMap(e)).toList();
      _sortChapters();
      _isLoadingChapters = false;

      final freshDetail = _buildUpdatedDetail(_chapters);
      await _detailService.saveDetail(freshDetail);
      await refreshProgression();
      await _checkIfInLibrary();
      notifyListeners();
    } catch (_) {
      _isLoadingChapters = false;
      notifyListeners();
    }
  }

  Future<void> _checkIfInLibrary() async {
    final libraryItem = await _libraryService.getLibraryManga(manga.id);
    _isInLibrary = libraryItem != null;
    _isFavorite = libraryItem?.isFavorite ?? false;
    notifyListeners();
  }

  Future<void> loadRecommendations({bool forceReload = false}) async {
    if (_isLoadingRecommendations) return;
    if (!forceReload && _recommendations.isNotEmpty) return;

    _isLoadingRecommendations = true;
    _recommendationErrorMessage = null;
    notifyListeners();

    try {
      final recs = await _apiService.getSimilarMangaFiltered(
        manga.id,
        status: _recommendationStatus,
        type: _recommendationType,
        genres: _recommendationGenres.isNotEmpty ? _recommendationGenres : null,
        limit: 20,
      );
      _recommendations = recs;
    } catch (e) {
      _recommendationErrorMessage = e.toString();
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> setRecommendationFilters({
    String? status,
    String? type,
    List<String>? genres,
  }) async {
    _recommendationStatus = status;
    _recommendationType = type;
    _recommendationGenres = genres != null ? List.from(genres) : [];
    await loadRecommendations(forceReload: true);
  }

  Future<void> toggleRecommendationGenre(String genre) async {
    if (_recommendationGenres.contains(genre)) {
      _recommendationGenres.remove(genre);
    } else {
      _recommendationGenres.add(genre);
    }
    await loadRecommendations(forceReload: true);
  }

  Future<void> removeRecommendationGenre(String genre) async {
    if (_recommendationGenres.remove(genre)) {
      await loadRecommendations(forceReload: true);
    }
  }

  Future<void> setRecommendationType(String? type) async {
    if (_recommendationType == type) {
      _recommendationType = null;
    } else {
      _recommendationType = type;
    }
    await loadRecommendations(forceReload: true);
  }

  Future<void> setRecommendationStatus(String? status) async {
    if (_recommendationStatus == status) {
      _recommendationStatus = null;
    } else {
      _recommendationStatus = status;
    }
    await loadRecommendations(forceReload: true);
  }

  Future<void> clearRecommendationFilters() async {
    if (!hasRecommendationFilters) return;
    _recommendationStatus = null;
    _recommendationType = null;
    _recommendationGenres = [];
    await loadRecommendations(forceReload: true);
  }

  Future<bool> toggleFavorite() async {
    if (!_isInLibrary) return false;
    await _libraryService.toggleFavorite(manga.id);
    _isFavorite = !_isFavorite;
    notifyListeners();
    return _isFavorite;
  }

  Future<void> addToLibrary(String status) async {
    final libraryManga = LibraryManga.fromMangaDetail(
      manga.id,
      manga.title,
      manga.author,
      manga.displayImageUrl,
      manga.url,
      manga.type,
      status: status,
    );
    await _libraryService.addToLibrary(libraryManga);
    _isInLibrary = true;
    _isFavorite = libraryManga.isFavorite;
    notifyListeners();
  }

  Future<void> removeFromLibrary() async {
    await _libraryService.removeFromLibrary(manga.id);
    _isInLibrary = false;
    _isFavorite = false;
    notifyListeners();
  }

  MangaDetail _buildUpdatedDetail(List<Chapter> freshChapters) {
    return MangaDetail(
      id: manga.id,
      malId: manga.malId,
      anilistId: manga.anilistId,
      mangaUpdateId: manga.mangaUpdateId,
      title: manga.title,
      author: manga.author,
      type: manga.type,
      genres: manga.genres,
      categories: manga.categories,
      description: manga.description,
      imageUrl: manga.imageUrl,
      localImageUrl: manga.localImageUrl,
      rating: manga.rating,
      popularity: manga.popularity,
      members: manga.members,
      totalView: manga.totalView,
      status: manga.status,
      releaseDate: manga.releaseDate,
      createdAt: manga.createdAt,
      updatedAt: manga.updatedAt,
      url: manga.url,
      chapters: freshChapters,
    );
  }
}

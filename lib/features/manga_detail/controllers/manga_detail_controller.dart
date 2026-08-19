import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../core/models/manga_summary.dart';
import '../../history/models/progression.dart';
import '../../history/services/progression_service.dart';
import '../../library/models/library_manga.dart';
import '../../library/services/library_service.dart';
import '../models/chapter_scraping_progress.dart';
import '../models/manga_detail.dart';
import '../services/manga_detail_service.dart';
import '../services/manga_signalr_service.dart';

enum ChapterFilterOption {
  all,
  unreadOnly,
  readOnly,
}

class MangaDetailController extends ChangeNotifier {
  final MangaDetail manga;
  final MangaApiService _apiService;
  final ProgressionService _progressionService;
  final LibraryService _libraryService;
  final MangaDetailService _detailService;
  final MangaSignalRService _signalRService;

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
  ChapterFilterOption _chapterFilter = ChapterFilterOption.all;
  ChapterScrapingProgress? _scrapingProgress;

  Timer? _searchDebounce;
  Timer? _clearScrapingTimer;
  CancelToken? _chaptersCancelToken;
  CancelToken? _recommendationsCancelToken;
  StreamSubscription<ChapterScrapingProgress>? _progressSubscription;
  StreamSubscription<ChaptersUpdatedEvent>? _chaptersUpdatedSubscription;

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
  ChapterFilterOption get chapterFilter => _chapterFilter;
  ChapterScrapingProgress? get scrapingProgress => _scrapingProgress;
  bool get isScrapingActive =>
      _scrapingProgress != null &&
      !_scrapingProgress!.isCompleted &&
      !_scrapingProgress!.isFailed;

  MangaDetailController({
    required this.manga,
    MangaApiService? apiService,
    ProgressionService? progressionService,
    LibraryService? libraryService,
    MangaDetailService? detailService,
    MangaSignalRService? signalRService,
  }) : _apiService = apiService ?? getIt<MangaApiService>(),
       _progressionService = progressionService ?? getIt<ProgressionService>(),
       _libraryService = libraryService ?? getIt<LibraryService>(),
       _detailService = detailService ?? getIt<MangaDetailService>(),
       _signalRService = signalRService ?? getIt<MangaSignalRService>() {
    _chapters = List.from(manga.chapters);
    _sortChapters();
  }

  Future<void> init() async {
    _initSignalR();
    await Future.wait([
      _loadChapters(),
      _loadProgression(),
      _checkIfInLibrary(),
    ]);
  }

  void _initSignalR() {
    _signalRService.joinMangaGroup(manga.id);

    _progressSubscription =
        _signalRService.scrapingProgressStream.listen((progress) {
      if (progress.mangaId == manga.id) {
        _clearScrapingTimer?.cancel();
        _scrapingProgress = progress;
        notifyListeners();

        if (progress.isCompleted) {
          // Silently refresh chapters after completion
          Future.delayed(const Duration(milliseconds: 1200), () {
            _silentRefreshChapters();
          });
          // Auto-clear banner after 3.5 seconds
          _clearScrapingTimer = Timer(const Duration(milliseconds: 3500), () {
            _scrapingProgress = null;
            notifyListeners();
          });
        }
      }
    });

    _chaptersUpdatedSubscription =
        _signalRService.chaptersUpdatedStream.listen((event) {
      if (event.mangaId == manga.id) {
        _silentRefreshChapters();
      }
    });
  }

  void startScrapingFeedback() {
    _clearScrapingTimer?.cancel();
    _scrapingProgress = ChapterScrapingProgress(
      mangaId: manga.id,
      mangaTitle: manga.title,
      chapterId: '',
      chapterNumber: 0,
      downloadedPages: 0,
      totalPages: 0,
      percent: 0,
      status: 'Starting',
    );
    notifyListeners();
  }

  void clearScrapingProgress() {
    _clearScrapingTimer?.cancel();
    _scrapingProgress = null;
    notifyListeners();
  }

  Future<void> _silentRefreshChapters() async {
    try {
      final chaptersData = await _apiService.getMangaChapters(manga.id);
      _chapters = chaptersData.map((e) => Chapter.fromMap(e)).toList();
      _sortChapters();
      final freshDetail = _buildUpdatedDetail(_chapters);
      await _detailService.saveDetail(freshDetail);
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _clearScrapingTimer?.cancel();
    _chaptersCancelToken?.cancel();
    _recommendationsCancelToken?.cancel();
    _progressSubscription?.cancel();
    _chaptersUpdatedSubscription?.cancel();
    _signalRService.leaveMangaGroup(manga.id);
    super.dispose();
  }

  List<Chapter> get filteredChapters {
    return _chapters.where((c) {
      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = c.title.toLowerCase().contains(query);
        final numberMatch = c.chapterNumber.toString().contains(query);
        if (!titleMatch && !numberMatch) return false;
      }

      // 2. Read / Unread Status Filter
      if (_chapterFilter != ChapterFilterOption.all) {
        final isRead = isChapterRead(c);
        if (_chapterFilter == ChapterFilterOption.unreadOnly && isRead) {
          return false;
        }
        if (_chapterFilter == ChapterFilterOption.readOnly && !isRead) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool isChapterRead(Chapter chapter) {
    if (_progression == null) return false;
    final log = _progression!.chapterLogs
        .where((l) => l.chapterId == chapter.id || l.chapterNumber == chapter.chapterNumber)
        .firstOrNull;
    return log?.isCompleted ?? false;
  }

  Chapter? get nextUnreadChapter {
    return manga.copyWith(chapters: _chapters).getNextUnreadChapter(_progression);
  }

  double get readProgressPercentage {
    return manga.copyWith(chapters: _chapters).getReadPercentage(_progression);
  }

  void setChapterFilter(ChapterFilterOption filter) {
    _chapterFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      _searchQuery = query.trim();
      notifyListeners();
    });
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

    final isStale = await _detailService.isCacheStale(manga.id);
    if (!isStale && _chapters.isNotEmpty) {
      return;
    }

    // 2. Background sync from API with CancelToken
    _chaptersCancelToken?.cancel();
    _chaptersCancelToken = CancelToken();

    try {
      final chaptersData = await _apiService.getMangaChapters(
        manga.id,
        cancelToken: _chaptersCancelToken,
      );
      _chapters = chaptersData.map((e) => Chapter.fromMap(e)).toList();
      _sortChapters();
      _isLoadingChapters = false;

      final freshDetail = _buildUpdatedDetail(_chapters);
      await _detailService.saveDetail(freshDetail);
      await _detailService.pruneOldCache();
      notifyListeners();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      if (_chapters.isEmpty) {
        _isLoadingChapters = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    _isLoadingChapters = true;
    notifyListeners();

    _chaptersCancelToken?.cancel();
    _chaptersCancelToken = CancelToken();

    try {
      final chaptersData = await _apiService.getMangaChapters(
        manga.id,
        cancelToken: _chaptersCancelToken,
      );
      _chapters = chaptersData.map((e) => Chapter.fromMap(e)).toList();
      _sortChapters();
      _isLoadingChapters = false;

      final freshDetail = _buildUpdatedDetail(_chapters);
      await _detailService.saveDetail(freshDetail);
      await refreshProgression();
      await _checkIfInLibrary();
      notifyListeners();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
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

    _recommendationsCancelToken?.cancel();
    _recommendationsCancelToken = CancelToken();

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
      if (e is DioException && e.type == DioExceptionType.cancel) return;
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
    return manga.copyWith(chapters: freshChapters);
  }
}

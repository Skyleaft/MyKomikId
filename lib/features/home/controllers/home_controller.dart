import 'package:flutter/foundation.dart';
import '../../../core/di/injection.dart';
import '../../../core/models/manga_summary.dart';
import '../../../core/network/manga_api_service.dart';
import '../../history/models/progression.dart';
import '../../history/services/progression_service.dart';
import '../../manga_detail/models/manga_detail.dart';
import '../../manga_detail/services/manga_detail_service.dart';
import '../models/trending_tab.dart';

class HomeController extends ChangeNotifier {
  final MangaApiService _apiService;
  final ProgressionService _progressionService;
  final MangaDetailService _detailService;

  final Map<int, List<MangaSummary>> _trendingByTab = {};
  final Map<int, bool> _trendingLoadingByTab = {};

  List<MangaSummary> _latestUpdates = [];
  List<MangaSummary> _recommendedManga = [];
  List<MangaSummary> _topManga = [];

  List<MangaProgression> _recentProgressions = [];
  Map<String, MangaDetail> _historyDetailsMap = {};
  bool _isLoadingHistory = true;

  bool _isLoadingLatest = true;
  bool _isLoadingRecommended = true;
  bool _isLoadingTop = true;

  Map<int, List<MangaSummary>> get trendingByTab => _trendingByTab;
  Map<int, bool> get trendingLoadingByTab => _trendingLoadingByTab;
  List<MangaSummary> get latestUpdates => _latestUpdates;
  List<MangaSummary> get recommendedManga => _recommendedManga;
  List<MangaSummary> get topManga => _topManga;
  List<MangaProgression> get recentProgressions => _recentProgressions;
  Map<String, MangaDetail> get historyDetailsMap => _historyDetailsMap;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingLatest => _isLoadingLatest;
  bool get isLoadingRecommended => _isLoadingRecommended;
  bool get isLoadingTop => _isLoadingTop;

  HomeController({
    MangaApiService? apiService,
    ProgressionService? progressionService,
    MangaDetailService? detailService,
  })  : _apiService = apiService ?? getIt<MangaApiService>(),
        _progressionService = progressionService ?? getIt<ProgressionService>(),
        _detailService = detailService ?? getIt<MangaDetailService>();

  Future<void> fetchAllData() async {
    await Future.wait([
      fetchHistory(),
      fetchTrendingForTab(0),
      fetchLatest(),
      fetchTop().then((_) => fetchRecommended()),
    ]);
  }

  Future<void> refresh() async {
    _trendingByTab.clear();
    _trendingLoadingByTab.clear();
    await fetchAllData();
  }

  Future<void> fetchTrendingForTab(int tabIdx) async {
    if (_trendingLoadingByTab[tabIdx] == true) return;
    _trendingLoadingByTab[tabIdx] = true;
    notifyListeners();

    try {
      final tab = kTrendingTabs[tabIdx];
      final response = await _apiService.getTrending(
        genres: tab.genre != null ? [tab.genre!] : null,
        pageSize: 10,
      );
      _trendingByTab[tabIdx] = response.items;
    } catch (_) {
    } finally {
      _trendingLoadingByTab[tabIdx] = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final progressions = await _progressionService.getAllProgressions();
      progressions.sort((a, b) => b.lastRead.compareTo(a.lastRead));
      final recent = progressions.take(10).toList();

      final detailsMap = <String, MangaDetail>{};
      for (final p in recent) {
        try {
          final cached = await _detailService.getDetail(p.mangaId);
          if (cached != null) {
            detailsMap[p.mangaId] = cached;
          } else {
            final data = await _apiService.getMangaDetail(p.mangaId);
            final detail = MangaDetail.fromMap(data);
            await _detailService.saveDetail(detail);
            detailsMap[p.mangaId] = detail;
          }
        } catch (_) {}
      }

      _recentProgressions = recent;
      _historyDetailsMap = detailsMap;
    } catch (_) {
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> fetchLatest() async {
    try {
      final response = await _apiService.getPagedManga(
        sortBy: 'updatedAt',
        orderBy: 'desc',
        pageSize: 5,
      );
      _latestUpdates = response.items;
    } catch (_) {
    } finally {
      _isLoadingLatest = false;
      notifyListeners();
    }
  }

  Future<void> fetchTop() async {
    try {
      final response = await _apiService.getPagedManga(
        sortBy: 'rating',
        orderBy: 'desc',
        pageSize: 6,
      );
      _topManga = response.items;
    } catch (_) {
    } finally {
      _isLoadingTop = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecommended() async {
    try {
      final history = await _progressionService.getAllProgressions();
      history.sort((a, b) => b.lastRead.compareTo(a.lastRead));
      List<String> ids = history.take(5).map((e) => e.mangaId).toList();

      if (ids.isEmpty && _topManga.isNotEmpty) {
        ids = [_topManga.first.id];
      }

      final items = await _apiService.getRecommendations(
        readingHistoryIds: ids,
        limit: 6,
      );
      _recommendedManga = items;
    } catch (_) {
    } finally {
      _isLoadingRecommended = false;
      notifyListeners();
    }
  }
}

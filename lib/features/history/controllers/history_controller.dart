import 'package:flutter/foundation.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../manga_detail/models/manga_detail.dart';
import '../../manga_detail/services/manga_detail_service.dart';
import '../models/progression.dart';
import '../services/progression_service.dart';

class HistoryController extends ChangeNotifier {
  final ProgressionService _progressionService;
  final MangaApiService _apiService;
  final MangaDetailService _detailService;

  List<MangaProgression> _progressions = [];
  Map<String, MangaDetail> _mangaDetailsMap = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  List<MangaProgression> get progressions => _progressions;
  Map<String, MangaDetail> get mangaDetailsMap => _mangaDetailsMap;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  HistoryController({
    ProgressionService? progressionService,
    MangaApiService? apiService,
    MangaDetailService? detailService,
  })  : _progressionService = progressionService ?? getIt<ProgressionService>(),
        _apiService = apiService ?? getIt<MangaApiService>(),
        _detailService = detailService ?? getIt<MangaDetailService>();

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool _matchesFilter(DateTime dateTime, String filter) {
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (filter == 'Today') {
      return localDateTime.isAfter(todayStart) ||
          localDateTime.isAtSameMomentAs(todayStart);
    } else if (filter == 'This Week') {
      final weekday = now.weekday;
      final weekStart = todayStart.subtract(Duration(days: weekday - 1));
      return localDateTime.isAfter(weekStart) ||
          localDateTime.isAtSameMomentAs(weekStart);
    } else if (filter == 'This Month') {
      final monthStart = DateTime(now.year, now.month, 1);
      return localDateTime.isAfter(monthStart) ||
          localDateTime.isAtSameMomentAs(monthStart);
    }
    return true;
  }

  List<MangaProgression> get filteredProgressions {
    return _progressions.where((progression) {
      final matchesTime = _matchesFilter(progression.lastRead, _selectedFilter);
      if (!matchesTime) return false;

      if (_searchQuery.isNotEmpty) {
        final detail = _mangaDetailsMap[progression.mangaId];
        final title = detail?.title.toLowerCase() ?? 'unknown manga';
        final query = _searchQuery.toLowerCase();
        return title.contains(query);
      }

      return true;
    }).toList();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _progressionService.getAllProgressions();
      list.sort((a, b) => b.lastRead.compareTo(a.lastRead));
      _progressions = list;

      final detailsMap = <String, MangaDetail>{};
      for (final progression in list) {
        try {
          final cached = await _detailService.getDetail(progression.mangaId);
          if (cached != null) {
            detailsMap[progression.mangaId] = cached;
            _apiService.getMangaDetail(progression.mangaId).then((data) {
              final fresh = MangaDetail.fromMap(data);
              _detailService.saveDetail(fresh);
              _mangaDetailsMap[progression.mangaId] = fresh;
              notifyListeners();
            }).catchError((_) {});
          } else {
            final detailData = await _apiService.getMangaDetail(
              progression.mangaId,
            );
            final mangaDetail = MangaDetail.fromMap(detailData);
            await _detailService.saveDetail(mangaDetail);
            detailsMap[progression.mangaId] = mangaDetail;
          }
        } catch (_) {}
      }

      _mangaDetailsMap = detailsMap;
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../manga_detail/models/manga_detail.dart';
import '../../manga_detail/services/manga_detail_service.dart';
import '../models/library_manga.dart';
import '../services/library_service.dart';

class LibraryController extends ChangeNotifier {
  final LibraryService _libraryService;
  final MangaApiService _apiService;
  final MangaDetailService _detailService;

  List<LibraryManga> _libraryMangas = [];
  Map<String, MangaDetail> _cachedDetails = {};
  bool _isLoading = true;
  String _selectedStatus = 'All';
  String _searchQuery = '';

  List<LibraryManga> get libraryMangas => _libraryMangas;
  Map<String, MangaDetail> get cachedDetails => _cachedDetails;
  bool get isLoading => _isLoading;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  LibraryController({
    LibraryService? libraryService,
    MangaApiService? apiService,
    MangaDetailService? detailService,
  })  : _libraryService = libraryService ?? getIt<LibraryService>(),
        _apiService = apiService ?? getIt<MangaApiService>(),
        _detailService = detailService ?? getIt<MangaDetailService>();

  List<LibraryManga> get filteredMangas {
    return _libraryMangas.where((m) {
      final matchesStatus = _selectedStatus == 'All' ||
          m.status.toLowerCase() == _selectedStatus.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          m.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadLibrary() async {
    try {
      final list = await _libraryService.getAllLibraryMangas();
      final Map<String, MangaDetail> details = {};
      for (final manga in list) {
        final detail = await _detailService.getDetail(manga.id);
        if (detail != null) {
          details[manga.id] = detail;
        }
      }
      _libraryMangas = list;
      _cachedDetails = details;
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      await _apiService.getUserLibrary();
      await _apiService.getUserProgression();
    } catch (_) {}
    await loadLibrary();
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../routes/app_pages.dart';
import '../../manga_detail/models/manga_detail.dart';
import '../../manga_detail/services/manga_detail_service.dart';
import '../../manga_detail/presentation/widgets/status_selection_sheet.dart';
import '../../reader/models/reader_content.dart';
import '../controllers/library_controller.dart';
import '../models/library_manga.dart';
import 'widgets/library_header.dart';
import 'widgets/library_manga_card.dart';
import 'widgets/library_manga_grid_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with RouteAware {
  late final LibraryController _controller;
  final MangaApiService _apiService = getIt<MangaApiService>();
  final MangaDetailService _detailService = getIt<MangaDetailService>();

  @override
  void initState() {
    super.initState();
    _controller = LibraryController();
    _controller.loadLibrary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      AppRoutes.routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    AppRoutes.routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and this screen shows up again
    _controller.loadLibrary();
    _controller.refresh();
  }

  Future<void> _navigateToMangaDetail(String mangaId) async {
    final cached = await _detailService.getDetail(mangaId);

    if (!mounted) return;

    if (cached != null) {
      await Navigator.pushNamed(context, AppRoutes.detail, arguments: cached);
      if (mounted) _controller.loadLibrary();

      _apiService
          .getMangaDetail(mangaId)
          .then((data) {
            final fresh = MangaDetail.fromMap(data);
            _detailService.saveDetail(fresh);
          })
          .catchError((_) {});
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detailData = await _apiService.getMangaDetail(mangaId);
      if (!mounted) return;
      Navigator.pop(context);

      final mangaDetail = MangaDetail.fromMap(detailData);
      await _detailService.saveDetail(mangaDetail);

      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.detail,
        arguments: mangaDetail,
      );
      if (mounted) _controller.loadLibrary();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AlertBanner.show(
        context,
        'Failed to load details: $e',
        type: AlertBannerType.error,
      );
    }
  }

  Future<void> _quickReadManga(LibraryManga manga) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      MangaDetail? detail = _controller.cachedDetails[manga.id];
      detail ??= await _detailService.getDetail(manga.id);

      if (detail == null || detail.chapters.isEmpty) {
        final chaptersData = await _apiService.getMangaChapters(manga.id);
        final chapters = chaptersData.map((e) => Chapter.fromMap(e)).toList();
        detail = (detail ??
            MangaDetail(
              id: manga.id,
              malId: 0,
              title: manga.title,
              author: manga.author,
              type: manga.type,
              popularity: 0,
              members: 0,
              totalView: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              chapters: chapters,
            )).copyWith(chapters: chapters);
      }

      final chapterToRead = detail.chapters.firstWhere(
        (c) => c.chapterNumber == (manga.currentChapter > 0 ? manga.currentChapter : 1.0),
        orElse: () => detail!.chapters.isNotEmpty ? detail.chapters.last : Chapter(
          id: '',
          title: 'Chapter 1',
          chapterNumber: 1,
          date: DateTime.now(),
        ),
      );

      final pages = await _apiService.getChapterPages(manga.id, chapterToRead.id);

      if (!mounted) return;
      Navigator.pop(context);

      final content = ReaderContent(
        mangaId: manga.id,
        mangaTitle: manga.title,
        currentChapterNumber: chapterToRead.chapterNumber,
        chapterId: chapterToRead.id,
        allChapters: detail.chapters,
        chapterTitle: chapterToRead.title,
        pages: pages
            .map((p) => p.copyWith(
                  url: _apiService.getLocalImageUrl(p.url, null),
                ))
            .toList(),
        currentPage: manga.currentPage > 1 ? manga.currentPage : 1,
      );

      await Navigator.pushNamed(context, AppRoutes.reader, arguments: content);
      if (mounted) _controller.loadLibrary();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AlertBanner.show(
          context,
          'Failed to open reader: $e',
          type: AlertBannerType.error,
        );
      }
    }
  }

  void _showMangaOptionsSheet(LibraryManga manga) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        manga.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  manga.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: manga.isFavorite ? Colors.red : null,
                ),
                title: Text(manga.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () {
                  Navigator.pop(context);
                  _controller.toggleMangaFavorite(manga.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded),
                title: Text('Change Status (Current: ${manga.status})'),
                onTap: () async {
                  Navigator.pop(context);
                  final selected = await StatusSelectionSheet.show(context);
                  if (selected != null) {
                    _controller.updateMangaStatus(manga.id, selected);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Remove from Library', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _controller.removeManga(manga.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _controller.refresh,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: (isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight)
                      .withValues(alpha: 0.8),
                  surfaceTintColor: Colors.transparent,
                  expandedHeight: 210,
                  toolbarHeight: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: LibraryHeader(
                          isDark: isDark,
                          selectedStatus: _controller.selectedStatus,
                          showFavoritesOnly: _controller.showFavoritesOnly,
                          isGridView: _controller.isGridView,
                          sortOption: _controller.sortOption,
                          statusCounts: _controller.statusCounts,
                          onSearchChanged: _controller.setSearchQuery,
                          onStatusChanged: _controller.setSelectedStatus,
                          onToggleFavorites: _controller.toggleFavoritesOnly,
                          onToggleViewMode: _controller.toggleViewMode,
                          onSortChanged: _controller.setSortOption,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
                  sliver: _buildContent(context, isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (_controller.isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final filteredMangas = _controller.filteredMangas;

    if (filteredMangas.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              _controller.selectedStatus == 'All'
                  ? 'Your library is empty\nAdd some manga to get started!'
                  : 'No manga found with the selected filter',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_controller.isGridView) {
      final screenWidth = MediaQuery.of(context).size.width;
      final crossAxisCount = screenWidth > 900
          ? 5
          : screenWidth > 600
              ? 3
              : 2;

      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final manga = filteredMangas[index];
          final detail = _controller.cachedDetails[manga.id];
          return LibraryMangaGridCard(
            manga: manga,
            detail: detail,
            isDark: isDark,
            apiService: _apiService,
            onTap: () => _navigateToMangaDetail(manga.id),
            onQuickRead: () => _quickReadManga(manga),
            onLongPress: () => _showMangaOptionsSheet(manga),
          );
        }, childCount: filteredMangas.length),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final manga = filteredMangas[index];
        final detail = _controller.cachedDetails[manga.id];
        return LibraryMangaCard(
          manga: manga,
          detail: detail,
          isDark: isDark,
          apiService: _apiService,
          onTap: () => _navigateToMangaDetail(manga.id),
          onQuickRead: () => _quickReadManga(manga),
          onLongPress: () => _showMangaOptionsSheet(manga),
        );
      }, childCount: filteredMangas.length),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../core/models/manga_summary.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../routes/app_pages.dart';
import '../../reader/models/reader_content.dart';
import '../controllers/manga_detail_controller.dart';
import '../models/manga_detail.dart';
import 'widgets/manga_detail_app_bar.dart';
import 'widgets/manga_detail_genres.dart';
import 'widgets/manga_detail_synopsis.dart';
import 'widgets/manga_detail_floating_dock.dart';
import 'widgets/manga_detail_tab_bar.dart';
import 'widgets/manga_detail_chapter_header.dart';
import 'widgets/manga_detail_chapter_tile.dart';
import 'widgets/manga_detail_recommendations_grid.dart';
import 'widgets/manga_detail_recommendations_header.dart';
import 'widgets/manga_detail_scraping_progress_card.dart';
import 'widgets/similar_manga_filter_sheet.dart';
import 'widgets/status_selection_sheet.dart';

class MangaDetailScreen extends StatefulWidget {
  final MangaDetail manga;
  final String? heroTag;

  const MangaDetailScreen({
    super.key,
    required this.manga,
    this.heroTag,
  });

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen>
    with SingleTickerProviderStateMixin {
  late final MangaDetailController _controller;
  late final TabController _tabController;
  late final ScrollController _scrollController;
  final MangaApiService _apiService = getIt<MangaApiService>();

  @override
  void initState() {
    super.initState();
    _controller = MangaDetailController(manga: widget.manga);
    _scrollController = ScrollController();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _controller.recommendations.isEmpty) {
        _controller.loadRecommendations();
      }
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.init();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToReader(BuildContext context, Chapter chapter) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Opening Chapter ${chapter.chapterNumber % 1 == 0 ? chapter.chapterNumber.toInt() : chapter.chapterNumber}...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final pages = await _apiService.getChapterPages(
        widget.manga.id,
        chapter.id,
      );

      if (context.mounted) {
        Navigator.pop(context);

        final progression = _controller.progression;
        int startingPage = 1;
        if (progression != null) {
          final log = progression.chapterLogs
              .where((l) =>
                  l.chapterId == chapter.id ||
                  l.chapterNumber == chapter.chapterNumber)
              .firstOrNull;
          if (log != null && log.lastReadPage > 0) {
            startingPage = log.lastReadPage;
          } else if (progression.currentChapter == chapter.chapterNumber &&
              progression.currentPage > 0) {
            startingPage = progression.currentPage;
          }
        }

        final content = ReaderContent(
          mangaId: widget.manga.id,
          mangaTitle: widget.manga.title,
          currentChapterNumber: chapter.chapterNumber,
          chapterId: chapter.id,
          allChapters: _controller.chapters,
          chapterTitle: chapter.title,
          pages: pages
              .map((p) => p.copyWith(
                    url: _apiService.getLocalImageUrl(p.url, null),
                  ))
              .toList(),
          currentPage: startingPage,
          progression: progression,
        );

        _controller.pauseSignalR();

        await Navigator.pushNamed(
          context,
          AppRoutes.reader,
          arguments: content,
        );
        if (mounted) {
          _controller.resumeSignalR();
          _controller.refreshProgression();
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        AlertBanner.show(
          context,
          'Failed to load chapter: $e',
          type: AlertBannerType.error,
        );
      }
    }
  }

  Future<void> _navigateToDetail(BuildContext context, MangaSummary item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading ${item.title}...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final detailData = await _apiService.getMangaDetail(item.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      final mangaDetail = MangaDetail.fromMap(detailData);
      Navigator.pushNamed(
        context,
        AppRoutes.detail,
        arguments: {
          'manga': mangaDetail,
          'heroTag': 'manga-cover-rec-${item.id}',
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      AlertBanner.show(
        context,
        'Failed to load details: $e',
        type: AlertBannerType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroImageUrl = _apiService.getLocalImageUrl(
      widget.manga.localImageUrl,
      widget.manga.imageUrl,
    );

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _controller.refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Responsive Parallax Backdrop Banner Header with Split Hero
                    MangaDetailAppBar(
                      manga: widget.manga,
                      heroImageUrl: heroImageUrl,
                      chapterCount: _controller.chapters.length,
                      heroTag: widget.heroTag,
                    ),

                    // Overview Section: Genres (stretches downward) & Synopsis
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MangaDetailGenres(
                                    manga: widget.manga,
                                    initialVisibleCount: 9,
                                  ),
                                  const SizedBox(height: 16),
                                  MangaDetailSynopsis(
                                    description: widget.manga.description,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Pinned Tab Bar (Chapters & Recommendations)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: MangaDetailTabBarDelegate(
                        backgroundColor: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        tabBar: TabBar(
                          controller: _tabController,
                          indicatorColor: colorScheme.primary,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          labelColor: colorScheme.primary,
                          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                          ),
                          tabs: [
                            Tab(text: 'Chapters (${_controller.chapters.length})'),
                            Tab(text: 'Recommendations (${_controller.recommendations.length})'),
                          ],
                        ),
                      ),
                    ),

                    // Chapter Search & Sort Header
                    if (_tabController.index == 0)
                      SliverToBoxAdapter(
                        child: Container(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: MangaDetailChapterHeader(
                                  isAscending: _controller.isAscending,
                                  currentFilter: _controller.chapterFilter,
                                  onFilterChanged: _controller.setChapterFilter,
                                  onToggleSort: _controller.toggleSort,
                                  onSearchChanged: _controller.setSearchQuery,
                                  onScrapChapters: () async {
                                    try {
                                      _controller.startScrapingFeedback();
                                      AlertBanner.show(
                                        context,
                                        'Scraping chapters queued...',
                                        type: AlertBannerType.info,
                                      );
                                      await _apiService
                                          .scrapChapterPagesNew(widget.manga.id);
                                    } catch (e) {
                                      _controller.clearScrapingProgress();
                                      if (context.mounted) {
                                        AlertBanner.show(
                                          context,
                                          'Failed to scrap chapters: $e',
                                          type: AlertBannerType.error,
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Real-time SignalR Chapter Scraping Progress Card
                    if (_tabController.index == 0 &&
                        _controller.scrapingProgress != null)
                      SliverToBoxAdapter(
                        child: Container(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: MangaDetailScrapingProgressCard(
                                  progress: _controller.scrapingProgress!,
                                  onDismiss: _controller.clearScrapingProgress,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Tab Content (Chapters or Recommendations)
                    if (_tabController.index == 0)
                      _buildChapterList(isDark)
                    else ...[
                      SliverToBoxAdapter(
                        child: Container(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: MangaDetailRecommendationsHeader(
                                  manga: widget.manga,
                                  totalCount: _controller.recommendations.length,
                                  isLoading: _controller.isLoadingRecommendations,
                                  selectedStatus: _controller.recommendationStatus,
                                  selectedType: _controller.recommendationType,
                                  selectedGenres: _controller.recommendationGenres,
                                  onOpenFilter: () {
                                    SimilarMangaFilterSheet.show(
                                      context,
                                      currentGenres:
                                          _controller.recommendationGenres,
                                      currentType:
                                          _controller.recommendationType,
                                      currentStatus:
                                          _controller.recommendationStatus,
                                      mangaGenres: widget.manga.genres ?? [],
                                      onApply: (genres, type, status) {
                                        _controller.setRecommendationFilters(
                                          genres: genres,
                                          type: type,
                                          status: status,
                                        );
                                      },
                                    );
                                  },
                                  onClearFilters:
                                      _controller.clearRecommendationFilters,
                                  onRemoveGenre:
                                      _controller.removeRecommendationGenre,
                                  onRemoveType: () =>
                                      _controller.setRecommendationType(null),
                                  onRemoveStatus: () =>
                                      _controller.setRecommendationStatus(null),
                                  onQuickToggleGenre:
                                      _controller.toggleRecommendationGenre,
                                  onRefresh: () => _controller
                                      .loadRecommendations(forceReload: true),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      MangaDetailRecommendationsGrid(
                        recommendations: _controller.recommendations,
                        isLoading: _controller.isLoadingRecommendations,
                        errorMessage: _controller.recommendationErrorMessage,
                        hasFilters: _controller.hasRecommendationFilters,
                        onClearFilters: _controller.clearRecommendationFilters,
                        onRetry: () => _controller.loadRecommendations(
                            forceReload: true),
                        onSelectRecommendation: (item) =>
                            _navigateToDetail(context, item),
                      ),
                    ],

                    // Bottom padding so content is not covered by the floating dock
                    SliverToBoxAdapter(
                      child: Container(
                        height: 100,
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Responsive Floating Bottom Pill Dock
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: MangaDetailFloatingDock(
                  chapters: _controller.chapters,
                  isLoadingChapters: _controller.isLoadingChapters,
                  isInLibrary: _controller.isInLibrary,
                  isFavorite: _controller.isFavorite,
                  libraryStatus: _controller.libraryStatus,
                  progression: _controller.progression,
                  onReadChapter: (ch) => _navigateToReader(context, ch),
                  onAddToLibrary: (status) async {
                    await _controller.addToLibrary(status);
                    if (context.mounted) {
                      AlertBanner.show(
                        context,
                        'Added to library as ${StatusSelectionSheet.getLabel(status)}',
                        type: AlertBannerType.success,
                      );
                    }
                  },
                  onChangeLibraryStatus: (newStatus) async {
                    await _controller.updateLibraryStatus(newStatus);
                    if (context.mounted) {
                      AlertBanner.show(
                        context,
                        'Status updated to ${StatusSelectionSheet.getLabel(newStatus)}',
                        type: AlertBannerType.success,
                      );
                    }
                  },
                  onRemoveFromLibrary: () async {
                    await _controller.removeFromLibrary();
                    if (context.mounted) {
                      AlertBanner.show(
                        context,
                        'Removed from library',
                        type: AlertBannerType.success,
                      );
                    }
                  },
                  onToggleFavorite: () async {
                    final isFav = await _controller.toggleFavorite();
                    if (context.mounted) {
                      AlertBanner.show(
                        context,
                        isFav
                            ? 'Added to favorites'
                            : 'Removed from favorites',
                        type: AlertBannerType.success,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChapterList(bool isDark) {
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    if (_controller.isLoadingChapters) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              color: bgColor,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.slate700.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const ShimmerBox(
                            width: 48,
                            height: 48,
                            borderRadius: 12,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ShimmerBox(
                                  width: 140,
                                  height: 14,
                                  borderRadius: 4,
                                ),
                                const SizedBox(height: 8),
                                ShimmerBox(
                                  width: 80,
                                  height: 10,
                                  borderRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: 6,
        ),
      );
    }

    final chapters = _controller.filteredChapters;

    if (chapters.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              _controller.searchQuery.isEmpty
                  ? 'No chapters available'
                  : 'No chapters matching "${_controller.searchQuery}"',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chapter = chapters[index];
          return Container(
            color: bgColor,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: MangaDetailChapterTile(
                    chapter: chapter,
                    isDark: isDark,
                    progression: _controller.progression,
                    onTap: () => _navigateToReader(context, chapter),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: chapters.length,
      ),
    );
  }
}

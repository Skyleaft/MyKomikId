import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../core/models/manga_summary.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../routes/app_pages.dart';
import '../../reader/models/reader_content.dart';
import '../controllers/manga_detail_controller.dart';
import '../models/manga_detail.dart';
import 'widgets/manga_detail_app_bar.dart';
import 'widgets/manga_detail_info_section.dart';
import 'widgets/manga_detail_stats_row.dart';
import 'widgets/manga_detail_genres.dart';
import 'widgets/manga_detail_synopsis.dart';
import 'widgets/manga_detail_action_bar.dart';
import 'widgets/manga_detail_tab_bar.dart';
import 'widgets/manga_detail_chapter_header.dart';
import 'widgets/manga_detail_chapter_tile.dart';
import 'widgets/manga_detail_recommendations_grid.dart';
import 'widgets/manga_detail_recommendations_header.dart';
import 'widgets/similar_manga_filter_sheet.dart';

class MangaDetailScreen extends StatefulWidget {
  final MangaDetail manga;

  const MangaDetailScreen({super.key, required this.manga});

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen>
    with SingleTickerProviderStateMixin {
  late final MangaDetailController _controller;
  late final TabController _tabController;
  final MangaApiService _apiService = getIt<MangaApiService>();

  @override
  void initState() {
    super.initState();
    _controller = MangaDetailController(manga: widget.manga);
    _controller.init();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _controller.recommendations.isEmpty) {
        _controller.loadRecommendations();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToReader(BuildContext context, Chapter chapter) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
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
        if (progression != null &&
            progression.currentChapter == chapter.chapterNumber) {
          startingPage = progression.currentPage;
        }

        final content = ReaderContent(
          mangaId: widget.manga.id,
          mangaTitle: widget.manga.title,
          currentChapterNumber: chapter.chapterNumber,
          chapterId: chapter.id,
          allChapters: _controller.chapters,
          chapterTitle: chapter.title,
          pageUrls: pages
              .map((p) => _apiService.getLocalImageUrl(p, null))
              .toList(),
          currentPage: startingPage,
          progression: progression,
        );

        await Navigator.pushNamed(
          context,
          AppRoutes.reader,
          arguments: content,
        );
        _controller.refreshProgression();
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final detailData = await _apiService.getMangaDetail(item.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      final mangaDetail = MangaDetail.fromMap(detailData);
      Navigator.pushNamed(context, AppRoutes.detail, arguments: mangaDetail);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroImageUrl = _apiService.getLocalImageUrl(
      widget.manga.localImageUrl,
      widget.manga.imageUrl,
    );

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _controller.refresh,
            child: CustomScrollView(
              slivers: [
                // Parallax Header
                MangaDetailAppBar(
                  manga: widget.manga,
                  heroImageUrl: heroImageUrl,
                ),

                // Main Info Container
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MangaDetailInfoSection(
                          manga: widget.manga,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        MangaDetailStatsRow(
                          rating: widget.manga.rating,
                          chapterCount: _controller.chapters.length,
                          totalView: widget.manga.totalView,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: AppColors.primary.withValues(alpha: 0.2),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        MangaDetailGenres(manga: widget.manga),
                        const SizedBox(height: 24),
                        MangaDetailSynopsis(
                          description: widget.manga.description,
                        ),
                        const SizedBox(height: 24),
                        MangaDetailActionBar(
                          chapters: _controller.chapters,
                          isLoadingChapters: _controller.isLoadingChapters,
                          isInLibrary: _controller.isInLibrary,
                          isFavorite: _controller.isFavorite,
                          progression: _controller.progression,
                          onReadChapter: (ch) => _navigateToReader(context, ch),
                          onAddToLibrary: (status) async {
                            await _controller.addToLibrary(status);
                            if (context.mounted) {
                              AlertBanner.show(
                                context,
                                'Added to library as $status',
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
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Pinned Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: MangaDetailTabBarDelegate(
                    backgroundColor: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    tabBar: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(text: 'Chapters'),
                        Tab(text: 'Recommendations'),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
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
                            AlertBanner.show(
                              context,
                              'Scraping chapters...',
                              type: AlertBannerType.info,
                            );
                            await _apiService.scrapChapterPagesNew(widget.manga.id);
                            if (context.mounted) {
                              AlertBanner.show(
                                context,
                                'Chapter scraping queued successfully!',
                                type: AlertBannerType.success,
                              );
                              _controller.refresh();
                            }
                          } catch (e) {
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

                // Tab Content (Chapters or Recommendations)
                if (_tabController.index == 0)
                  _buildChapterList(isDark)
                else ...[
                  SliverToBoxAdapter(
                    child: Container(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
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
                            currentGenres: _controller.recommendationGenres,
                            currentType: _controller.recommendationType,
                            currentStatus: _controller.recommendationStatus,
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
                        onClearFilters: _controller.clearRecommendationFilters,
                        onRemoveGenre: _controller.removeRecommendationGenre,
                        onRemoveType: () => _controller.setRecommendationType(null),
                        onRemoveStatus: () => _controller.setRecommendationStatus(null),
                        onQuickToggleGenre: _controller.toggleRecommendationGenre,
                        onRefresh: () => _controller.loadRecommendations(forceReload: true),
                      ),
                    ),
                  ),
                  MangaDetailRecommendationsGrid(
                    recommendations: _controller.recommendations,
                    isLoading: _controller.isLoadingRecommendations,
                    errorMessage: _controller.recommendationErrorMessage,
                    hasFilters: _controller.hasRecommendationFilters,
                    onClearFilters: _controller.clearRecommendationFilters,
                    onRetry: () => _controller.loadRecommendations(forceReload: true),
                    onSelectRecommendation: (item) =>
                        _navigateToDetail(context, item),
                  ),
                ],

                SliverToBoxAdapter(
                  child: Container(
                    height: 48,
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                  ),
                ),
              ],
            ),
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
      return SliverToBoxAdapter(
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.all(24.0),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final chapters = _controller.filteredChapters;

    if (chapters.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.all(24.0),
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: MangaDetailChapterTile(
              chapter: chapter,
              isDark: isDark,
              progression: _controller.progression,
              onTap: () => _navigateToReader(context, chapter),
            ),
          );
        },
        childCount: chapters.length,
      ),
    );
  }
}

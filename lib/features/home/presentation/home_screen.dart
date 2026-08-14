import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../routes/app_pages.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../manga_detail/models/manga_detail.dart';
import '../controllers/home_controller.dart';
import '../models/trending_tab.dart';
import 'widgets/home_header.dart';
import 'widgets/home_continue_reading_section.dart';
import 'widgets/home_trending_section.dart';
import 'widgets/home_latest_updates_section.dart';
import 'widgets/home_top_manga_section.dart';
import 'widgets/home_recommended_section.dart';

class HomeScreen extends StatefulWidget {
  final Function({String? sortBy, String? search})? onNavigateToDiscover;

  const HomeScreen({super.key, this.onNavigateToDiscover});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final HomeController _controller;
  late final TabController _trendingTabController;
  final MangaApiService _apiService = getIt<MangaApiService>();

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _trendingTabController = TabController(
      length: kTrendingTabs.length,
      vsync: this,
    );
    _trendingTabController.addListener(_onTrendingTabChanged);
    _controller.fetchAllData();
  }

  @override
  void dispose() {
    _trendingTabController.removeListener(_onTrendingTabChanged);
    _trendingTabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTrendingTabChanged() {
    final idx = _trendingTabController.index;
    if (!_trendingTabController.indexIsChanging) return;
    if (!_controller.trendingByTab.containsKey(idx)) {
      _controller.fetchTrendingForTab(idx);
    }
  }

  Future<void> _navigateToDetail(String mangaId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final detailData = await _apiService.getMangaDetail(mangaId);
      if (!mounted) return;
      Navigator.pop(context);

      final mangaDetail = MangaDetail.fromMap(detailData);
      Navigator.pushNamed(context, AppRoutes.detail, arguments: mangaDetail);
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

  void _navigateToDiscover({String? sortBy}) {
    if (widget.onNavigateToDiscover != null) {
      widget.onNavigateToDiscover!(sortBy: sortBy);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiscoverScreen(sortBy: sortBy),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _controller.refresh,
          color: AppColors.primary,
          child: SafeArea(
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
                  expandedHeight: 100,
                  toolbarHeight: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: HomeHeader(isDark: isDark),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 150),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),
                      HomeContinueReadingSection(
                        recentProgressions: _controller.recentProgressions,
                        historyDetailsMap: _controller.historyDetailsMap,
                        isLoading: _controller.isLoadingHistory,
                        isDark: isDark,
                        apiService: _apiService,
                      ),
                      const SizedBox(height: 32),
                      HomeTrendingSection(
                        tabController: _trendingTabController,
                        trendingByTab: _controller.trendingByTab,
                        trendingLoadingByTab: _controller.trendingLoadingByTab,
                        isDark: isDark,
                        apiService: _apiService,
                        onSelectManga: _navigateToDetail,
                        onNavigateToDiscover: () =>
                            _navigateToDiscover(sortBy: 'totalView'),
                      ),
                      const SizedBox(height: 32),
                      HomeLatestUpdatesSection(
                        latestUpdates: _controller.latestUpdates,
                        isLoading: _controller.isLoadingLatest,
                        isDark: isDark,
                        apiService: _apiService,
                        onSelectManga: _navigateToDetail,
                        onNavigateToDiscover: () =>
                            _navigateToDiscover(sortBy: 'updatedAt'),
                      ),
                      const SizedBox(height: 32),
                      HomeTopMangaSection(
                        topManga: _controller.topManga,
                        isLoading: _controller.isLoadingTop,
                        apiService: _apiService,
                        onSelectManga: _navigateToDetail,
                        onNavigateToDiscover: () =>
                            _navigateToDiscover(sortBy: 'rating'),
                      ),
                      const SizedBox(height: 32),
                      HomeRecommendedSection(
                        recommendedManga: _controller.recommendedManga,
                        isLoading: _controller.isLoadingRecommended,
                        apiService: _apiService,
                        onSelectManga: _navigateToDetail,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

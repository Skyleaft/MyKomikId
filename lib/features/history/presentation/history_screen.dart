import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../routes/app_pages.dart';
import '../../manga_detail/models/manga_detail.dart';
import '../controllers/history_controller.dart';
import 'widgets/history_header.dart';
import 'widgets/history_item_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryController _controller;
  final MangaApiService _apiService = getIt<MangaApiService>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = HistoryController();
    _controller.loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDetail(MangaDetail mangaDetail) {
    Navigator.pushNamed(
      context,
      AppRoutes.detail,
      arguments: mangaDetail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
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
                  expandedHeight: 200,
                  toolbarHeight: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: HistoryHeader(
                          isDark: isDark,
                          selectedFilter: _controller.selectedFilter,
                          searchController: _searchController,
                          onSearchChanged: _controller.setSearchQuery,
                          onFilterChanged: _controller.setSelectedFilter,
                          onRefresh: _controller.loadHistory,
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
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final filtered = _controller.filteredProgressions;
    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              _controller.searchQuery.isNotEmpty ||
                      _controller.selectedFilter != 'All'
                  ? 'No matching history found'
                  : 'No reading history yet\nStart reading manga to see your progress here!',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final progression = filtered[index];
        final mangaDetail = _controller.mangaDetailsMap[progression.mangaId];

        return HistoryItemCard(
          progression: progression,
          mangaDetail: mangaDetail,
          isDark: isDark,
          apiService: _apiService,
          onTap: () {
            if (mangaDetail != null) {
              _navigateToDetail(mangaDetail);
            }
          },
        );
      }, childCount: filtered.length),
    );
  }
}

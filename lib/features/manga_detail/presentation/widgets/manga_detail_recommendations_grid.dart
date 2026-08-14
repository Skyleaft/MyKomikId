import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/manga_summary.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/discover_card.dart';

class MangaDetailRecommendationsGrid extends StatelessWidget {
  final List<MangaSummary> recommendations;
  final bool isLoading;
  final ValueChanged<MangaSummary> onSelectRecommendation;

  const MangaDetailRecommendationsGrid({
    super.key,
    required this.recommendations,
    required this.isLoading,
    required this.onSelectRecommendation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    if (isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.all(48.0),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (recommendations.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.all(48.0),
          child: const Center(
            child: Text(
              'No recommendations available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;
    final int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

    return SliverPadding(
      padding: const EdgeInsets.all(24.0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 24,
          crossAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = recommendations[index];
          return DiscoverCard(
            title: item.title,
            type: item.type,
            latestChapter: item.latestChapter,
            views: formatViewCount(item.totalView),
            genres: item.genres ?? [],
            status: item.status,
            rating: item.rating,
            localImageUrl: item.localImageUrl,
            imageUrl: item.imageUrl,
            onTap: () => onSelectRecommendation(item),
          );
        }, childCount: recommendations.length),
      ),
    );
  }
}

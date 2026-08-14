import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/manga_summary.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/discover_card.dart';

class MangaDetailRecommendationsGrid extends StatelessWidget {
  final List<MangaSummary> recommendations;
  final bool isLoading;
  final String? errorMessage;
  final bool hasFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onRetry;
  final ValueChanged<MangaSummary> onSelectRecommendation;

  const MangaDetailRecommendationsGrid({
    super.key,
    required this.recommendations,
    required this.isLoading,
    this.errorMessage,
    this.hasFilters = false,
    this.onClearFilters,
    this.onRetry,
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
          padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  hasFilters
                      ? 'Finding matching similar manga...'
                      : 'Loading recommendations...',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SliverToBoxAdapter(
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load similar manga',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (recommendations.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 56.0, horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate800 : AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasFilters
                        ? Icons.filter_alt_off_outlined
                        : Icons.auto_stories_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  hasFilters
                      ? 'No similar manga match the filters'
                      : 'No similar manga found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasFilters
                      ? 'Try adjusting or clearing your active filters to see more recommendations.'
                      : 'Check back later for semantic recommendations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                if (hasFilters && onClearFilters != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onClearFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear Filters'),
                  ),
                ],
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
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

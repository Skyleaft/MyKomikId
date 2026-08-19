import 'package:flutter/material.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/manga_api_service.dart';
import '../../../../routes/app_pages.dart';
import '../../../history/models/progression.dart';
import '../../../manga_detail/models/manga_detail.dart';

class HomeContinueReadingSection extends StatelessWidget {
  final List<MangaProgression> recentProgressions;
  final Map<String, MangaDetail> historyDetailsMap;
  final bool isLoading;
  final bool isDark;
  final MangaApiService apiService;

  const HomeContinueReadingSection({
    super.key,
    required this.recentProgressions,
    required this.historyDetailsMap,
    required this.isLoading,
    required this.isDark,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && recentProgressions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Continue Reading',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recentProgressions.length,
                  itemBuilder: (context, index) {
                    final progression = recentProgressions[index];
                    final detail = historyDetailsMap[progression.mangaId];
                    return _buildHistoryCard(context, progression, detail);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    MangaProgression progression,
    MangaDetail? detail,
  ) {
    final imageUrl = detail != null
        ? apiService.getLocalImageUrl(detail.localImageUrl, detail.imageUrl)
        : '';
    final title = detail?.title ?? 'Unknown Manga';
    final progress = progression.progressPercentage;
    final now = DateTime.now();
    final diff = now.difference(progression.lastRead.toLocal());
    String timeAgo;
    if (diff.inDays >= 1) {
      timeAgo = '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      timeAgo = '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      timeAgo = '${diff.inMinutes}m ago';
    } else {
      timeAgo = 'Just now';
    }

    return GestureDetector(
      onTap: () {
        if (detail != null) {
          Navigator.pushNamed(context, AppRoutes.detail, arguments: detail);
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark
              ? AppColors.slate800.withValues(alpha: 0.9)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                      ),
                      errorBuilder: (_, _, _) => Container(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeAgo,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ch. ${progression.currentChapter.toInt()}  •  Pg. ${progression.currentPage}/${progression.totalPages}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

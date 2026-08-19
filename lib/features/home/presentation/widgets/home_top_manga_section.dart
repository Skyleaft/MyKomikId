import 'package:flutter/material.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/manga_summary.dart';
import '../../../../core/network/manga_api_service.dart';
import '../../../../core/widgets/shimmer_box.dart';

class HomeTopMangaSection extends StatelessWidget {
  final List<MangaSummary> topManga;
  final bool isLoading;
  final bool isDark;
  final MangaApiService apiService;
  final void Function(String mangaId, {MangaSummary? summary}) onSelectManga;
  final VoidCallback onNavigateToDiscover;

  const HomeTopMangaSection({
    super.key,
    required this.topManga,
    required this.isLoading,
    this.isDark = true,
    required this.apiService,
    required this.onSelectManga,
    required this.onNavigateToDiscover,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Top Manga',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onNavigateToDiscover,
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
          const SizedBox(height: 14),
          if (isLoading)
            _buildSkeletonLoader()
          else if (topManga.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                'No top manga found',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topManga.length,
                itemBuilder: (context, index) {
                  return _buildSmallCard(context, topManga[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    borderRadius: 12,
                  ),
                ),
                SizedBox(height: 6),
                ShimmerBox(width: 90, height: 12, borderRadius: 4),
                SizedBox(height: 4),
                ShimmerBox(width: 50, height: 10, borderRadius: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmallCard(BuildContext context, MangaSummary manga) {
    final String imageUrl = apiService.getLocalImageUrl(
      manga.localImageUrl,
      manga.imageUrl,
    );

    return GestureDetector(
      onTap: () => onSelectManga(manga.id, summary: manga),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            fadeInDuration: const Duration(milliseconds: 200),
                            placeholder: (_, _) => Container(
                              color: isDark ? Colors.grey[850] : Colors.grey[200],
                            ),
                            errorBuilder: (_, _, _) => Container(
                              color: isDark ? Colors.grey[850] : Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: isDark ? Colors.grey[850] : Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  if (manga.rating != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC107),
                              size: 11,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              manga.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              manga.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


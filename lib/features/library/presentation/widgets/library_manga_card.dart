import 'package:flutter/material.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/manga_api_service.dart';
import '../../../manga_detail/models/manga_detail.dart';
import '../../models/library_manga.dart';

class LibraryMangaCard extends StatelessWidget {
  final LibraryManga manga;
  final MangaDetail? detail;
  final bool isDark;
  final MangaApiService apiService;
  final VoidCallback onTap;

  const LibraryMangaCard({
    super.key,
    required this.manga,
    required this.detail,
    required this.isDark,
    required this.apiService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String displayUrl = apiService.getLocalImageUrl(
      detail?.localImageUrl ?? manga.imageUrl,
      manga.imageUrl,
    );

    String excerpt = '';
    if (detail?.description != null && detail!.description!.isNotEmpty) {
      excerpt = detail!.description!;
    } else {
      excerpt = 'No description available';
    }

    final int totalChapters = detail?.chapters.length ?? 0;
    final String displayAuthor = (detail != null &&
            detail!.author.isNotEmpty &&
            detail!.author != 'Unknown Author')
        ? detail!.author
        : manga.author;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900]!.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover Image Left
                Stack(
                  children: [
                    Container(
                      width: 105,
                      height: 145,
                      color: AppColors.primary.withValues(alpha: 0.05),
                      child: displayUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: displayUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, url, error) =>
                                  _buildImagePlaceholder(),
                              placeholder: (context, url) =>
                                  _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                    // Progress Bar overlay at bottom of image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        color: Colors.black.withValues(alpha: 0.2),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: manga.progressPercentage.clamp(0.0, 1.0),
                          child: Container(color: AppColors.primary),
                        ),
                      ),
                    ),
                    if (manga.isCompleted)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DONE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Information details Right
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    manga.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(manga.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By $displayAuthor • ${manga.type}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Description Excerpt
                        Expanded(
                          child: Text(
                            excerpt,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Genres Row & Progress Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: detail?.genres != null &&
                                      detail!.genres!.isNotEmpty
                                  ? Text(
                                      detail!.genres!.join(', '),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.grey[500]
                                            : Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : Text(
                                      'No genres loaded',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.grey[600]
                                            : Colors.grey[500],
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Ch. ${manga.currentChapter.toInt()}${totalChapters > 0 ? '/$totalChapters' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.menu_book,
        color: AppColors.primary.withValues(alpha: 0.4),
        size: 28,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = switch (status.toLowerCase()) {
      'reading' => Colors.green,
      'completed' => Colors.blue,
      'onhold' => Colors.orange,
      'dropped' => Colors.red,
      'plantoread' => Colors.purple,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

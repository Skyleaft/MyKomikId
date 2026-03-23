import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../data/services/manga_api_service.dart';
import '../di/injection.dart';

class MangaCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? localImageUrl;
  final int currentChapter;
  final int totalChapters;
  final double progress;
  final bool isCompleted;
  final String? type;
  final String? status;
  final List<String>? genres;
  final VoidCallback? onTap;

  const MangaCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.localImageUrl,
    required this.currentChapter,
    required this.totalChapters,
    required this.progress,
    this.isCompleted = false,
    this.type,
    this.status,
    this.genres,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String displayUrl = getIt<MangaApiService>().getLocalImageUrl(
      localImageUrl,
      imageUrl,
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (displayUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: displayUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            _buildPlaceholder(),
                        placeholder: (context, url) => _buildPlaceholder(),
                      )
                    else
                      _buildPlaceholder(),

                    // Status Badge (Top Left)
                    if (status != null && status!.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: switch (status!.toLowerCase()) {
                              'reading' => Colors.green.withOpacity(0.8),
                              'completed' => Colors.blue.withOpacity(0.8),
                              'onhold' => Colors.orange.withOpacity(0.8),
                              'dropped' => Colors.red.withOpacity(0.8),
                              'plantoread' => Colors.purple.withOpacity(0.8),
                              _ => Colors.grey.withOpacity(0.8),
                            },
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status!.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // Type Badge (Bottom Left)
                    Positioned(
                      bottom: 12,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type?.toUpperCase() ?? 'MANGA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Progress Bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        color: Colors.black.withOpacity(0.4),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(color: AppColors.primary),
                        ),
                      ),
                    ),

                    // Completed Badge (Keep as indicator if progression is done)
                    if (isCompleted)
                      Positioned(
                        top: 8,
                        right: 8,
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
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Ch. $currentChapter${totalChapters > 0 ? '/$totalChapters' : ''}',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.primary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (genres != null && genres!.isNotEmpty)
            Text(
              genres!.join(', '),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.menu_book,
          color: AppColors.primary.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }
}

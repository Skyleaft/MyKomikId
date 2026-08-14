import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class MangaDetailStatsRow extends StatelessWidget {
  final double? rating;
  final int chapterCount;
  final int totalView;

  const MangaDetailStatsRow({
    super.key,
    required this.rating,
    required this.chapterCount,
    required this.totalView,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rating
        Column(
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 24),
                const SizedBox(width: 4),
                Text(
                  rating?.toString() ?? '0.0',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Text(
              'Rating',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        // Divider
        Container(
          height: 32,
          width: 1,
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 24),
        // Chapters
        Column(
          children: [
            Text(
              chapterCount.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'Chapters',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        // Divider
        Container(
          height: 32,
          width: 1,
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 24),
        // Reads
        Column(
          children: [
            Text(
              formatViewCount(totalView),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'Reads',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

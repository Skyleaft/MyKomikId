import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../history/models/progression.dart';
import '../../models/manga_detail.dart';

class MangaDetailChapterTile extends StatelessWidget {
  final Chapter chapter;
  final bool isDark;
  final MangaProgression? progression;
  final VoidCallback? onTap;

  const MangaDetailChapterTile({
    super.key,
    required this.chapter,
    required this.isDark,
    required this.progression,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = chapter.isChapterAvailable;
    final Color chapterBgColor = isAvailable
        ? isDark
            ? AppColors.slate700.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.1)
        : Colors.grey.shade600;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: isAvailable ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: chapterBgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Chapter number box
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate700.withValues(alpha: 0.4)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        chapter.chapterNumber % 1 == 0
                            ? chapter.chapterNumber.toInt().toString()
                            : chapter.chapterNumber.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Chapter info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Language Badge
                            if (chapter.language.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  chapter.language.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),

                            // Provider Badge
                            if (chapter.chapterProvider != null &&
                                chapter.chapterProvider!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (chapter.chapterProviderIcon != null) ...[
                                      Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(right: 4),
                                        child: chapter.chapterProviderIcon!
                                                .toLowerCase()
                                                .endsWith('.ico')
                                            ? Icon(
                                                Icons.link,
                                                size: 10,
                                                color: textColor.withValues(alpha: 0.6),
                                              )
                                            : CachedNetworkImage(
                                                imageUrl: chapter.chapterProviderIcon!,
                                                width: 12,
                                                height: 12,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Icon(
                                                  Icons.link,
                                                  size: 10,
                                                  color: textColor.withValues(alpha: 0.6),
                                                ),
                                              ),
                                      ),
                                    ],
                                    Text(
                                      chapter.chapterProvider!,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: textColor.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // View Count
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: textColor.withValues(alpha: 0.5),
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  formatViewCount(chapter.totalView),
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.5),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Date row
                        Row(
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(chapter.date),
                              style: TextStyle(
                                fontSize: 11,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '·',
                              style: TextStyle(
                                fontSize: 11,
                                color: textColor.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo(chapter.date),
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Completion Badge & Chevron
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompletionBadge(),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: textColor.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildProgressionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionBadge() {
    final double chapterNumber = chapter.chapterNumber;
    final bool isRead = progression != null &&
        progression!.chapterLogs.any(
          (log) => log.chapterNumber == chapterNumber && log.isCompleted,
        );

    if (!isRead) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'READ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionBar() {
    if (progression == null) return const SizedBox.shrink();

    UserChapterLog? log;
    for (final l in progression!.chapterLogs) {
      if (l.chapterNumber == chapter.chapterNumber) {
        log = l;
        break;
      }
    }

    if (log == null || log.isCompleted) {
      return const SizedBox.shrink();
    }

    final double progressPercentage = log.totalPages <= 0
        ? 0.0
        : (log.lastReadPage / log.totalPages).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progressPercentage,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress: ${(progressPercentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

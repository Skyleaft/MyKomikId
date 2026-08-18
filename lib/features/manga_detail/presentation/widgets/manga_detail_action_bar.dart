import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../history/models/progression.dart';
import '../../models/manga_detail.dart';
import 'status_selection_sheet.dart';

class MangaDetailActionBar extends StatelessWidget {
  final List<Chapter> chapters;
  final bool isLoadingChapters;
  final bool isInLibrary;
  final bool isFavorite;
  final MangaProgression? progression;
  final ValueChanged<Chapter> onReadChapter;
  final ValueChanged<String> onAddToLibrary;
  final VoidCallback onRemoveFromLibrary;
  final VoidCallback onToggleFavorite;

  const MangaDetailActionBar({
    super.key,
    required this.chapters,
    required this.isLoadingChapters,
    required this.isInLibrary,
    required this.isFavorite,
    required this.progression,
    required this.onReadChapter,
    required this.onAddToLibrary,
    required this.onRemoveFromLibrary,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (progression != null) {
      return _buildResumeActionButtons(context, progression!);
    }
    return _buildDefaultActionButtons(context);
  }

  Widget _buildDefaultActionButtons(BuildContext context) {
    final availableChapters = chapters.where((c) => c.isChapterAvailable).toList();
    final firstChapter = availableChapters.isNotEmpty ? availableChapters.last : null;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: isLoadingChapters || firstChapter == null
                ? null
                : () => onReadChapter(firstChapter),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLoadingChapters || firstChapter == null
                  ? Colors.grey[700]
                  : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36),
              ),
            ),
            icon: const Icon(Icons.menu_book),
            label: const Text(
              'Start Chapter 1',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildLibraryButton(context),
        if (isInLibrary) ...[
          const SizedBox(width: 10),
          _buildFavoriteButton(),
        ],
      ],
    );
  }

  Widget _buildResumeActionButtons(
    BuildContext context,
    MangaProgression currentProgression,
  ) {
    // Find exact or next uncompleted chapter
    Chapter? targetChapter;
    for (final c in chapters) {
      if (c.chapterNumber == currentProgression.currentChapter) {
        targetChapter = c;
        break;
      }
    }

    targetChapter ??= chapters.isNotEmpty ? chapters.last : null;

    final String numStr = targetChapter != null
        ? (targetChapter.chapterNumber % 1 == 0
            ? targetChapter.chapterNumber.toInt().toString()
            : targetChapter.chapterNumber.toString())
        : (currentProgression.currentChapter % 1 == 0
            ? currentProgression.currentChapter.toInt().toString()
            : currentProgression.currentChapter.toString());

    final buttonText = 'Resume Ch. $numStr (Pg. ${currentProgression.currentPage})';

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: targetChapter != null
                ? () => onReadChapter(targetChapter!)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildLibraryButton(context),
        if (isInLibrary) ...[
          const SizedBox(width: 10),
          _buildFavoriteButton(),
        ],
      ],
    );
  }

  Widget _buildLibraryButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isInLibrary
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isInLibrary ? Icons.bookmark : Icons.bookmark_border,
          color: isInLibrary ? AppColors.primary : Colors.white70,
        ),
        onPressed: () async {
          if (isInLibrary) {
            onRemoveFromLibrary();
          } else {
            final selected = await StatusSelectionSheet.show(context);
            if (selected != null) {
              onAddToLibrary(selected);
            }
          }
        },
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Container(
      decoration: BoxDecoration(
        color: isFavorite
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.white70,
        ),
        onPressed: onToggleFavorite,
      ),
    );
  }
}

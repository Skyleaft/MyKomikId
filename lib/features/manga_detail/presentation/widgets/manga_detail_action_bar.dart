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

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: isLoadingChapters || availableChapters.isEmpty
                ? null
                : () {
                    // Earliest chapter
                    onReadChapter(availableChapters.last);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLoadingChapters || availableChapters.isEmpty
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
              'Read First Chapter',
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
    Chapter? exactChapter;
    for (final c in chapters) {
      if (c.isChapterAvailable && c.chapterNumber == currentProgression.currentChapter) {
        exactChapter = c;
        break;
      }
    }

    Chapter? nextChapter;
    for (final c in chapters) {
      if (c.isChapterAvailable && c.chapterNumber > currentProgression.currentChapter) {
        nextChapter = c;
        break;
      }
    }

    Chapter? prevChapter;
    for (int i = chapters.length - 1; i >= 0; i--) {
      final c = chapters[i];
      if (c.isChapterAvailable && c.chapterNumber < currentProgression.currentChapter) {
        prevChapter = c;
        break;
      }
    }

    Chapter? firstAvail;
    for (final c in chapters) {
      if (c.isChapterAvailable) {
        firstAvail = c;
        break;
      }
    }

    final targetChapter = exactChapter ?? nextChapter ?? prevChapter ?? firstAvail;

    final buttonText = targetChapter != null
        ? 'Resume Chapter ${targetChapter.chapterNumber % 1 == 0 ? targetChapter.chapterNumber.toInt() : targetChapter.chapterNumber}'
        : 'Resume Chapter ${currentProgression.currentChapter % 1 == 0 ? currentProgression.currentChapter.toInt() : currentProgression.currentChapter}';

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: () {
              if (targetChapter != null) {
                onReadChapter(targetChapter);
              } else {
                final availableChapters =
                    chapters.where((c) => c.isChapterAvailable).toList();
                if (availableChapters.isNotEmpty) {
                  onReadChapter(availableChapters.last);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36),
              ),
            ),
            icon: const Icon(Icons.play_arrow),
            label: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: isInLibrary ? AppColors.primary : Colors.grey[800],
        borderRadius: BorderRadius.circular(28),
      ),
      child: IconButton(
        tooltip: isInLibrary ? 'In Library' : 'Add to Library',
        icon: Icon(
          isInLibrary ? Icons.library_add_check : Icons.library_add,
          color: Colors.white,
        ),
        onPressed: () async {
          if (isInLibrary) {
            onRemoveFromLibrary();
          } else {
            final status = await StatusSelectionSheet.show(context);
            if (status != null) {
              onAddToLibrary(status);
            }
          }
        },
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: isFavorite
            ? Colors.redAccent.withValues(alpha: 0.2)
            : Colors.grey[800],
        borderRadius: BorderRadius.circular(28),
        border: isFavorite
            ? Border.all(color: Colors.redAccent, width: 1.5)
            : null,
      ),
      child: IconButton(
        tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.redAccent : Colors.white,
        ),
        onPressed: onToggleFavorite,
      ),
    );
  }
}

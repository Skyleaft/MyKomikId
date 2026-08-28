import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final availableChapters =
        chapters.where((c) => c.isChapterAvailable).toList();
    final firstChapter =
        availableChapters.isNotEmpty ? availableChapters.last : null;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                if (!isLoadingChapters && firstChapter != null)
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: isLoadingChapters || firstChapter == null
                  ? null
                  : () => onReadChapter(firstChapter),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: Text(
                'Start Chapter 1',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildLibraryButton(context, isDark, colorScheme),
        if (isInLibrary) ...[
          const SizedBox(width: 10),
          _buildFavoriteButton(context, isDark),
        ],
      ],
    );
  }

  Widget _buildResumeActionButtons(
    BuildContext context,
    MangaProgression currentProgression,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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

    final buttonText =
        'Resume Ch. $numStr (Pg. ${currentProgression.currentPage})';

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: targetChapter != null
                  ? () => onReadChapter(targetChapter!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                buttonText,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildLibraryButton(context, isDark, colorScheme),
        if (isInLibrary) ...[
          const SizedBox(width: 10),
          _buildFavoriteButton(context, isDark),
        ],
      ],
    );
  }

  Widget _buildLibraryButton(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isInLibrary
            ? colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.14)
            : (isDark
                ? const Color(0xFF1E293B)
                : Colors.black.withValues(alpha: 0.05)),
        shape: BoxShape.circle,
        border: Border.all(
          color: isInLibrary
              ? colorScheme.primary.withValues(alpha: 0.4)
              : (isDark ? Colors.white12 : Colors.black12),
          width: 1,
        ),
      ),
      child: IconButton(
        tooltip: isInLibrary ? 'In Library' : 'Add to Library',
        icon: Icon(
          isInLibrary ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: isInLibrary
              ? colorScheme.primary
              : (isDark ? Colors.white70 : Colors.black54),
        ),
        onPressed: () async {
          HapticFeedback.selectionClick();
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

  Widget _buildFavoriteButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isFavorite
            ? Colors.red.withValues(alpha: isDark ? 0.22 : 0.14)
            : (isDark
                ? const Color(0xFF1E293B)
                : Colors.black.withValues(alpha: 0.05)),
        shape: BoxShape.circle,
        border: Border.all(
          color: isFavorite
              ? Colors.red.withValues(alpha: 0.4)
              : (isDark ? Colors.white12 : Colors.black12),
          width: 1,
        ),
      ),
      child: IconButton(
        tooltip: isFavorite ? 'Favorited' : 'Add to Favorites',
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFavorite
              ? Colors.redAccent
              : (isDark ? Colors.white70 : Colors.black54),
        ),
        onPressed: () {
          HapticFeedback.selectionClick();
          onToggleFavorite();
        },
      ),
    );
  }
}

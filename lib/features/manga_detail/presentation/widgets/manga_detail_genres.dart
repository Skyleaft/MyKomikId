import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/manga_detail.dart';

class MangaDetailGenres extends StatelessWidget {
  final MangaDetail manga;

  const MangaDetailGenres({super.key, required this.manga});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProviderChips(),
        _buildGenreTags(context),
      ],
    );
  }

  Widget _buildProviderChips() {
    final hasMal = manga.malId > 0;
    final hasAnilist = manga.anilistId != null && manga.anilistId! > 0;
    final hasMangaUpdates =
        manga.mangaUpdateId != null && manga.mangaUpdateId! > 0;

    if (!hasMal && !hasAnilist && !hasMangaUpdates) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (hasMal)
            _buildExternalLinkChip(
              label: 'MAL',
              icon: Icons.link_rounded,
              color: const Color(0xFF2E51A2),
              url: 'https://myanimelist.net/manga/${manga.malId}',
            ),
          if (hasAnilist)
            _buildExternalLinkChip(
              label: 'AniList',
              icon: Icons.tv_rounded,
              color: const Color(0xFF02A9FF),
              url: 'https://anilist.co/manga/${manga.anilistId}',
            ),
          if (hasMangaUpdates)
            _buildExternalLinkChip(
              label: 'MangaUpdates',
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF8C52FF),
              url:
                  'https://www.mangaupdates.com/series.html?id=${manga.mangaUpdateId}',
            ),
        ],
      ),
    );
  }

  Widget _buildExternalLinkChip({
    required String label,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () => launchUrlString(url),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.open_in_new_rounded, size: 11, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreTags(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (manga.genres != null)
          ...manga.genres!.map(
            (genre) => _buildTag(
              genre,
              colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              colorScheme.primary,
              isDark: isDark,
            ),
          ),
        if (manga.categories != null)
          ...manga.categories!.map(
            (category) => _buildTag(
              category,
              Colors.tealAccent.withValues(alpha: 0.15),
              Colors.tealAccent[400] ?? Colors.teal,
              isDark: isDark,
            ),
          ),
        _buildTag(
          manga.status?.toUpperCase() ?? 'ONGOING',
          isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          isDark ? Colors.white70 : Colors.black54,
          isDark: isDark,
        ),
        if (manga.releaseDate != null)
          _buildTag(
            'START: ${DateFormat('yyyy').format(manga.releaseDate!)}',
            Colors.blueAccent.withValues(alpha: 0.15),
            Colors.blueAccent,
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildTag(
    String label,
    Color bgColor,
    Color textColor, {
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

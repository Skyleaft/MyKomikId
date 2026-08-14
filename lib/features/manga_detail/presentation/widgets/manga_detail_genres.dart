import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../core/constants/app_colors.dart';
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
        _buildGenreTags(),
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
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.open_in_new, size: 11, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (manga.genres != null)
          ...manga.genres!.map(
            (genre) => _buildTag(
              genre,
              AppColors.primary.withValues(alpha: 0.2),
              AppColors.primary,
            ),
          ),
        if (manga.categories != null)
          ...manga.categories!.map(
            (category) => _buildTag(
              category,
              Colors.tealAccent.withValues(alpha: 0.15),
              Colors.tealAccent[400] ?? Colors.teal,
            ),
          ),
        _buildTag(
          manga.status?.toUpperCase() ?? 'ONGOING',
          Colors.grey.withValues(alpha: 0.2),
          Colors.grey,
        ),
        if (manga.releaseDate != null)
          _buildTag(
            'START: ${DateFormat('yyyy').format(manga.releaseDate!)}',
            Colors.blueAccent.withValues(alpha: 0.2),
            Colors.blueAccent,
          ),
      ],
    );
  }

  Widget _buildTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../models/manga_detail.dart';

class MangaDetailAppBar extends StatelessWidget {
  final MangaDetail manga;
  final String heroImageUrl;

  const MangaDetailAppBar({
    super.key,
    required this.manga,
    required this.heroImageUrl,
  });

  void _showExternalLinksSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'External Links & Databases',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (manga.malId > 0)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2E51A2),
                    child: Text('MAL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  title: const Text('MyAnimeList'),
                  subtitle: Text('ID: ${manga.malId}'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrlString('https://myanimelist.net/manga/${manga.malId}');
                  },
                ),
              if (manga.anilistId != null && manga.anilistId! > 0)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF02A9FF),
                    child: Text('AL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  title: const Text('AniList'),
                  subtitle: Text('ID: ${manga.anilistId}'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrlString('https://anilist.co/manga/${manga.anilistId}');
                  },
                ),
              if (manga.url != null && manga.url!.isNotEmpty)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.public, color: Colors.white, size: 20),
                  ),
                  title: const Text('Source Website'),
                  subtitle: Text(manga.url!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrlString(manga.url!);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasExternalLinks =
        (manga.malId > 0) ||
        (manga.anilistId != null && manga.anilistId! > 0) ||
        (manga.url != null && manga.url!.isNotEmpty);

    return SliverAppBar(
      expandedHeight: 400,
      floating: false,
      pinned: false,
      snap: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroSection(context),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      actions: [
        if (hasExternalLinks)
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'External Links (MAL, AniList, Web)',
              icon: const Icon(Icons.link_rounded, color: Colors.white, size: 20),
              onPressed: () => _showExternalLinksSheet(context),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            tooltip: 'Share Manga',
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            onPressed: () {
              final String shareUrl = '${AppConfig.baseUrl}/manga/${manga.id}';
              final String customSchemeUrl =
                  'open-manga-reader://manga/${manga.id}';
              final String shareText =
                  'Check out ${manga.title} on Open Manga Reader!\n\n'
                  'Read it here: $shareUrl\n'
                  'Or open in app: $customSchemeUrl';

              // ignore: deprecated_member_use
              Share.share(shareText, subject: 'Share ${manga.title}');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Stack(
      children: [
        heroImageUrl.isNotEmpty
            ? ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: CachedNetworkImage(
                  imageUrl: heroImageUrl,
                  fit: BoxFit.cover,
                  height: 400,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    height: 400,
                    color: Colors.grey[800],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 400,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                height: 400,
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
              ),
        Center(
          child: Container(
            width: 230,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: heroImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: heroImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 32,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Colors.black54,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

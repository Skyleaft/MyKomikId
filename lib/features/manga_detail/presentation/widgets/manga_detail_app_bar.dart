import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              Text(
                'External Links & Databases',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              if (manga.malId > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2E51A2),
                    child: Text(
                      'MAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: const Text('MyAnimeList'),
                  subtitle: Text('ID: ${manga.malId}'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrlString(
                      'https://myanimelist.net/manga/${manga.malId}',
                    );
                  },
                ),
              if (manga.anilistId != null && manga.anilistId! > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF02A9FF),
                    child: Text(
                      'AL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: const Text('AniList'),
                  subtitle: Text('ID: ${manga.anilistId}'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrlString(
                      'https://anilist.co/manga/${manga.anilistId}',
                    );
                  },
                ),
              if (manga.url != null && manga.url!.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.public,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text('Source Website'),
                  subtitle: Text(
                    manga.url!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasExternalLinks =
        (manga.malId > 0) ||
        (manga.anilistId != null && manga.anilistId! > 0) ||
        (manga.url != null && manga.url!.isNotEmpty);

    final Color buttonBgColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.8);
    final Color buttonIconColor = isDark ? Colors.white : Colors.black87;
    final Color buttonBorderColor = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.08);

    const double collapsedToolbarHeight = 72.0;

    return SliverAppBar(
      expandedHeight: 400,
      toolbarHeight: collapsedToolbarHeight,
      floating: false,
      pinned: true,
      snap: false,
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 56,
      leading: Center(
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: buttonBgColor,
            shape: BoxShape.circle,
            border: Border.all(color: buttonBorderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: buttonIconColor,
                  size: 20,
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (hasExternalLinks)
          Center(
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: buttonBgColor,
                shape: BoxShape.circle,
                border: Border.all(color: buttonBorderColor, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'External Links (MAL, AniList, Web)',
                    icon: Icon(
                      Icons.link_rounded,
                      color: buttonIconColor,
                      size: 20,
                    ),
                    onPressed: () => _showExternalLinksSheet(context),
                  ),
                ),
              ),
            ),
          ),
        Center(
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: buttonBgColor,
              shape: BoxShape.circle,
              border: Border.all(color: buttonBorderColor, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Share Manga',
                  icon: Icon(
                    Icons.share_rounded,
                    color: buttonIconColor,
                    size: 20,
                  ),
                  onPressed: () {
                    final String shareUrl =
                        '${AppConfig.baseUrl}/manga/${manga.id}';
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
            ),
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final isCollapsed =
              top <=
              (collapsedToolbarHeight +
                  MediaQuery.of(context).padding.top +
                  15);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            titlePadding: const EdgeInsets.only(
              left: 68,
              right: 108,
              bottom: 12,
            ),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCollapsed ? 1.0 : 0.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (heroImageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: heroImageUrl,
                        width: 34,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      manga.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            background: _buildHeroSection(context),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Stack(
      children: [
        heroImageUrl.isNotEmpty
            ? ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
        // Vignette overlay for depth
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 0.75, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 240,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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

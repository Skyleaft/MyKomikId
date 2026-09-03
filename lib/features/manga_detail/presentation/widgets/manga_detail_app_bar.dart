import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../models/manga_detail.dart';
import 'manga_detail_split_hero.dart';

class MangaDetailAppBar extends StatelessWidget {
  final MangaDetail manga;
  final String heroImageUrl;
  final int chapterCount;
  final String? heroTag;
  final VoidCallback? onRefresh;

  const MangaDetailAppBar({
    super.key,
    required this.manga,
    required this.heroImageUrl,
    this.chapterCount = 0,
    this.heroTag,
    this.onRefresh,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasExternalLinks =
        (manga.malId > 0) ||
        (manga.anilistId != null && manga.anilistId! > 0) ||
        (manga.url != null && manga.url!.isNotEmpty);

    final Color buttonBgColor = isDark
        ? const Color(0xEB0F172A)
        : const Color(0xF2FFFFFF);
    final Color buttonIconColor = isDark ? Colors.white : Colors.black87;
    final Color buttonBorderColor = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.08);

    final double expandedBarHeight = isDesktop
        ? 450.0
        : (isTablet ? 410.0 : 380.0);
    const double collapsedToolbarHeight = 68.0;

    return SliverAppBar(
      expandedHeight: expandedBarHeight,
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
      actions: [
        if (onRefresh != null)
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
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Refresh Manga (F5)',
                icon: Icon(
                  Icons.refresh_rounded,
                  color: buttonIconColor,
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRefresh!();
                },
              ),
            ),
          ),
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
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Share Manga',
              icon: Icon(
                Icons.share_rounded,
                color: buttonIconColor,
                size: 19,
              ),
              onPressed: () {
                final baseUrl = AppConfig.baseUrl;
                final webShareUrl = '$baseUrl/manga/${manga.id}';
                final customSchemeUrl =
                    'open-manga-reader://manga/${manga.id}';
                final shareText =
                    'Read ${manga.title} on Open Manga Reader!\n\n'
                    'Web link: $webShareUrl\n'
                    'Or open in app: $customSchemeUrl';

                // ignore: deprecated_member_use
                Share.share(shareText, subject: 'Share ${manga.title}');
              },
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

          final isHeroVisible = top > 200;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            titlePadding: const EdgeInsets.only(
              left: 68,
              right: 108,
              bottom: 14,
            ),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isCollapsed ? 1.0 : 0.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (heroImageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: heroImageUrl,
                        width: 32,
                        height: 44,
                        memCacheWidth: 100,
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
            background: _buildParallaxBackdropAndHero(
              context,
              isDark,
              isHeroVisible: isHeroVisible,
            ),
          );
        },
      ),
    );
  }

  Widget _buildParallaxBackdropAndHero(
    BuildContext context,
    bool isDark, {
    required bool isHeroVisible,
  }) {
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred Backdrop Image (isolated in RepaintBoundary for silky GPU caching)
        if (heroImageUrl.isNotEmpty)
          RepaintBoundary(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: CachedNetworkImage(
                imageUrl: heroImageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 80,
                maxWidthDiskCache: 300,
                filterQuality: FilterQuality.low,
                placeholder: (_, _) => Container(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey[300],
                ),
                errorBuilder: (_, _, _) => Container(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey[300],
                ),
              ),
            ),
          )
        else
          Container(color: isDark ? const Color(0xFF0F172A) : Colors.grey[300]),

        // Rich Vignette Gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 0.72, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.25),
                  bgColor.withValues(alpha: 0.8),
                  bgColor,
                ],
              ),
            ),
          ),
        ),

        // Split Hero centered within max width constraints
        Positioned(
          left: 0,
          right: 0,
          bottom: 14,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MangaDetailSplitHero(
                  manga: manga,
                  heroImageUrl: heroImageUrl,
                  chapterCount: chapterCount,
                  isDark: isDark,
                  heroTag: heroTag,
                  isHeroVisible: isHeroVisible,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../di/injection.dart';
import '../models/manga_summary.dart';
import '../network/manga_api_service.dart';
import 'shimmer_box.dart';

class DiscoverCard extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? localImageUrl;
  final String type;
  final String views;
  final LatestChapterSummary? latestChapter;
  final List<String> genres;
  final String? status;
  final double? rating;
  final String? heroTag;
  final VoidCallback? onTap;

  const DiscoverCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.localImageUrl,
    required this.type,
    required this.views,
    required this.latestChapter,
    required this.genres,
    this.status,
    this.rating,
    this.heroTag,
    this.onTap,
  });

  @override
  State<DiscoverCard> createState() => _DiscoverCardState();
}

class _DiscoverCardState extends State<DiscoverCard> {
  bool _isHovered = false;

  Color _getTypeColor(String type) {
    return switch (type.toLowerCase()) {
      'manhwa' => const Color(0xFF8B5CF6), // Purple / Indigo
      'manhua' => const Color(0xFF06B6D4), // Cyan
      'novel' => const Color(0xFFF59E0B), // Amber
      _ => AppColors.primary, // Manga / Default
    };
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
    return switch (status.toLowerCase()) {
      'ongoing' => const Color(0xFF10B981), // Emerald Green
      'completed' || 'finished' || 'end' => const Color(0xFF3B82F6), // Blue
      'hiatus' || 'onhold' => const Color(0xFFF97316), // Orange
      'dropped' => const Color(0xFFEF4444), // Crimson Red
      _ => Colors.grey.shade600,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final String displayUrl = getIt<MangaApiService>().getLocalImageUrl(
      widget.localImageUrl,
      widget.imageUrl,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    final double borderRadius = isDesktop ? 16 : (isTablet ? 14 : 12);
    final double titleFontSize = isDesktop ? 14.5 : (isTablet ? 13.5 : 12.5);
    final double genreFontSize = isDesktop ? 11 : (isTablet ? 10.5 : 10);
    final double badgeFontSize = isDesktop ? 10 : (isTablet ? 9.5 : 9);
    final double iconSize = isDesktop ? 13 : (isTablet ? 12 : 11);

    Widget coverCard = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isHovered
                  ? (isDark ? 0.45 : 0.2)
                  : (isDark ? 0.3 : 0.1),
            ),
            blurRadius: _isHovered ? 16 : 8,
            offset: Offset(0, _isHovered ? 8 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cached Image
            if (displayUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: displayUrl,
                fit: BoxFit.cover,
                memCacheWidth: 400,
                maxWidthDiskCache: 600,
                placeholder: (_, _) => ShimmerBox(
                  borderRadius: borderRadius,
                ),
                errorBuilder: (_, _, _) =>
                    _buildPlaceholder(iconSize * 3),
              )
            else
              _buildPlaceholder(iconSize * 3),

            // Gradient Vignette Scrim (Top & Bottom for Contrast)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.25, 0.65, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Top Left: Type Badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _getTypeColor(widget.type)
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  widget.type.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Top Right: Status & Rating Badges
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.status != null &&
                      widget.status!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.status)
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.status!.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: badgeFontSize - 0.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: const Color(0xFFFBBF24),
                          size: iconSize + 2,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (widget.rating == null ||
                                  widget.rating == 0)
                              ? 'N/A'
                              : widget.rating!.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Badges: Latest Chapter & Views
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary
                            .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        'Ch. ${widget.latestChapter?.number.toInt() ?? 0}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: badgeFontSize + 0.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: Colors.white70,
                          size: iconSize,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          widget.views,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.heroTag != null && widget.heroTag!.isNotEmpty) {
      coverCard = Hero(
        tag: widget.heroTag!,
        transitionOnUserGestures: true,
        createRectTween: (begin, end) =>
            MaterialRectArcTween(begin: begin, end: end),
        flightShuttleBuilder: (
          flightContext,
          animation,
          flightDirection,
          fromHeroContext,
          toHeroContext,
        ) {
          return Material(
            color: Colors.transparent,
            child: toHeroContext.widget,
          );
        },
        child: coverCard,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image with Badges & Vignette
              Expanded(child: coverCard),

              // Title and Genres Information
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.genres.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  widget.genres.join(' • '),
                  style: GoogleFonts.inter(
                    fontSize: genreFontSize,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double iconSize) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: AppColors.primary.withValues(alpha: 0.5),
          size: iconSize,
        ),
      ),
    );
  }
}

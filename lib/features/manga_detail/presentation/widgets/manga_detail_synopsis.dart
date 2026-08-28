import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class MangaDetailSynopsis extends StatefulWidget {
  final String? description;

  const MangaDetailSynopsis({super.key, this.description});

  @override
  State<MangaDetailSynopsis> createState() => _MangaDetailSynopsisState();
}

class _MangaDetailSynopsisState extends State<MangaDetailSynopsis> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = (widget.description ?? '').trim().isNotEmpty
        ? widget.description!.trim()
        : 'No synopsis available for this title.';
    final hasLongText = text.length > 180;

    final TextStyle textStyle = GoogleFonts.inter(
      color: isDark ? Colors.white70 : const Color(0xFF475569),
      height: 1.65,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeInCubic,
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
          secondChild: Text(
            text,
            style: textStyle,
          ),
        ),
        if (hasLongText) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Show less' : 'Read more',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

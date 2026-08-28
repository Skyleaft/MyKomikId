import 'package:flutter/material.dart';
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
    final text = widget.description ?? 'No description available';
    final hasLongText = text.length > 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          maxLines: _isExpanded ? null : 4,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.blueGrey,
            height: 1.6,
            fontSize: 14,
          ),
        ),
        if (hasLongText) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Text(
              _isExpanded ? 'Show less' : 'Read more',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MangaDetailChapterHeader extends StatefulWidget {
  final bool isAscending;
  final VoidCallback onToggleSort;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onScrapChapters;

  const MangaDetailChapterHeader({
    super.key,
    required this.isAscending,
    required this.onToggleSort,
    required this.onSearchChanged,
    required this.onScrapChapters,
  });

  @override
  State<MangaDetailChapterHeader> createState() => _MangaDetailChapterHeaderState();
}

class _MangaDetailChapterHeaderState extends State<MangaDetailChapterHeader> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSearching) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.slate700.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search chapter number...',
                  hintStyle: TextStyle(
                    color: (isDark ? Colors.white70 : Colors.black54)
                        .withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  widget.onSearchChanged(value.trim());
                },
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                widget.onSearchChanged('');
              },
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Chapters',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _isSearching = true),
              icon: const Icon(
                Icons.search,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: widget.onScrapChapters,
              icon: const Icon(
                Icons.cloud_download_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            TextButton.icon(
              onPressed: widget.onToggleSort,
              icon: Text(
                widget.isAscending ? 'Oldest' : 'Latest',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              label: AnimatedRotation(
                turns: widget.isAscending ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.swap_vert,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

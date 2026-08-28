import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/manga_api_service.dart';
import '../../models/query_paged_manga_request.dart';

class FilterDialog extends StatefulWidget {
  final MangaAdvancedFilter initialFilter;
  final MangaSortOption initialSort;
  final Function(MangaAdvancedFilter filter, MangaSortOption sort) onApply;

  const FilterDialog({
    super.key,
    required this.initialFilter,
    required this.initialSort,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  final _apiService = getIt<MangaApiService>();

  List<String> _genres = [];
  List<String> _types = [];
  final List<String> _statuses = [
    'Ongoing',
    'Completed',
    'On Hiatus',
    'Discontinued',
    'Unknown',
  ];

  bool _isLoading = true;

  // Filter state
  late List<String> _includedGenres;
  late List<String> _excludedGenres;
  late String _genreMatchMode;
  late List<String> _selectedTypes;
  late List<String> _selectedStatuses;
  late TextEditingController _authorController;
  double? _minRating;
  int? _minChapters;
  bool? _nsfw; // null = all, false = safe only, true = nsfw only

  // Sort state
  late String _selectedSortBy;
  late String _selectedOrderBy;

  @override
  void initState() {
    super.initState();
    _includedGenres = List.from(widget.initialFilter.includedGenres);
    _excludedGenres = List.from(widget.initialFilter.excludedGenres);
    _genreMatchMode = widget.initialFilter.genreMatchMode ?? 'and';
    _selectedTypes = List.from(widget.initialFilter.types);
    _selectedStatuses = List.from(widget.initialFilter.statuses);
    _authorController =
        TextEditingController(text: widget.initialFilter.author ?? '');
    _minRating = widget.initialFilter.minRating;
    _minChapters = widget.initialFilter.minChapters;
    _nsfw = widget.initialFilter.nsfw ?? false;

    _selectedSortBy = widget.initialSort.field;
    _selectedOrderBy = widget.initialSort.direction;

    _fetchFilterData();
  }

  @override
  void dispose() {
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _fetchFilterData() async {
    try {
      final genres = await _apiService.getAllGenres();
      final types = await _apiService.getAllTypes();

      if (mounted) {
        setState(() {
          _genres = genres;
          _types = types.isNotEmpty
              ? types
              : ['Manga', 'Manhwa', 'Manhua', 'Novel'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _types = ['Manga', 'Manhwa', 'Manhua', 'Novel'];
          _isLoading = false;
        });
      }
    }
  }

  void _resetAll() {
    setState(() {
      _includedGenres.clear();
      _excludedGenres.clear();
      _genreMatchMode = 'and';
      _selectedTypes.clear();
      _selectedStatuses.clear();
      _authorController.clear();
      _minRating = null;
      _minChapters = null;
      _nsfw = false;
      _selectedSortBy = 'updatedAt';
      _selectedOrderBy = 'desc';
    });
  }

  int _calculateActiveFilters() {
    int count = 0;
    count += _includedGenres.length;
    count += _excludedGenres.length;
    count += _selectedTypes.length;
    count += _selectedStatuses.length;
    if (_authorController.text.trim().isNotEmpty) count++;
    if (_minRating != null) count++;
    if (_minChapters != null) count++;
    if (_nsfw != false) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCount = _calculateActiveFilters();

    if (_isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Loading filters...'),
            ],
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Advanced Filters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: _resetAll,
                  child: const Text(
                    'Reset All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort By
                  _buildSectionHeader(
                    title: 'Sort By',
                    icon: Icons.sort_rounded,
                  ),
                  _buildSortByGroup(),
                  const SizedBox(height: 20),

                  // Sort Order
                  _buildSectionHeader(
                    title: 'Order Direction',
                    icon: Icons.swap_vert_rounded,
                  ),
                  _buildOrderGroup(),
                  const SizedBox(height: 24),

                  // Status
                  _buildSectionHeader(
                    title: 'Status',
                    icon: Icons.info_outline_rounded,
                    subtitle: 'Multiple selection allowed',
                  ),
                  _buildMultiChoiceGroup(
                    items: _statuses,
                    selectedItems: _selectedStatuses,
                    onToggle: (status) {
                      setState(() {
                        if (_selectedStatuses.contains(status)) {
                          _selectedStatuses.remove(status);
                        } else {
                          _selectedStatuses.add(status);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Type
                  _buildSectionHeader(
                    title: 'Type',
                    icon: Icons.category_outlined,
                    subtitle: 'Multiple selection allowed',
                  ),
                  _buildMultiChoiceGroup(
                    items: _types,
                    selectedItems: _selectedTypes,
                    onToggle: (type) {
                      setState(() {
                        if (_selectedTypes.contains(type)) {
                          _selectedTypes.remove(type);
                        } else {
                          _selectedTypes.add(type);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Genres (Tri-state Include / Exclude)
                  _buildGenresSection(isDark),
                  const SizedBox(height: 24),

                  // Minimum Rating
                  _buildSectionHeader(
                    title: 'Minimum Rating',
                    icon: Icons.star_rounded,
                  ),
                  _buildRatingGroup(),
                  const SizedBox(height: 24),

                  // Minimum Chapters
                  _buildSectionHeader(
                    title: 'Minimum Chapters',
                    icon: Icons.menu_book_rounded,
                  ),
                  _buildChaptersGroup(),
                  const SizedBox(height: 24),

                  // Author / Artist
                  _buildSectionHeader(
                    title: 'Author / Artist',
                    icon: Icons.person_outline_rounded,
                  ),
                  TextField(
                    controller: _authorController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Oda Eiichiro, Chugong...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.cardDark
                          : Colors.grey.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // NSFW Setting
                  _buildSectionHeader(
                    title: 'Age Rating (NSFW)',
                    icon: Icons.shield_outlined,
                  ),
                  _buildNsfwGroup(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final filter = widget.initialFilter.copyWith(
                    includedGenres: _includedGenres,
                    excludedGenres: _excludedGenres,
                    genreMatchMode: _genreMatchMode,
                    statuses: _selectedStatuses,
                    types: _selectedTypes,
                    author: _authorController.text.trim().isEmpty
                        ? null
                        : _authorController.text.trim(),
                    minRating: _minRating,
                    minChapters: _minChapters,
                    nsfw: _nsfw,
                    clearAuthor: _authorController.text.trim().isEmpty,
                    clearMinRating: _minRating == null,
                    clearMinChapters: _minChapters == null,
                    clearNsfw: _nsfw == null,
                  );

                  final sort = MangaSortOption(
                    field: _selectedSortBy,
                    direction: _selectedOrderBy,
                  );

                  widget.onApply(filter, sort);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  activeCount > 0
                      ? 'Apply Filters ($activeCount)'
                      : 'Apply Filters',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(
              '($subtitle)',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenresSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              title: 'Genres',
              icon: Icons.local_offer_outlined,
            ),
            // AND / OR match mode toggle
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardDark
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniSegment(
                    label: 'AND',
                    isSelected: _genreMatchMode == 'and',
                    onTap: () => setState(() => _genreMatchMode = 'and'),
                  ),
                  _buildMiniSegment(
                    label: 'OR',
                    isSelected: _genreMatchMode == 'or',
                    onTap: () => setState(() => _genreMatchMode = 'or'),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Legend banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark.withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap once: Include (green) • Tap twice: Exclude (red)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genres.map((genre) {
            final isIncluded = _includedGenres.contains(genre);
            final isExcluded = _excludedGenres.contains(genre);

            Color chipBorderColor;
            Color chipBgColor;
            Color textColor;
            IconData? chipIcon;

            if (isIncluded) {
              chipBorderColor = const Color(0xFF10B981);
              chipBgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
              textColor = const Color(0xFF10B981);
              chipIcon = Icons.check_rounded;
            } else if (isExcluded) {
              chipBorderColor = const Color(0xFFEF4444);
              chipBgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
              textColor = const Color(0xFFEF4444);
              chipIcon = Icons.close_rounded;
            } else {
              chipBorderColor = isDark
                  ? Colors.white12
                  : Colors.grey.withValues(alpha: 0.25);
              chipBgColor = Colors.transparent;
              textColor = isDark ? Colors.white70 : Colors.grey[700]!;
              chipIcon = null;
            }

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isIncluded) {
                    // Switch from Include -> Exclude
                    _includedGenres.remove(genre);
                    _excludedGenres.add(genre);
                  } else if (isExcluded) {
                    // Switch from Exclude -> Neutral
                    _excludedGenres.remove(genre);
                  } else {
                    // Switch from Neutral -> Include
                    _includedGenres.add(genre);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: chipBgColor,
                  border: Border.all(color: chipBorderColor, width: 1.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chipIcon != null) ...[
                      Icon(chipIcon, size: 14, color: textColor),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      genre,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: isIncluded || isExcluded
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMiniSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiChoiceGroup({
    required List<String> items,
    required List<String> selectedItems,
    required Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return _buildOptionChip(
          label: item,
          isSelected: isSelected,
          onTap: () => onToggle(item),
          icon: isSelected ? Icons.check_rounded : null,
        );
      }).toList(),
    );
  }

  Widget _buildSortByGroup() {
    final sortOptions = {
      'updatedAt': 'Latest Update',
      'rating': 'Highest Rating',
      'popularity': 'Popularity',
      'totalView': 'Total Views',
      'releaseDate': 'Release Date',
      'title': 'Title / Name',
      'latestChapter': 'Latest Chapter',
      'createdAt': 'Recently Added',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortOptions.entries.map((e) {
        final isSelected = _selectedSortBy == e.key;
        return _buildOptionChip(
          label: e.value,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedSortBy = e.key),
        );
      }).toList(),
    );
  }

  Widget _buildOrderGroup() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionChip(
            label: 'Descending (Z-A / High-Low)',
            isSelected: _selectedOrderBy == 'desc',
            onTap: () => setState(() => _selectedOrderBy = 'desc'),
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOptionChip(
            label: 'Ascending (A-Z / Low-High)',
            isSelected: _selectedOrderBy == 'asc',
            onTap: () => setState(() => _selectedOrderBy = 'asc'),
            icon: Icons.arrow_upward_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingGroup() {
    final ratingOptions = <double?>[null, 6.0, 7.0, 8.0, 8.5, 9.0];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ratingOptions.map((rating) {
        final isSelected = _minRating == rating;
        return _buildOptionChip(
          label: rating == null ? 'Any Rating' : '⭐ ${rating.toStringAsFixed(1)}+',
          isSelected: isSelected,
          onTap: () => setState(() => _minRating = rating),
        );
      }).toList(),
    );
  }

  Widget _buildChaptersGroup() {
    final chapterOptions = <int?>[null, 10, 30, 50, 100, 200];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chapterOptions.map((chapters) {
        final isSelected = _minChapters == chapters;
        return _buildOptionChip(
          label: chapters == null ? 'Any Length' : '$chapters+ Chapters',
          isSelected: isSelected,
          onTap: () => setState(() => _minChapters = chapters),
        );
      }).toList(),
    );
  }

  Widget _buildNsfwGroup() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionChip(
            label: 'All Content',
            isSelected: _nsfw == null,
            onTap: () => setState(() => _nsfw = null),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOptionChip(
            label: 'Safe Only',
            isSelected: _nsfw == false,
            onTap: () => setState(() => _nsfw = false),
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOptionChip(
            label: '18+ Only',
            isSelected: _nsfw == true,
            onTap: () => setState(() => _nsfw = true),
            icon: Icons.warning_amber_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? AppColors.cardDark : Colors.transparent),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.25)),
            width: isSelected ? 1.4 : 1.0,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white60 : Colors.grey[600]),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : Colors.grey[700]),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

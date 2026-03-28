import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/services/manga_api_service.dart';

class FilterDialog extends StatefulWidget {
  final List<String> initialGenres;
  final String? initialType;
  final String? initialStatus;
  final String initialSortBy;
  final String initialOrderBy;
  final Function(
    List<String> genres,
    String? type,
    String? status,
    String sortBy,
    String orderBy,
  )
  onApply;

  const FilterDialog({
    super.key,
    required this.initialGenres,
    this.initialType,
    this.initialStatus,
    required this.initialSortBy,
    required this.initialOrderBy,
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
  String? _error;

  late List<String> _selectedGenres;
  String? _selectedType;
  String? _selectedStatus;
  late String _selectedSortBy;
  late String _selectedOrderBy;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.initialGenres);
    _selectedType = widget.initialType;
    _selectedStatus = widget.initialStatus;
    _selectedSortBy = widget.initialSortBy;
    _selectedOrderBy = widget.initialOrderBy;
    _fetchFilterData();
  }

  Future<void> _fetchFilterData() async {
    try {
      final genres = await _apiService.getAllGenres();
      final types = await _apiService.getAllTypes();

      if (mounted) {
        setState(() {
          _genres = genres;
          _types = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load filters: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedGenres.clear();
                      _selectedType = null;
                      _selectedStatus = null;
                      _selectedSortBy = 'updatedAt';
                      _selectedOrderBy = 'desc';
                    });
                  },
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
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Sort By'),
                  _buildSortByGroup(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Sort Order'),
                  _buildOrderGroup(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Status'),
                  _buildChoiceGroup(
                    items: _statuses,
                    selectedItem: _selectedStatus,
                    onSelected: (val) => setState(() => _selectedStatus = val),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Type'),
                  _buildChoiceGroup(
                    items: _types,
                    selectedItem: _selectedType,
                    onSelected: (val) => setState(() => _selectedType = val),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Genres'),
                  _buildFilterGroup(
                    items: _genres,
                    selectedItems: _selectedGenres,
                    onToggle: (type, selected) {
                      setState(() {
                        if (selected) {
                          _selectedGenres.add(type);
                        } else {
                          _selectedGenres.remove(type);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(
                    _selectedGenres,
                    _selectedType,
                    _selectedStatus,
                    _selectedSortBy,
                    _selectedOrderBy,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildChoiceGroup({
    required List<String> items,
    required String? selectedItem,
    required Function(String?) onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final isSelected = selectedItem == item;
        return _buildOptionChip(
          label: item,
          isSelected: isSelected,
          onTap: () => onSelected(isSelected ? null : item),
        );
      }).toList(),
    );
  }

  Widget _buildFilterGroup({
    required List<String> items,
    required List<String> selectedItems,
    required Function(String, bool) onToggle,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return _buildOptionChip(
          label: item,
          isSelected: isSelected,
          onTap: () => onToggle(item, !isSelected),
          icon: isSelected ? Icons.check_rounded : null,
        );
      }).toList(),
    );
  }

  Widget _buildSortByGroup() {
    final sortOptions = {
      'updatedAt': 'Updated',
      'title': 'Name',
      'popularity': 'Popularity',
      'rating': 'Rating',
      'releaseDate': 'Release Date',
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildOptionChip(
          label: 'Ascending',
          isSelected: _selectedOrderBy == 'asc',
          onTap: () => setState(() => _selectedOrderBy = 'asc'),
          icon: Icons.arrow_upward_rounded,
        ),
        _buildOptionChip(
          label: 'Descending',
          isSelected: _selectedOrderBy == 'desc',
          onTap: () => setState(() => _selectedOrderBy = 'desc'),
          icon: Icons.arrow_downward_rounded,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
            if (icon != null) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

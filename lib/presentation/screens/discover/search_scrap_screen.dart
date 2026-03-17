import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_manga_reader/core/constants/app_colors.dart';
import 'package:my_manga_reader/core/di/injection.dart';
import 'package:my_manga_reader/data/services/manga_api_service.dart';
import 'package:my_manga_reader/routes/app_pages.dart';
import 'package:my_manga_reader/data/models/search_result.dart';
import 'dart:async';
import 'package:dio/dio.dart';

class SearchScrapScreen extends StatefulWidget {
  const SearchScrapScreen({super.key});

  @override
  State<SearchScrapScreen> createState() => _SearchScrapScreenState();
}

class _SearchScrapScreenState extends State<SearchScrapScreen> {
  final _searchController = TextEditingController();
  final _apiService = getIt<MangaApiService>();

  bool _isLoadingSearch = false;
  bool _isLoadingProviders = false;
  List<SearchResult> _searchResults = [];
  List<Map<String, dynamic>> _providers = [];
  List<String>? _selectedGenres;
  String? _selectedStatus;
  String? _selectedType;
  String? _error;

  String _selectedProviderName = '';

  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMoreResults = true;

  Timer? _debounceTimer;
  CancelToken? _searchCancelToken;
  int _searchRequestCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCancelToken?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoadingProviders = true);

    try {
      final response = await _apiService.getScrapProviders();
      _providers = response;

      if (_providers.isNotEmpty) {
        _selectedProviderName = _providers[0]['providerName'];
      }
    } catch (e) {
      _providers = [
        {'providerName': 'Komiku'},
        {'providerName': 'Kiryuu'},
      ];

      _selectedProviderName = 'Komiku';
    }

    setState(() => _isLoadingProviders = false);

    // Auto load first page
    _performSearch();
  }

  void _onSearchChanged() {
    // Only update search query, don't perform search
    _searchQuery = _searchController.text;
  }

  Future<void> _performSearch() async {
    final query = _searchQuery.trim();
    final currentRequestCounter = ++_searchRequestCounter;

    // Cancel any ongoing search request
    _searchCancelToken?.cancel();
    _searchCancelToken = CancelToken();

    setState(() {
      _isLoadingSearch = true;
      _error = null;

      if (_currentPage == 1) {
        _searchResults = [];
      }
    });

    try {
      final results = await _apiService.searchScrapSource(
        keyword: query,
        genres: _selectedGenres,
        status: _selectedStatus,
        type: _selectedType,
        page: _currentPage,
        provider: _selectedProviderName,
      );

      // Check if this request is still the latest one
      if (currentRequestCounter != _searchRequestCounter) {
        return; // Ignore results from cancelled request
      }

      if (!mounted) return;

      setState(() {
        if (_currentPage == 1) {
          _searchResults = results
              .map((e) => SearchResult.fromJson(e))
              .toList();
        } else {
          _searchResults.addAll(
            results.map((e) => SearchResult.fromJson(e)).toList(),
          );
        }

        _isLoadingSearch = false;

        _hasMoreResults = results.isNotEmpty;
      });
    } catch (e) {
      // Check if this request was cancelled
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return; // Ignore cancelled request
      }

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoadingSearch = false;
      });
    }
  }

  Future<void> _scrapManga(String mangaUrl) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      await _apiService.scrapManga(mangaUrl, false, _selectedProviderName);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scraping added to queue!')));
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to scrap: $e')));
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingSearch || !_hasMoreResults) return;

    _currentPage++;
    await _performSearch();
  }

  Future<void> _showFilterDialog() async {
    final genres = await _apiService.getAllGenres();
    final types = await _apiService.getAllTypes();

    final selectedGenres = <String>[];
    final selectedTypes = <String>[];
    String? selectedStatus;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Results'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Genres
                const Text(
                  'Genres',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: genres.map((genre) {
                    return FilterChip(
                      label: Text(genre),
                      selected: selectedGenres.contains(genre),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedGenres.add(genre);
                          } else {
                            selectedGenres.remove(genre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Types
                const Text(
                  'Types',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: types.map((type) {
                    return FilterChip(
                      label: Text(type),
                      selected: selectedTypes.contains(type),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedTypes.add(type);
                          } else {
                            selectedTypes.remove(type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Status
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Ongoing'),
                        value: 'ongoing',
                        groupValue: selectedStatus,
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Completed'),
                        value: 'completed',
                        groupValue: selectedStatus,
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                _selectedGenres = selectedGenres.isEmpty
                    ? null
                    : List.from(selectedGenres);
                _selectedType = selectedTypes.isEmpty
                    ? null
                    : selectedTypes.first;
                _selectedStatus = selectedStatus;

                _currentPage = 1;
                _hasMoreResults = true;

                _performSearch();
              },
              child: const Text('Apply Filter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDarkMode ? Colors.white : AppColors.primary;
    final cardColor = isDarkMode ? AppColors.cardDark : Colors.white;
    final shadowColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Manga',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: textColor),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search titles, authors, or genres...',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 14, color: textColor),
                      onSubmitted: (value) {
                        // Trigger search when Enter is pressed
                        _searchQuery = value.trim();
                        _currentPage = 1;
                        _hasMoreResults = true;
                        _performSearch();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Provider Selector
          if (_providers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButton<String>(
                  value: _selectedProviderName,
                  isExpanded: true,
                  underline: Container(),
                  dropdownColor: cardColor,
                  style: TextStyle(color: textColor, fontSize: 14),
                  items: _providers.map((provider) {
                    return DropdownMenuItem<String>(
                      value: provider['providerName'],
                      child: Text(
                        provider['providerName'],
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProviderName = value!;
                      _selectedGenres = null;
                      _selectedStatus = null;
                      _selectedType = null;
                      _currentPage = 1;
                      _hasMoreResults = true;
                      _searchResults = [];
                    });

                    _performSearch(); // ✅ dipanggil di luar setState
                  },
                ),
              ),
            ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Search Results (${_searchResults.length})'
                      : 'Search Results (0)',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_providers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _selectedProviderName,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Error Message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.red.withOpacity(0.2)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),

          // Search Results
          Expanded(
            child:
                _searchResults.isEmpty &&
                    !_isLoadingSearch &&
                    _searchQuery.isEmpty
                ? Center(
                    child: Text(
                      'Search for manga to get started',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  )
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.cardDark : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.primary;
    final shadowColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.1);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          // Check if we're near the bottom (within 100 pixels) and there are more results
          if (metrics.pixels >= metrics.maxScrollExtent - 100 &&
              _hasMoreResults &&
              !_isLoadingSearch) {
            _loadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        itemCount: _searchResults.length + (_isLoadingSearch ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _searchResults.length) {
            final item = _searchResults[index];
            return _buildResultCard(
              item,
              isDarkMode,
              cardColor,
              textColor,
              shadowColor,
            );
          } else {
            // Loading indicator at the bottom
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildResultCard(
    SearchResult item,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color shadowColor,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _scrapManga(item.detailUrl),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.thumbnail.isNotEmpty
                    ? Image.network(
                        item.thumbnail,
                        width: 80,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 110,
                          color: isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[300],
                          child: Icon(
                            Icons.broken_image,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 110,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        child: Icon(
                          Icons.image,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
              ),

              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.type,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.genre,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.lastUpdateText.isNotEmpty)
                      Text(
                        item.lastUpdateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.brown[200] : Colors.brown,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ch. ${item.latestChapterNumber.toInt()}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.latestScrapped != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Updated',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: item.detailUrl.isNotEmpty
                        ? () => _scrapManga(item.detailUrl)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('SCRAP', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

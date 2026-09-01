import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/discover_card.dart';
import '../../../core/models/manga_summary.dart';
import '../../../core/models/paged_response.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../routes/app_pages.dart';
import '../../manga_detail/models/manga_detail.dart';
import '../../manga_detail/services/manga_detail_service.dart';
import '../models/query_paged_manga_request.dart';
import 'widgets/discover_header.dart';
import 'widgets/discover_grid_skeleton.dart';
import 'widgets/scrap_queue_dialog.dart';
import 'widgets/filter_dialog.dart';

class DiscoverScreen extends StatefulWidget {
  final String? initialSearch;
  final String? sortBy;

  const DiscoverScreen({super.key, this.initialSearch, this.sortBy});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  final MangaApiService _apiService = getIt<MangaApiService>();
  final MangaDetailService _detailService = getIt<MangaDetailService>();

  @override
  bool get wantKeepAlive => true;

  final List<MangaSummary> _items = [];
  bool _isLoading = false;
  bool _isMoreLoading = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  String? _searchQuery;
  bool _isSemanticSearch = false;

  MangaAdvancedFilter _filter = const MangaAdvancedFilter();
  late MangaSortOption _sortOption;

  late final ScrollController _scrollController;
  bool _showScrollToTop = false;

  Timer? _debounceTimer;
  int _requestCounter = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchQuery = widget.initialSearch;
    _sortOption = MangaSortOption(
      field: widget.sortBy ?? 'updatedAt',
      direction: 'desc',
    );
    _fetchData(refresh: true);
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearch != oldWidget.initialSearch ||
        widget.sortBy != oldWidget.sortBy) {
      _searchQuery = widget.initialSearch;
      _sortOption = MangaSortOption(
        field: widget.sortBy ?? 'updatedAt',
        direction: 'desc',
      );
      _fetchData(refresh: true);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.hasClients && _scrollController.offset > 400;
    if (show != _showScrollToTop) {
      setState(() {
        _showScrollToTop = show;
      });
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _fetchData({bool refresh = false}) async {
    if (refresh) {
      _debounceTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _currentPage = 1;
        _items.clear();
        _hasMore = true;
        _isLoading = true;
      });
    } else if (!_hasMore || _isMoreLoading || _isLoading) {
      return;
    }

    if (_currentPage > 1) {
      setState(() {
        _isMoreLoading = true;
      });
    }

    final currentRequest = ++_requestCounter;

    try {
      final PagedResponse<MangaSummary> response;
      if (_isSemanticSearch &&
          _searchQuery != null &&
          _searchQuery!.isNotEmpty) {
        final items = await _apiService.searchSemantic(
          _searchQuery!,
          limit: 30,
        );
        response = PagedResponse<MangaSummary>(
          items: items,
          page: 1,
          pageSize: 30,
          totalCount: items.length,
          totalPages: 1,
          hasPreviousPage: false,
          hasNextPage: false,
        );
      } else {
        final request = QueryPagedMangaRequest(
          filter: _filter.copyWith(
            search: _searchQuery,
            clearSearch: _searchQuery == null || _searchQuery!.trim().isEmpty,
          ),
          sorts: [_sortOption],
          page: _currentPage,
          pageSize: _pageSize,
        );
        response = await _apiService.queryPagedManga(request);
      }

      if (currentRequest != _requestCounter || !mounted) return;

      setState(() {
        _items.addAll(response.items);
        _isLoading = false;
        _isMoreLoading = false;
        _hasMore =
            _items.length < response.totalCount &&
            !_isSemanticSearch &&
            response.items.isNotEmpty;
        if (_hasMore) _currentPage++;
      });
    } catch (e) {
      if (currentRequest != _requestCounter || !mounted) return;
      setState(() {
        _isLoading = false;
        _isMoreLoading = false;
      });
      AlertBanner.show(
        context,
        'Error loading manga: ${e.toString()}',
        type: AlertBannerType.error,
      );
    }
  }

  void _onSearch(String value) {
    final newQuery = value.trim().isEmpty ? null : value.trim();
    if (_searchQuery == newQuery) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _searchQuery = newQuery;
      _fetchData(refresh: true);
    });
  }

  void _onShowQueue() {
    showDialog(
      context: context,
      builder: (context) => const ScrapQueueDialog(),
    );
  }

  void _onSearchScrapSource() {
    Navigator.pushNamed(context, AppRoutes.searchScrap);
  }

  void _onFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterDialog(
        initialFilter: _filter,
        initialSort: _sortOption,
        onApply: (newFilter, newSort) {
          setState(() {
            _filter = newFilter;
            _sortOption = newSort;
          });
          _fetchData(refresh: true);
        },
      ),
    );
  }

  Future<void> _navigateToDetail(MangaSummary item) async {
    final heroTag = 'manga-cover-discover-${item.id}';
    // Fast path: Check local cache first
    try {
      final cached = await _detailService.getDetail(item.id);
      if (cached != null && mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        await Navigator.pushNamed(
          context,
          AppRoutes.detail,
          arguments: {
            'manga': cached,
            'heroTag': heroTag,
          },
        );
        return;
      }
    } catch (_) {}

    // Fallback: Fetch from API with non-blocking feedback
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final detailData = await _apiService.getMangaDetail(item.id);
      if (!mounted) return;
      Navigator.pop(context);

      final mangaDetail = MangaDetail.fromMap(detailData);
      await _detailService.saveDetail(mangaDetail);

      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      await Navigator.pushNamed(
        context,
        AppRoutes.detail,
        arguments: {
          'manga': mangaDetail,
          'heroTag': heroTag,
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AlertBanner.show(
        context,
        'Failed to load details: $e',
        type: AlertBannerType.error,
      );
    }
  }

  SliverGridDelegateWithFixedCrossAxisCount _buildGridDelegate() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    final int crossAxisCount = isDesktop
        ? 5
        : isTablet
        ? 3
        : 2;

    final double mainAxisSpacing = isDesktop
        ? 32
        : isTablet
        ? 28
        : 24;

    final double crossAxisSpacing = isDesktop
        ? 24
        : isTablet
        ? 20
        : 16;

    final double childAspectRatio = isDesktop
        ? 0.75
        : isTablet
        ? 0.70
        : 0.65;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }

  bool get _hasActiveFilters => _filter.hasActiveFilters;

  void _clearAllFilters() {
    setState(() {
      _filter = const MangaAdvancedFilter(nsfw: false);
      _searchQuery = null;
    });
    _fetchData(refresh: true);
  }

  Widget _buildActiveFilterChips(bool isDark) {
    if (!_hasActiveFilters) return const SizedBox.shrink();

    final chips = <Widget>[];

    // Included Genres
    for (final genre in _filter.includedGenres) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(genre, style: const TextStyle(fontSize: 12)),
            avatar: const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Color(0xFF10B981),
            ),
            selected: true,
            selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
            checkmarkColor: const Color(0xFF10B981),
            onDeleted: () {
              final newIncluded = List<String>.from(_filter.includedGenres)
                ..remove(genre);
              setState(() {
                _filter = _filter.copyWith(includedGenres: newIncluded);
              });
              _fetchData(refresh: true);
            },
          ),
        ),
      );
    }

    // Excluded Genres
    for (final genre in _filter.excludedGenres) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text('NOT: $genre', style: const TextStyle(fontSize: 12)),
            avatar: const Icon(
              Icons.cancel_rounded,
              size: 14,
              color: Color(0xFFEF4444),
            ),
            selected: true,
            selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
            checkmarkColor: const Color(0xFFEF4444),
            onDeleted: () {
              final newExcluded = List<String>.from(_filter.excludedGenres)
                ..remove(genre);
              setState(() {
                _filter = _filter.copyWith(excludedGenres: newExcluded);
              });
              _fetchData(refresh: true);
            },
          ),
        ),
      );
    }

    // Types
    for (final type in _filter.types) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text('Type: $type', style: const TextStyle(fontSize: 12)),
            selected: true,
            selectedColor: Colors.blue.withValues(alpha: 0.15),
            checkmarkColor: Colors.blue,
            onDeleted: () {
              final newTypes = List<String>.from(_filter.types)..remove(type);
              setState(() {
                _filter = _filter.copyWith(types: newTypes);
              });
              _fetchData(refresh: true);
            },
          ),
        ),
      );
    }

    // Statuses
    for (final status in _filter.statuses) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(
              'Status: $status',
              style: const TextStyle(fontSize: 12),
            ),
            selected: true,
            selectedColor: Colors.teal.withValues(alpha: 0.15),
            checkmarkColor: Colors.teal,
            onDeleted: () {
              final newStatuses = List<String>.from(_filter.statuses)
                ..remove(status);
              setState(() {
                _filter = _filter.copyWith(statuses: newStatuses);
              });
              _fetchData(refresh: true);
            },
          ),
        ),
      );
    }

    // Author
    if (_filter.author != null && _filter.author!.isNotEmpty) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(
              'Author: ${_filter.author}',
              style: const TextStyle(fontSize: 12),
            ),
            selected: true,
            selectedColor: Colors.purple.withValues(alpha: 0.15),
            checkmarkColor: Colors.purple,
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(clearAuthor: true);
              });
              _fetchData(refresh: true);
            },
          ),
        ),
      );
    }

    // Min Rating
    if (_filter.minRating != null) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(
              '⭐ ${_filter.minRating!.toStringAsFixed(1)}+',
              style: const TextStyle(fontSize: 12),
            ),
            selected: true,
            selectedColor: Colors.amber.withValues(alpha: 0.15),
            checkmarkColor: Colors.amber[800],
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(clearMinRating: true);
              });
              _fetchData(refresh: true);
            },
          ),
        ),
      );
    }

    // Min Chapters
    if (_filter.minChapters != null) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(
              '${_filter.minChapters}+ Chapters',
              style: const TextStyle(fontSize: 12),
            ),
            selected: true,
            selectedColor: Colors.orange.withValues(alpha: 0.15),
            checkmarkColor: Colors.orange[800],
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(clearMinChapters: true);
              });
              _fetchData(refresh: true);
            },
          ),
        ),
      );
    }

    // NSFW (show chip when different from default Safe Only)
    if (_filter.nsfw != false) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(
              _filter.nsfw == true ? '18+ Only' : 'All Content (incl. 18+)',
              style: const TextStyle(fontSize: 12),
            ),
            selected: true,
            selectedColor: (_filter.nsfw == true ? Colors.red : Colors.orange)
                .withValues(alpha: 0.15),
            checkmarkColor: _filter.nsfw == true ? Colors.red : Colors.orange,
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(nsfw: false);
              });
              _fetchData(refresh: true);
            },
          ),
        ),
      );
    }

    chips.add(
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          avatar: const Icon(Icons.clear_all, size: 16),
          label: const Text('Clear All', style: TextStyle(fontSize: 12)),
          onPressed: _clearAllFilters,
        ),
      ),
    );

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView(scrollDirection: Axis.horizontal, children: chips),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            onRefresh: () async {
              _fetchData(refresh: true);
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 500 &&
                    !_isSemanticSearch) {
                  _fetchData();
                }
                return false;
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor:
                        (isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight)
                            .withValues(alpha: 0.8),
                    surfaceTintColor: Colors.transparent,
                    expandedHeight: 146,
                    toolbarHeight: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DiscoverHeader(
                              isDark: isDark,
                              onSearch: _onSearch,
                              onShowQueue: _onShowQueue,
                              onSearchScrapSource: _onSearchScrapSource,
                              onFilter: _onFilter,
                              onAdvancedRecommendation: () =>
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.advancedRecommendation,
                                  ),
                              hasFilters: _hasActiveFilters,
                              isSemanticSearch: _isSemanticSearch,
                              onSemanticSearchChanged: (value) {
                                setState(() {
                                  _isSemanticSearch = value;
                                });
                                _fetchData(refresh: true);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_hasActiveFilters)
                    SliverToBoxAdapter(child: _buildActiveFilterChips(isDark)),
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: DiscoverGridSkeleton(itemCount: 8),
                    )
                  else if (_items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No manga found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _hasActiveFilters
                                    ? 'Try changing your search terms or filters.'
                                    : 'No manga available at the moment.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              if (_hasActiveFilters) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset Filters'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
                      sliver: SliverGrid(
                        gridDelegate: _buildGridDelegate(),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == _items.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }
                            final item = _items[index];

                            return DiscoverCard(
                              title: item.title,
                              type: item.type,
                              latestChapter: item.latestChapter,
                              views: formatViewCount(item.totalView),
                              genres: item.genres ?? [],
                              status: item.status,
                              rating: item.rating,
                              heroTag: 'manga-cover-discover-${item.id}',
                              imageUrl: _apiService.getLocalImageUrl(
                                item.localImageUrl,
                                item.imageUrl,
                              ),
                              onTap: () => _navigateToDetail(item),
                            );
                          },
                          childCount: _items.length + (_isMoreLoading ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 90,
            child: IgnorePointer(
              ignoring: !_showScrollToTop,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                offset: _showScrollToTop ? Offset.zero : const Offset(0, 1),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _showScrollToTop ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _scrollToTop,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.92),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.4 : 0.12,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../routes/app_pages.dart';
import '../../manga_detail/models/manga_detail.dart';
import '../../manga_detail/services/manga_detail_service.dart';
import '../controllers/library_controller.dart';
import 'widgets/library_header.dart';
import 'widgets/library_manga_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final LibraryController _controller;
  final MangaApiService _apiService = getIt<MangaApiService>();
  final MangaDetailService _detailService = getIt<MangaDetailService>();

  @override
  void initState() {
    super.initState();
    _controller = LibraryController();
    _controller.loadLibrary();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToMangaDetail(String mangaId) async {
    final cached = await _detailService.getDetail(mangaId);

    if (!mounted) return;

    if (cached != null) {
      await Navigator.pushNamed(context, AppRoutes.detail, arguments: cached);
      if (mounted) _controller.loadLibrary();

      _apiService
          .getMangaDetail(mangaId)
          .then((data) {
            final fresh = MangaDetail.fromMap(data);
            _detailService.saveDetail(fresh);
          })
          .catchError((_) {});
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detailData = await _apiService.getMangaDetail(mangaId);
      if (!mounted) return;
      Navigator.pop(context);

      final mangaDetail = MangaDetail.fromMap(detailData);
      await _detailService.saveDetail(mangaDetail);

      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.detail,
        arguments: mangaDetail,
      );
      if (mounted) _controller.loadLibrary();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _controller.refresh,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: (isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight)
                      .withValues(alpha: 0.8),
                  surfaceTintColor: Colors.transparent,
                  expandedHeight: 220,
                  toolbarHeight: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: LibraryHeader(
                          isDark: isDark,
                          selectedStatus: _controller.selectedStatus,
                          onSearchChanged: _controller.setSearchQuery,
                          onStatusChanged: _controller.setSelectedStatus,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
                  sliver: _buildContent(context, isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (_controller.isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          padding: const EdgeInsets.all(24.0),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final filteredMangas = _controller.filteredMangas;

    if (filteredMangas.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              _controller.selectedStatus == 'All'
                  ? 'Your library is empty\nAdd some manga to get started!'
                  : 'No manga with status ${_controller.selectedStatus}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final manga = filteredMangas[index];
        final detail = _controller.cachedDetails[manga.id];
        return LibraryMangaCard(
          manga: manga,
          detail: detail,
          isDark: isDark,
          apiService: _apiService,
          onTap: () => _navigateToMangaDetail(manga.id),
        );
      }, childCount: filteredMangas.length),
    );
  }
}

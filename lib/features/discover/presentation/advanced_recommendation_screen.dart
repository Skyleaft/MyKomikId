import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/discover_card.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/models/manga_summary.dart';
import '../../../core/network/manga_api_service.dart';
import '../../../routes/app_pages.dart';
import '../../history/models/progression.dart';
import '../../history/services/progression_service.dart';
import '../../manga_detail/models/manga_detail.dart';
import '../../manga_detail/services/manga_detail_service.dart';
import '../models/advanced_recommendation_request.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';

class AdvancedRecommendationScreen extends StatefulWidget {
  const AdvancedRecommendationScreen({super.key});

  @override
  State<AdvancedRecommendationScreen> createState() =>
      _AdvancedRecommendationScreenState();
}

class _AdvancedRecommendationScreenState
    extends State<AdvancedRecommendationScreen> {
  final MangaApiService _apiService = getIt<MangaApiService>();
  final ProgressionService _progressionService = getIt<ProgressionService>();
  final MangaDetailService _detailService = getIt<MangaDetailService>();

  List<MangaProgression> _history = [];
  Map<String, MangaDetail> _historyDetailsMap = {};
  final Set<String> _likedIds = {};
  final Set<String> _dislikedIds = {};

  List<MangaSummary> _results = [];
  bool _isLoadingHistory = true;
  bool _isLoadingResults = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final progressions = await _progressionService.getAllProgressions();
      progressions.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
      final recent = progressions.take(20).toList();

      final detailsMap = <String, MangaDetail>{};
      for (final p in recent) {
        try {
          final cached = await _detailService.getDetail(p.mangaId);
          if (cached != null) {
            detailsMap[p.mangaId] = cached;
          } else {
            final data = await _apiService.getMangaDetail(p.mangaId);
            final detail = MangaDetail.fromMap(data);
            await _detailService.saveDetail(detail);
            detailsMap[p.mangaId] = detail;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _history = recent;
          _historyDetailsMap = detailsMap;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _getRecommendations() async {
    if (_likedIds.isEmpty && _dislikedIds.isEmpty) {
      AlertBanner.show(
        context,
        'Please select at least one manga to like or dislike.',
        type: AlertBannerType.info,
      );
      return;
    }

    setState(() {
      _isLoadingResults = true;
      _results.clear();
    });

    try {
      final request = AdvancedRecommendationRequest(
        likedIds: _likedIds.toList(),
        dislikedIds: _dislikedIds.toList(),
        limit: 20,
      );

      final items = await _apiService.getAdvancedRecommendations(request);

      if (mounted) {
        setState(() {
          _results = items;
          _isLoadingResults = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingResults = false);
        AlertBanner.show(
          context,
          'Failed to load recommendations: $e',
          type: AlertBannerType.error,
        );
      }
    }
  }

  void _navigateToDetail(MangaSummary item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final detailData = await _apiService.getMangaDetail(item.id);
      if (mounted) {
        Navigator.pop(context);
        final mangaDetail = MangaDetail.fromMap(detailData);
        Navigator.pushNamed(context, AppRoutes.detail, arguments: mangaDetail);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AlertBanner.show(
          context,
          'Failed to load details: $e',
          type: AlertBannerType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Recommendations'),
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        elevation: 0,
      ),
      body: _isLoadingHistory
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: isDark
                      ? AppColors.slate700.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select from your history to guide the AI:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: _history.isEmpty
                            ? const Center(
                                child: Text('No reading history found.'),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _history.length,
                                itemBuilder: (context, index) {
                                  final item = _history[index];
                                  final isLiked = _likedIds.contains(
                                    item.mangaId,
                                  );
                                  final isDisliked = _dislikedIds.contains(
                                    item.mangaId,
                                  );

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isLiked) {
                                          _likedIds.remove(item.mangaId);
                                          _dislikedIds.add(item.mangaId);
                                        } else if (isDisliked) {
                                          _dislikedIds.remove(item.mangaId);
                                        } else {
                                          _likedIds.add(item.mangaId);
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.slate700
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isLiked
                                              ? Colors.green
                                              : isDisliked
                                              ? Colors.red
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            if (_historyDetailsMap[item
                                                    .mangaId] !=
                                                null)
                                              CachedNetworkImage(
                                                imageUrl: _apiService
                                                    .getLocalImageUrl(
                                                  _historyDetailsMap[item
                                                          .mangaId]!
                                                      .localImageUrl,
                                                  _historyDetailsMap[item
                                                          .mangaId]!
                                                      .imageUrl,
                                                ),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            else
                                              const Center(
                                                child: Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.black.withValues(
                                                      alpha: 0.1,
                                                    ),
                                                    Colors.black.withValues(
                                                      alpha: 0.8,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (isLiked || isDisliked)
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: Icon(
                                                  isLiked
                                                      ? Icons.thumb_up
                                                      : Icons.thumb_down,
                                                  color: isLiked
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 16,
                                                ),
                                              ),
                                            Positioned(
                                              bottom: 4,
                                              left: 4,
                                              right: 4,
                                              child: Text(
                                                _historyDetailsMap[item.mangaId]
                                                        ?.title ??
                                                    'Loading...',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _getRecommendations,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Generate Recommendations',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingResults
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _results.isEmpty
                      ? const Center(
                          child: Text('No recommendations generated yet.'),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return DiscoverCard(
                              title: item.title,
                              type: item.type,
                              latestChapter: item.latestChapter,
                              views: formatViewCount(item.totalView),
                              genres: item.genres ?? [],
                              status: item.status,
                              rating: item.rating,
                              imageUrl: _apiService.getLocalImageUrl(
                                item.localImageUrl,
                                item.imageUrl,
                              ),
                              onTap: () => _navigateToDetail(item),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

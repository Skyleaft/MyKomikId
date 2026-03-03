import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/progression.dart';
import '../../../data/models/reader_content.dart';
import '../../../data/services/manga_api_service.dart';
import '../../../data/services/progression_service.dart';

class ReaderScreen extends StatefulWidget {
  final ReaderContent content;

  const ReaderScreen({super.key, required this.content});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  final MangaApiService _apiService = getIt<MangaApiService>();
  final ProgressionService _progressionService = getIt<ProgressionService>();
  bool _showUI = true;
  bool _isLoading = false;
  final TransformationController _transformationController =
      TransformationController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  // Local state to allow chapter switching
  late List<String> _pageUrls;
  late String _chapterTitle;
  late double _currentChapterNumber;

  double _progress = 0.0;
  int _currentPage = 1;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _pageUrls = widget.content.pageUrls;
    _chapterTitle = widget.content.chapterTitle;
    _currentChapterNumber = widget.content.currentChapterNumber;
    _animationController = AnimationController(vsync: this);

    // Set initial scroll position based on saved progress
    if (widget.content.currentPage > 1 &&
        widget.content.currentPage <= _pageUrls.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final targetScroll =
              ((widget.content.currentPage - 1) / (_pageUrls.length - 1)) *
              maxScroll;
          _scrollController.jumpTo(targetScroll);

          // Update progress and page state to match the scroll position
          setState(() {
            _progress = (targetScroll / maxScroll).clamp(0.0, 1.0);
            _currentPage = widget.content.currentPage;
          });
        }
      });
    }

    _transformationController.addListener(_onTransformationChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    // Left empty for now, we'll track progress differently
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    if (maxScroll > 0) {
      final newProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      final newPage = ((newProgress * (_pageUrls.length - 1)).round() + 1);

      if ((newProgress - _progress).abs() > 0.001 || newPage != _currentPage) {
        setState(() {
          _progress = newProgress;
          _currentPage = newPage;
        });

        // Save progression
        _saveProgression();
      }
    }
  }

  Future<void> _changeChapter(bool next) async {
    final chapters = widget.content.allChapters;
    // Chapters are usually sorted DESC (latest first)
    final currentIndex = chapters.indexWhere(
      (c) => c.chapterNumber == _currentChapterNumber,
    );

    int targetIndex;
    if (next) {
      // If DESC, next is lower index (e.g. current is chapter 5 at index 10, next is chapter 6 at index 9)
      targetIndex = currentIndex - 1;
    } else {
      targetIndex = currentIndex + 1;
    }

    if (targetIndex < 0 || targetIndex >= chapters.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next ? 'This is the latest chapter' : 'This is the first chapter',
          ),
        ),
      );
      return;
    }

    final targetChapter = chapters[targetIndex];

    setState(() => _isLoading = true);

    try {
      final pages = await _apiService.getChapterPages(
        widget.content.mangaId,
        targetChapter.chapterNumber,
      );

      setState(() {
        _pageUrls = pages
            .map(
              (p) => _apiService.getLocalImageUrl(
                p['localImageUrl'] as String?,
                p['imageUrl'] as String?,
              ),
            )
            .toList();
        _chapterTitle = targetChapter.title;
        _currentChapterNumber = targetChapter.chapterNumber;
        _progress = 0.0;
        _currentPage = 1;
        _isLoading = false;
        // Reset scroll position
        _transformationController.value = Matrix4.identity();
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load chapter: $e')));
      }
    }
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale > 1.0) {
      // Zoom out with animation
      _animateTo(
        Matrix4.identity(),
        duration: const Duration(milliseconds: 250),
      );
    } else if (_doubleTapDetails != null) {
      // Zoom in with animation
      final position = _doubleTapDetails!.localPosition;
      const targetScale = 2.5;

      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);

      final targetMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(targetScale);

      _animateTo(targetMatrix, duration: const Duration(milliseconds: 250));
    }
  }

  void _animateTo(Matrix4 targetMatrix, {required Duration duration}) {
    // Cancel any ongoing animation
    _animationController.stop();
    _animationController.reset();

    // Set up the animation
    _animationController.duration = duration;

    final currentMatrix = _transformationController.value;
    final animation = Matrix4Tween(begin: currentMatrix, end: targetMatrix)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    animation.addListener(() {
      _transformationController.value = animation.value;
    });

    _animationController.forward();
  }

  void _onSliderChanged(double value) {
    setState(() {
      _progress = value;
    });
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final targetScroll = value * position.maxScrollExtent;
      _scrollController.jumpTo(targetScroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content Area
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleUI,
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 5.0,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : CustomScrollView(
                        controller: _scrollController,
                        physics:
                            const ClampingScrollPhysics(), // Ensures smooth scrolling behavior
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final url = _pageUrls[index];
                              return Image.network(
                                url,
                                fit: BoxFit.fitWidth,
                                width: screenWidth,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height:
                                        screenWidth *
                                        1.5, // Estimate height for smoother lazy load
                                    width: screenWidth,
                                    color: Colors.black,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }, childCount: _pageUrls.length),
                          ),
                          // Extra padding element so you can view the bottom
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 250),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // Top Header
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _showUI ? 0 : -150,
            left: 0,
            right: 0,
            child: _buildFloatingTopUI(),
          ),

          // Bottom Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _showUI ? 20 : -350,
            left: 20,
            right: 20,
            child: _buildFloatingBottomUI(),
          ),

          // Mini Progress Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showUI ? 0 : 1,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTopUI() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildGlassIconButton(
                    Icons.arrow_back,
                    () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.content.mangaTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _chapterTitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildGlassIconButton(Icons.settings_outlined, () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomUI() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 45, 45, 45).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Slider Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => _changeChapter(false),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white10,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: _progress,
                        onChanged: _onSliderChanged,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => _changeChapter(true),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              // Info Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PAGE $_currentPage OF ${_pageUrls.length}  •  ${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Future<void> _saveProgression() async {
    final isCompleted = _progress >= 0.99;

    final progression = MangaProgression(
      mangaId: widget.content.mangaId,
      currentChapter: _currentChapterNumber,
      currentPage: _currentPage,
      totalPages: _pageUrls.length,
      lastRead: DateTime.now(),
      isCompleted: isCompleted,
    );

    try {
      await _progressionService.saveProgression(progression);
    } catch (e) {
      // Show error message to help debug the issue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Log the error for debugging
      debugPrint('Progression save error: $e');
    }
  }
}

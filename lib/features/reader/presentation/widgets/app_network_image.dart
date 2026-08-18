import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';

class AppNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool gaplessPlayback;
  final Duration? timeout;
  final Map<String, String>? httpHeaders;
  final int? maxHeightDiskCache;
  final int? maxWidthDiskCache;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.fitWidth,
    this.width,
    this.placeholder,
    this.errorWidget,
    this.gaplessPlayback = true,
    this.timeout = const Duration(seconds: 15),
    this.httpHeaders,
    this.maxHeightDiskCache,
    this.maxWidthDiskCache,
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  double? _aspectRatio;

  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Timer? _timeoutTimer;
  bool _isErrorOrTimeout = false;
  int _retryCount = 0;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _retryCount = 0;
      _aspectRatio = null;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }
    super.dispose();
  }

  void _resolveImage() {
    _timeoutTimer?.cancel();
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }

    if (mounted) {
      setState(() {
        _isErrorOrTimeout = false;
        _isRetrying = false;
      });
    }

    if (widget.timeout != null) {
      _timeoutTimer = Timer(widget.timeout!, () {
        if (mounted && _aspectRatio == null) {
          setState(() {
            _isErrorOrTimeout = true;
            _isRetrying = false;
          });
        }
      });
    }

    final provider = CachedNetworkImageProvider(
      widget.imageUrl,
      headers: widget.httpHeaders,
      maxHeight: widget.maxHeightDiskCache,
      maxWidth: widget.maxWidthDiskCache,
    );

    _imageStream = provider.resolve(const ImageConfiguration());
    _imageStreamListener = ImageStreamListener(
      (info, _) {
        _timeoutTimer?.cancel();
        final ratio =
            info.image.width.toDouble() / info.image.height.toDouble();

        if (mounted) {
          setState(() {
            _aspectRatio = ratio;
            _isErrorOrTimeout = false;
            _isRetrying = false;
          });
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        _timeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _isErrorOrTimeout = true;
            _isRetrying = false;
          });
        }
      },
    );

    _imageStream?.addListener(_imageStreamListener!);
  }

  Future<void> _forceReload() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _retryCount++;
    });

    try {
      await CachedNetworkImageProvider(
        widget.imageUrl,
        headers: widget.httpHeaders,
      ).evict();
    } catch (_) {}

    if (mounted) {
      _resolveImage();
    }
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          height: (widget.width ?? 300) * 1.4,
          width: widget.width,
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white24,
            ),
          ),
        );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          widget.errorWidget!,
          _buildRetryButton(),
        ],
      );
    }

    return Container(
      height: (widget.width ?? 300) * 1.2,
      width: widget.width,
      color: const Color(0xFF141414),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_rounded,
            color: Colors.white30,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load image',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_retryCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Retried $_retryCount time(s)',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildRetryButton(),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isRetrying ? null : _forceReload,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isRetrying)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              const SizedBox(width: 6),
              Text(
                _isRetrying ? 'Retrying...' : 'Tap to Retry',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isErrorOrTimeout) {
      return _buildErrorWidget();
    }

    if (_aspectRatio == null) {
      return _buildPlaceholder();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      httpHeaders: widget.httpHeaders,
      fit: widget.fit,
      width: widget.width,
      maxHeightDiskCache: widget.maxHeightDiskCache,
      maxWidthDiskCache: widget.maxWidthDiskCache,
      placeholder: (context, url) => _buildPlaceholder(),
      errorBuilder: (context, url, error) => _buildErrorWidget(),
    );

    if (widget.width != null) {
      return AspectRatio(
        aspectRatio: _aspectRatio!,
        child: imageWidget,
      );
    }

    return FittedBox(
      fit: widget.fit,
      alignment: Alignment.center,
      child: SizedBox(
        width: 1000,
        height: 1000 / _aspectRatio!,
        child: imageWidget,
      ),
    );
  }
}

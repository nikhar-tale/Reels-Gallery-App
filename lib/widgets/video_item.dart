import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../models/video_model.dart';
import '../providers/video_provider.dart';

/// Individual video item widget with auto-play functionality
class VideoItem extends StatefulWidget {
  final VideoModel video;
  final bool isActive;
  final VoidCallback onLike;

  const VideoItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.onLike,
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose controller here - let the cache manage it
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle play/pause based on isActive status
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _playVideo();
      } else {
        _pauseVideo();
      }
    }

    // If video changed, reinitialize
    if (widget.video.id != oldWidget.video.id) {
      _initializeVideo();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Pause video when app goes to background
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pauseVideo();
      _isVisible = false;
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      _isVisible = true;
      _playVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isInitialized = false;
        _hasError = false;
        _errorMessage = '';
      });

      // Get controller from cache
      _controller = await VideoControllerCache.instance.getController(
        widget.video.id,
        widget.video.filePath,
      );

      if (mounted) {
        // Add listener for video events
        _controller!.addListener(_videoListener);
        
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        // Auto-play if this video is active and app is visible
        if (widget.isActive && _isVisible) {
          _playVideo();
        }
      }
    } catch (e) {
      print('Error initializing video ${widget.video.id}: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Unable to load video: ${e.toString()}';
          _isInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    // Handle video completion, errors, etc.
    if (_controller!.value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = _controller!.value.errorDescription ?? 'Unknown video error';
      });
    }
  }

  void _playVideo() {
    if (_controller != null && _isInitialized && !_hasError && _isVisible) {
      try {
        _controller!.play();
        _controller!.setLooping(true);
        print('Playing video: ${widget.video.fileName}');
      } catch (e) {
        print('Error playing video: $e');
      }
    }
  }

  void _pauseVideo() {
    if (_controller != null && _isInitialized) {
      try {
        _controller!.pause();
        print('Paused video: ${widget.video.fileName}');
      } catch (e) {
        print('Error pausing video: $e');
      }
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized && !_hasError) {
      if (_controller!.value.isPlaying) {
        _pauseVideo();
      } else {
        _playVideo();
      }
    }
  }

  void _handleLike() {
    // Add haptic feedback
    try {
      widget.onLike();
      // You could add a like animation here
      _showLikeAnimation();
    } catch (e) {
      print('Error handling like: $e');
    }
  }

  void _showLikeAnimation() {
    // Simple scale animation for like button feedback
    if (mounted) {
      // This could trigger a brief scale animation on the like button
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Video player
          Center(
            child: _buildVideoPlayer(),
          ),

          // Tap to play/pause (only when video is loaded)
          if (_isInitialized && !_hasError)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),

          // Play/Pause indicator overlay
          if (_isInitialized && !_hasError)
            _buildPlayPauseIndicator(),

          // UI Controls overlay
          _buildControlsOverlay(),

          // Video info overlay (bottom)
          _buildVideoInfoOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    // Calculate aspect ratio and fit
    final videoAspectRatio = _controller!.value.aspectRatio;
    final screenSize = MediaQuery.of(context).size;
    final screenAspectRatio = screenSize.width / screenSize.height;

    return SizedBox.expand(
      child: FittedBox(
        fit: videoAspectRatio > screenAspectRatio 
            ? BoxFit.fitHeight 
            : BoxFit.fitWidth,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading ${widget.video.fileName}...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white54,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.video.fileName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeVideo,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseIndicator() {
    if (_controller == null || !_isInitialized) return const SizedBox.shrink();
    
    return AnimatedOpacity(
      opacity: _controller!.value.isPlaying ? 0.0 : 0.8,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      right: 12,
      bottom: 80,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Like button with animation
            _buildActionButton(
              icon: widget.video.stats.isLiked 
                  ? Icons.favorite 
                  : Icons.favorite_border,
              label: _formatNumber(widget.video.stats.likes),
              onTap: _handleLike,
              color: widget.video.stats.isLiked ? Colors.red : Colors.white,
              isLiked: widget.video.stats.isLiked,
            ),
            
            const SizedBox(height: 24),
            
            // Views count (non-interactive)
            _buildActionButton(
              icon: Icons.visibility,
              label: _formatNumber(widget.video.stats.views),
              onTap: null,
              color: Colors.white70,
            ),
            
            const SizedBox(height: 24),
            
            // Share button (placeholder)
            _buildActionButton(
              icon: Icons.share,
              label: 'Share',
              onTap: () {
                // Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share functionality would be implemented here'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfoOverlay() {
    return Positioned(
      left: 16,
      right: 80,
      bottom: 100,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video filename
            Text(
              widget.video.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Date added
            Text(
              'Added ${_formatDate(widget.video.dateAdded)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
    bool isLiked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with background
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
                border: isLiked 
                    ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
                    : null,
              ),
              child: AnimatedScale(
                scale: isLiked ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Label with shadow
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_provider.dart';
import '../models/video_model.dart';
import 'video_item.dart';

/// Main video feed widget implementing vertical scrolling with auto-play
class VideoFeed extends ConsumerStatefulWidget {
  const VideoFeed({super.key});

  @override
  ConsumerState<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends ConsumerState<VideoFeed> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Preload first few videos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadInitialVideos();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _preloadInitialVideos() {
    final videos = ref.read(videoFeedProvider).videos;
    final cache = VideoControllerCache.instance;
    
    // Preload first 3 videos for smooth experience
    for (int i = 0; i < 3 && i < videos.length; i++) {
      final video = videos[i];
      cache.preloadVideo(video.id, video.filePath);
    }
  }

  void _onPageChanged(int page) {
    if (_currentPage != page) {
      print('Page changed from $_currentPage to $page');
      
      final videos = ref.read(videoFeedProvider).videos;
      if (page < videos.length) {
        // Update current index in provider
        ref.read(videoFeedProvider.notifier).updateCurrentIndex(page);
        
        // Increment view count for the new video
        ref.read(videoFeedProvider.notifier).incrementViews(videos[page].id);
        
        // Preload next videos
        _preloadNextVideos(page, videos);
      }
      
      _currentPage = page;
    }
  }

  void _preloadNextVideos(int currentPage, List<VideoModel> videos) {
    final cache = VideoControllerCache.instance;
    
    // Preload next 2 videos
    for (int i = 1; i <= 2; i++) {
      final nextIndex = currentPage + i;
      if (nextIndex < videos.length) {
        final video = videos[nextIndex];
        cache.preloadVideo(video.id, video.filePath);
      }
    }

    // Clean up controllers for videos that are far away (memory optimization)
    final keepRange = 3; // Keep 3 videos before and after current
    for (int i = 0; i < videos.length; i++) {
      if ((i < currentPage - keepRange) || (i > currentPage + keepRange)) {
        cache.removeController(videos[i].id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoFeedState = ref.watch(videoFeedProvider);
    final videos = videoFeedState.videos;

    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final isCurrentVideo = index == videoFeedState.currentIndex;
        
        return VideoItem(
          video: video,
          isActive: isCurrentVideo,
          onLike: () => ref.read(videoFeedProvider.notifier).toggleLike(video.id),
        );
      },
    );
  }
}
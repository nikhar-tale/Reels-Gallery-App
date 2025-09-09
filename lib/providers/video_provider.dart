import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../models/video_model.dart';
import '../services/storage_service.dart';

/// State class for managing video feed
class VideoFeedState {
  final List<VideoModel> videos;
  final int currentIndex;
  final bool isLoading;
  final String? error;

  const VideoFeedState({
    this.videos = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
  });

  VideoFeedState copyWith({
    List<VideoModel>? videos,
    int? currentIndex,
    bool? isLoading,
    String? error,
  }) {
    return VideoFeedState(
      videos: videos ?? this.videos,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Video feed provider - manages the list of videos and current playback state
class VideoFeedNotifier extends StateNotifier<VideoFeedState> {
  VideoFeedNotifier() : super(const VideoFeedState()) {
    loadVideos();
  }

  /// Load videos from storage and shuffle them
  Future<void> loadVideos() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final videos = StorageService.instance.getShuffledVideos();
      state = state.copyWith(
        videos: videos,
        isLoading: false,
        currentIndex: 0,
      );
      
      print('Loaded ${videos.length} videos');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load videos: $e',
      );
    }
  }

  /// Update current video index
  void updateCurrentIndex(int index) {
    if (index >= 0 && index < state.videos.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// Add a new video and reshuffle the feed
  Future<void> addVideo() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final newVideo = await StorageService.instance.addVideo();
      if (newVideo != null) {
        // Reshuffle all videos including the new one
        final shuffledVideos = StorageService.instance.getShuffledVideos();
        state = state.copyWith(
          videos: shuffledVideos,
          isLoading: false,
          currentIndex: 0, // Reset to first video after adding
        );
        print('Added new video and reshuffled feed');
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add video: $e',
      );
    }
  }

  /// Add multiple videos and reshuffle the feed
  Future<void> addVideos() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final newVideos = await StorageService.instance.addVideos();
      if (newVideos.isNotEmpty) {
        // Reshuffle all videos including the new ones
        final shuffledVideos = StorageService.instance.getShuffledVideos();
        state = state.copyWith(
          videos: shuffledVideos,
          isLoading: false,
          currentIndex: 0, // Reset to first video after adding
        );
        print('Added ${newVideos.length} new videos and reshuffled feed');
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add videos: $e',
      );
    }
  }

  /// Toggle like status for current video
  Future<void> toggleLike(String videoId) async {
    try {
      final videoIndex = state.videos.indexWhere((v) => v.id == videoId);
      if (videoIndex == -1) return;

      final video = state.videos[videoIndex];
      final newStats = video.stats.copyWith(
        isLiked: !video.stats.isLiked,
        likes: video.stats.isLiked 
            ? video.stats.likes - 1 
            : video.stats.likes + 1,
      );

      // Update local state immediately for instant UI feedback
      final updatedVideos = List<VideoModel>.from(state.videos);
      updatedVideos[videoIndex] = video.copyWith(stats: newStats);
      state = state.copyWith(videos: updatedVideos);

      // Persist to storage
      await StorageService.instance.updateVideoStats(videoId, newStats);
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  /// Increment view count for a video
  Future<void> incrementViews(String videoId) async {
    try {
      final videoIndex = state.videos.indexWhere((v) => v.id == videoId);
      if (videoIndex == -1) return;

      final video = state.videos[videoIndex];
      final newStats = video.stats.copyWith(
        views: video.stats.views + 1,
        lastViewed: DateTime.now(),
      );

      // Update local state
      final updatedVideos = List<VideoModel>.from(state.videos);
      updatedVideos[videoIndex] = video.copyWith(stats: newStats);
      state = state.copyWith(videos: updatedVideos);

      // Persist to storage
      await StorageService.instance.updateVideoStats(videoId, newStats);
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }
}

/// Provider for video feed state
final videoFeedProvider = StateNotifierProvider<VideoFeedNotifier, VideoFeedState>((ref) {
  return VideoFeedNotifier();
});

/// Video controller cache for managing video players efficiently
class VideoControllerCache {
  static final VideoControllerCache _instance = VideoControllerCache._internal();
  static VideoControllerCache get instance => _instance;
  VideoControllerCache._internal();

  final Map<String, VideoPlayerController> _controllers = {};

  /// Get or create a video controller
  Future<VideoPlayerController> getController(String videoId, String filePath) async {
    if (_controllers.containsKey(videoId)) {
      return _controllers[videoId]!;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Video file not found: $filePath');
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      
      _controllers[videoId] = controller;
      print('Initialized controller for video: $videoId');
      
      return controller;
    } catch (e) {
      print('Error creating video controller for $videoId: $e');
      rethrow;
    }
  }

  /// Remove and dispose a controller
  void removeController(String videoId) {
    final controller = _controllers.remove(videoId);
    if (controller != null) {
      controller.dispose();
      print('Disposed controller for video: $videoId');
    }
  }

  /// Dispose all controllers
  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    print('Disposed all video controllers');
  }

  /// Get controller if it exists
  VideoPlayerController? getExistingController(String videoId) {
    return _controllers[videoId];
  }

  /// Preload a video (initialize controller without playing)
  Future<void> preloadVideo(String videoId, String filePath) async {
    if (!_controllers.containsKey(videoId)) {
      try {
        await getController(videoId, filePath);
        print('Preloaded video: $videoId');
      } catch (e) {
        print('Error preloading video $videoId: $e');
      }
    }
  }
}
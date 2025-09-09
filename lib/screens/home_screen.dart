import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_provider.dart';
import '../widgets/video_feed.dart';
import '../widgets/add_video_button.dart';

/// Home screen containing the main video feed
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up video controllers when app is closed
    VideoControllerCache.instance.disposeAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Pause all videos when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseAllVideos();
    }
  }

  void _pauseAllVideos() {
    final controllers = VideoControllerCache.instance;
    // This would pause all active controllers - implementation depends on your video feed structure
  }

  @override
  Widget build(BuildContext context) {
    final videoFeedState = ref.watch(videoFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main video feed
            if (videoFeedState.isLoading && videoFeedState.videos.isEmpty)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (videoFeedState.videos.isEmpty)
              _buildEmptyState()
            else
              const VideoFeed(),

            // Add video button - positioned at bottom right
            const Positioned(
              bottom: 100,
              right: 20,
              child: AddVideoButton(),
            ),

            // Loading overlay when adding video
            if (videoFeedState.isLoading && videoFeedState.videos.isNotEmpty)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Adding video...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 24),
          const Text(
            'No videos yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add your first video to get started',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
              onPressed: () => ref.read(videoFeedProvider.notifier).addVideos(), // Changed method
              icon: const Icon(Icons.add),
              label: const Text('Add Videos'), // Updated text
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
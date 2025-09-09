import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_provider.dart';

/// Floating action button for adding new videos
class AddVideoButton extends ConsumerWidget {
  const AddVideoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoFeedState = ref.watch(videoFeedProvider);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: videoFeedState.isLoading 
            ? null 
            : () => _showAddVideoConfirmation(context, ref),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        child: const Icon(
          Icons.add,
          size: 28,
        ),
      ),
    );
  }

  // void _showAddVideoConfirmation(BuildContext context, WidgetRef ref) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.grey[900],
  //         title: const Text(
  //           'Add Video',
  //           style: TextStyle(color: Colors.white),
  //         ),
  //         content: const Text(
  //           'Select a video from your device to add to your feed. The feed will be reshuffled after adding.',
  //           style: TextStyle(color: Colors.white70),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text(
  //               'Cancel',
  //               style: TextStyle(color: Colors.white54),
  //             ),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               ref.read(videoFeedProvider.notifier).addVideo();
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.red,
  //               foregroundColor: Colors.white,
  //             ),
  //             child: const Text('Select Video'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showAddVideoConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Add Videos',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Select one or more videos from your device to add to your feed. The feed will be reshuffled after adding.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(videoFeedProvider.notifier).addVideos(); // Changed method name
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Select Videos'), // Updated text
            ),
          ],
        );
      },
    );
  }
}
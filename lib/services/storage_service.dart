import 'dart:io';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/video_model.dart';

/// Service for managing video storage and persistence
class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();

  static const String _videosBoxName = 'videos';
  Box<VideoModel>? _videosBox;

  /// Initialize the storage service
  Future<void> initialize() async {
    try {
      _videosBox = await Hive.openBox<VideoModel>(_videosBoxName);
      print('Storage service initialized with ${_videosBox!.length} videos');
    } catch (e) {
      print('Error initializing storage service: $e');
      rethrow;
    }
  }

  /// Get all videos from storage
  List<VideoModel> getAllVideos() {
    if (_videosBox == null) {
      throw Exception('Storage service not initialized');
    }
    return _videosBox!.values.toList();
  }

  /// Get videos in random order for feed pagination
  List<VideoModel> getShuffledVideos() {
    final videos = getAllVideos();
    final shuffled = List<VideoModel>.from(videos);
    shuffled.shuffle(Random());
    return shuffled;
  }

  /// Add a new video to storage
  Future<VideoModel?> addVideo() async {
    try {
      // Pick video file from device
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        // Copy file to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final videosDir = Directory('${appDir.path}/videos');
        if (!await videosDir.exists()) {
          await videosDir.create(recursive: true);
        }

        // Generate unique filename to avoid conflicts
        final uuid = const Uuid();
        final uniqueId = uuid.v4();
        final fileExtension = fileName.split('.').last;
        final uniqueFileName = '${uniqueId}.$fileExtension';
        final newPath = '${videosDir.path}/$uniqueFileName';
        
        await file.copy(newPath);

        // Create video model
        final video = VideoModel(
          id: uniqueId,
          filePath: newPath,
          fileName: fileName,
          dateAdded: DateTime.now(),
          stats: VideoStats(),
        );

        // Save to Hive
        await _videosBox!.put(uniqueId, video);
        
        print('Added video: $fileName to storage');
        return video;
      }
    } catch (e) {
      print('Error adding video: $e');
    }
    return null;
  }

  // Add multiple videos to storage
  Future<List<VideoModel>> addVideos() async {
    final addedVideos = <VideoModel>[];
    
    try {
      // Pick multiple video files from device
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true, // Enable multiple selection
      );

      if (result != null && result.files.isNotEmpty) {
        // Get app directory
        final appDir = await getApplicationDocumentsDirectory();
        final videosDir = Directory('${appDir.path}/videos');
        if (!await videosDir.exists()) {
          await videosDir.create(recursive: true);
        }

        // Process each selected video
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            final fileName = platformFile.name;
            
            // Generate unique filename
            final uuid = const Uuid();
            final uniqueId = uuid.v4();
            final fileExtension = fileName.split('.').last;
            final uniqueFileName = '${uniqueId}.$fileExtension';
            final newPath = '${videosDir.path}/$uniqueFileName';
            
            // Copy file to app directory
            await file.copy(newPath);

            // Create video model
            final video = VideoModel(
              id: uniqueId,
              filePath: newPath,
              fileName: fileName,
              dateAdded: DateTime.now(),
              stats: VideoStats(),
            );

            // Save to Hive
            await _videosBox!.put(uniqueId, video);
            addedVideos.add(video);
            
            print('Added video: $fileName to storage');
          }
        }
      }
    } catch (e) {
      print('Error adding videos: $e');
    }
    
    return addedVideos;
  }

  /// Update video statistics
  Future<void> updateVideoStats(String videoId, VideoStats newStats) async {
    try {
      final video = _videosBox!.get(videoId);
      if (video != null) {
        final updatedVideo = video.copyWith(stats: newStats);
        await _videosBox!.put(videoId, updatedVideo);
        print('Updated stats for video $videoId');
      }
    } catch (e) {
      print('Error updating video stats: $e');
    }
  }

  /// Delete a video from storage
  Future<void> deleteVideo(String videoId) async {
    try {
      final video = _videosBox!.get(videoId);
      if (video != null) {
        // Delete physical file
        final file = File(video.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        // Remove from Hive
        await _videosBox!.delete(videoId);
        print('Deleted video: ${video.fileName}');
      }
    } catch (e) {
      print('Error deleting video: $e');
    }
  }

  /// Get video by ID
  VideoModel? getVideo(String id) {
    return _videosBox!.get(id);
  }

  /// Clear all videos (for testing)
  Future<void> clearAllVideos() async {
    try {
      // Delete all physical files
      final videos = getAllVideos();
      for (final video in videos) {
        final file = File(video.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Clear Hive box
      await _videosBox!.clear();
      print('Cleared all videos');
    } catch (e) {
      print('Error clearing videos: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _videosBox?.close();
  }
}
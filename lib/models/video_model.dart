import 'package:hive/hive.dart';

part 'video_model.g.dart';

/// Video model representing a single video in the feed
@HiveType(typeId: 0)
class VideoModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String filePath;

  @HiveField(2)
  String fileName;

  @HiveField(3)
  DateTime dateAdded;

  @HiveField(4)
  VideoStats stats;

  VideoModel({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.dateAdded,
    required this.stats,
  });

  /// Create a copy of this video with updated stats
  VideoModel copyWith({
    String? id,
    String? filePath,
    String? fileName,
    DateTime? dateAdded,
    VideoStats? stats,
  }) {
    return VideoModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      dateAdded: dateAdded ?? this.dateAdded,
      stats: stats ?? this.stats,
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, fileName: $fileName, stats: $stats)';
  }
}

/// Statistics for each video (likes, views, saved status)
@HiveType(typeId: 1)
class VideoStats extends HiveObject {
  @HiveField(0)
  int likes;

  @HiveField(1)
  int views;

  @HiveField(2)
  bool isLiked;

  @HiveField(3)
  bool isSaved;

  @HiveField(4)
  DateTime lastViewed;

  VideoStats({
    this.likes = 0,
    this.views = 0,
    this.isLiked = false,
    this.isSaved = false,
    DateTime? lastViewed,
  }) : lastViewed = lastViewed ?? DateTime.now();

  /// Create a copy of stats with updated values
  VideoStats copyWith({
    int? likes,
    int? views,
    bool? isLiked,
    bool? isSaved,
    DateTime? lastViewed,
  }) {
    return VideoStats(
      likes: likes ?? this.likes,
      views: views ?? this.views,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      lastViewed: lastViewed ?? this.lastViewed,
    );
  }

  @override
  String toString() {
    return 'VideoStats(likes: $likes, views: $views, isLiked: $isLiked)';
  }
}
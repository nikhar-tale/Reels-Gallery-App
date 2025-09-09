// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoModelAdapter extends TypeAdapter<VideoModel> {
  @override
  final int typeId = 0;

  @override
  VideoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoModel(
      id: fields[0] as String,
      filePath: fields[1] as String,
      fileName: fields[2] as String,
      dateAdded: fields[3] as DateTime,
      stats: fields[4] as VideoStats,
    );
  }

  @override
  void write(BinaryWriter writer, VideoModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.dateAdded)
      ..writeByte(4)
      ..write(obj.stats);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VideoStatsAdapter extends TypeAdapter<VideoStats> {
  @override
  final int typeId = 1;

  @override
  VideoStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoStats(
      likes: fields[0] as int,
      views: fields[1] as int,
      isLiked: fields[2] as bool,
      isSaved: fields[3] as bool,
      lastViewed: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VideoStats obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.likes)
      ..writeByte(1)
      ..write(obj.views)
      ..writeByte(2)
      ..write(obj.isLiked)
      ..writeByte(3)
      ..write(obj.isSaved)
      ..writeByte(4)
      ..write(obj.lastViewed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
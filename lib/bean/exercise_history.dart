import 'package:json_annotation/json_annotation.dart';

part 'exercise_history.g.dart';

@JsonSerializable()
class ExerciseHistory {
  final String id;
  final String startStation;
  final String endStation;
  final String startStationEn;
  final String endStationEn;
  final List<ExerciseRecord> exercises;
  final int totalCalories;
  final int totalDuration; // 總運動時間（秒）
  final DateTime timestamp;
  final String? bodyPartName;

  ExerciseHistory({
    required this.id,
    required this.startStation,
    required this.endStation,
    required this.startStationEn,
    required this.endStationEn,
    required this.exercises,
    required this.totalCalories,
    required this.totalDuration,
    required this.timestamp,
    this.bodyPartName,
  });

  factory ExerciseHistory.fromJson(Map<String, dynamic> json) =>
      _$ExerciseHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseHistoryToJson(this);

  String get routeDisplay => '$startStation → $endStation';
  String get dateDisplay {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays == 0) {
      return '今天 ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天 ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${timestamp.year}/${timestamp.month}/${timestamp.day}';
    }
  }
}

@JsonSerializable()
class ExerciseRecord {
  final String exerciseName;
  final int duration; // 秒
  final int calories;
  final String? stationSegment; // 例如「公館 → 台電大樓」

  ExerciseRecord({
    required this.exerciseName,
    required this.duration,
    required this.calories,
    this.stationSegment,
  });

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) =>
      _$ExerciseRecordFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseRecordToJson(this);

  String get durationDisplay {
    if (duration < 60) {
      return '${duration}秒';
    }
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    if (seconds == 0) {
      return '${minutes}分鐘';
    }
    return '${minutes}分${seconds}秒';
  }
}

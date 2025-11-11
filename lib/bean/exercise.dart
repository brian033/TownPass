import 'package:json_annotation/json_annotation.dart';

part 'exercise.g.dart';

@JsonSerializable()
class ExerciseList {
  final String version;
  final List<Exercise> exercises;

  ExerciseList({
    required this.version,
    required this.exercises,
  });

  factory ExerciseList.fromJson(Map<String, dynamic> json) =>
      _$ExerciseListFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseListToJson(this);
}

@JsonSerializable()
class Exercise {
  final String id;
  final String name;
  final String nameEn;
  final String bodyPartId;
  final String difficulty;
  final int duration;
  final int calories;
  final String description;
  final List<String> instructions;
  final String tips;
  final String imageUrl;
  final String videoUrl;
  final String safetyNotes;

  Exercise({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.bodyPartId,
    required this.difficulty,
    required this.duration,
    required this.calories,
    required this.description,
    required this.instructions,
    required this.tips,
    required this.imageUrl,
    required this.videoUrl,
    required this.safetyNotes,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseToJson(this);

  String get durationText => '${duration}秒';
  String get caloriesText => '${calories}大卡';
  String get difficultyText {
    switch (difficulty) {
      case 'easy':
        return '簡單';
      case 'medium':
        return '中等';
      case 'hard':
        return '困難';
      default:
        return difficulty;
    }
  }
}

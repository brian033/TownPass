import 'package:json_annotation/json_annotation.dart';

part 'body_part.g.dart';

@JsonSerializable()
class BodyPartList {
  final String version;
  final List<BodyPart> bodyParts;

  BodyPartList({
    required this.version,
    required this.bodyParts,
  });

  factory BodyPartList.fromJson(Map<String, dynamic> json) =>
      _$BodyPartListFromJson(json);

  Map<String, dynamic> toJson() => _$BodyPartListToJson(this);
}

@JsonSerializable()
class BodyPart {
  final String id;
  final String name;
  final String nameEn;
  final String description;
  final String icon;
  final List<String> targetMuscles;
  final String color;

  BodyPart({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.icon,
    required this.targetMuscles,
    required this.color,
  });

  factory BodyPart.fromJson(Map<String, dynamic> json) =>
      _$BodyPartFromJson(json);

  Map<String, dynamic> toJson() => _$BodyPartToJson(this);

  String get displayName => name;
  String get fullDescription => '$name - $description';
}

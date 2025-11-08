import 'package:town_pass/bean/mrt_station.dart';

/// Recommended exercise data model for MRT commute
class RecommendedExercise {
  RecommendedExercise({
    required this.name,
    required this.calPerSec,
    required this.doInCrowded,
    required this.parts,
    required this.media,
    required this.description,
  });

  final String name;
  final double calPerSec;
  final bool doInCrowded;
  final List<String> parts;
  final String media;
  final String description;

  factory RecommendedExercise.fromJson(Map<String, dynamic> json) {
    return RecommendedExercise(
      name: json['name']?.toString() ?? '',
      calPerSec: (json['calPerSec'] as num?)?.toDouble() ?? 0.0,
      doInCrowded: json['doInCrowded'] as bool? ?? false,
      parts: (json['parts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      media: json['media']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calPerSec': calPerSec,
      'doInCrowded': doInCrowded,
      'parts': parts,
      'media': media,
      'description': description,
    };
  }
}

/// Raw travel time segment between two adjacent MRT stations.
class MrtTravelSegment {
  MrtTravelSegment({
    required this.line,
    required this.stationAName,
    required this.stationBName,
    required this.travelSeconds,
    required this.stopSeconds,
  });

  final String line;
  final String stationAName;
  final String stationBName;
  final int travelSeconds;
  final int stopSeconds;

  int get totalSeconds => travelSeconds + stopSeconds;

  factory MrtTravelSegment.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value) {
      if (value == null) {
        return 0;
      }
      if (value is int) {
        return value;
      }
      return int.tryParse(value.toString()) ?? 0;
    }

    return MrtTravelSegment(
      line: json['line']?.toString() ?? '',
      stationAName: json['stationA']?.toString() ?? '',
      stationBName: json['stationB']?.toString() ?? '',
      travelSeconds: _parseInt(json['travelSeconds']),
      stopSeconds: _parseInt(json['stopSeconds']),
    );
  }
}

class MrtRouteLeg {
  MrtRouteLeg({
    required this.fromStation,
    required this.toStation,
    required this.lineName,
    required this.travelSeconds,
    required this.stopSeconds,
    required this.cumulativeSeconds,
  });

  final MrtStation fromStation;
  final MrtStation toStation;
  final String lineName;
  final int travelSeconds;
  final int stopSeconds;
  final int cumulativeSeconds;

  int get segmentSeconds => travelSeconds + stopSeconds;
}

class MrtRouteResult {
  MrtRouteResult({
    required this.startStation,
    required this.endStation,
    required this.legs,
    this.exercises = const [],
  });

  final MrtStation startStation;
  final MrtStation endStation;
  final List<MrtRouteLeg> legs;
  final List<RecommendedExercise> exercises;

  int get totalSeconds =>
      legs.fold(0, (previousValue, leg) => previousValue + leg.segmentSeconds);
}

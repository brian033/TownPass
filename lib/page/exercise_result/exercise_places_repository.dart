import 'dart:convert';

import 'package:flutter/services.dart';

class ExercisePlace {
  ExercisePlace({
    required this.name,
    required this.imageUrl,
    required this.locationUrl,
    required this.nearbyStations,
  });

  final String name;
  final String imageUrl;
  final String locationUrl;
  final List<String> nearbyStations;

  factory ExercisePlace.fromJson(Map<String, dynamic> json) {
    final nearby = json['nearbyMrtStations'];
    return ExercisePlace(
      name: json['place'] as String,
      imageUrl: json['image'] as String,
      locationUrl: json['url'] as String,
      nearbyStations: nearby is List
          ? nearby.map((dynamic item) => item.toString()).toList()
          : const <String>[],
    );
  }
}

class ExercisePlacesRepository {
  ExercisePlacesRepository._();

  static const String _mockDataPath = 'assets/mock_data/places.json';
  static List<ExercisePlace>? _cache;

  static Future<List<ExercisePlace>> _loadPlaces() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }

    final jsonString = await rootBundle.loadString(_mockDataPath);
    final List<dynamic> rawList = json.decode(jsonString) as List<dynamic>;
    final places = rawList
        .map((dynamic item) =>
            ExercisePlace.fromJson(item as Map<String, dynamic>))
        .toList();
    _cache = places;
    return places;
  }

  static Future<List<ExercisePlace>> findByStation(String stationName) async {
    final target = _normalize(stationName);
    if (target.isEmpty) {
      return const [];
    }

    final places = await _loadPlaces();
    return places
        .where((place) =>
            place.nearbyStations.any((station) => _normalize(station) == target))
        .toList(growable: false);
  }

  static String _normalize(String value) {
    return value.replaceAll('捷運', '').trim();
  }
}


import 'package:json_annotation/json_annotation.dart';

part 'mrt_station.g.dart';

@JsonSerializable()
class MrtStationList {
  final String version;
  final String lastUpdate;
  final List<MrtStation> stations;

  MrtStationList({
    required this.version,
    required this.lastUpdate,
    required this.stations,
  });

  factory MrtStationList.fromJson(Map<String, dynamic> json) =>
      _$MrtStationListFromJson(json);

  Map<String, dynamic> toJson() => _$MrtStationListToJson(this);
}

@JsonSerializable()
class MrtStation {
  final String id;
  final String stationCode;
  final String name;
  final String nameEn;
  final List<String> lines;
  final List<String> lineColors;
  final Location location;
  final String district;
  final String city;

  MrtStation({
    required this.id,
    required this.stationCode,
    required this.name,
    required this.nameEn,
    required this.lines,
    required this.lineColors,
    required this.location,
    required this.district,
    required this.city,
  });

  factory MrtStation.fromJson(Map<String, dynamic> json) =>
      _$MrtStationFromJson(json);

  Map<String, dynamic> toJson() => _$MrtStationToJson(this);

  String get displayName => name;
  String get fullName => '$name ($nameEn)';
}

@JsonSerializable()
class Location {
  final double lat;
  final double lng;

  Location({
    required this.lat,
    required this.lng,
  });

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}

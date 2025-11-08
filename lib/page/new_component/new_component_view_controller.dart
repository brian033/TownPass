import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:town_pass/bean/mrt_station.dart';
import 'package:town_pass/bean/body_part.dart';
import 'package:town_pass/bean/exercise.dart';
import 'package:town_pass/bean/mrt_connection.dart';
import 'package:town_pass/page/exercise_recommendation/exercise_recommendation_view.dart';
import 'package:town_pass/service/geo_locator_service.dart';

class NewComponentViewController extends GetxController {
  // 資料列表
  final RxList<MrtStation> mrtStations = <MrtStation>[].obs;
  final RxList<BodyPart> bodyParts = <BodyPart>[].obs;
  final RxList<Exercise> exercises = <Exercise>[].obs;
  final List<RecommendedExercise> _exercisesForRecommendation = [];

  // 使用者選擇
  final Rx<MrtStation?> selectedStartStation = Rx<MrtStation?>(null);
  final Rx<MrtStation?> selectedEndStation = Rx<MrtStation?>(null);
  final Rx<BodyPart?> selectedBodyPart = Rx<BodyPart?>(null);

  // 載入狀態
  final RxBool isLoading = true.obs;

  // GPS 位置
  Position? _userPosition;
  final GeoLocatorService _geoLocatorService = Get.find<GeoLocatorService>();

  // 取得按距離排序的起點站列表
  List<MrtStation> get sortedStartStations {
    if (_userPosition == null) {
      return mrtStations.toList();
    }

    final stationsWithDistance = mrtStations.map((station) {
      final distance = _calculateDistance(
        _userPosition!.latitude,
        _userPosition!.longitude,
        station.location.lat,
        station.location.lng,
      );
      return _StationWithDistance(station, distance);
    }).toList();

    // 按距離排序
    stationsWithDistance.sort((a, b) => a.distance.compareTo(b.distance));

    return stationsWithDistance.map((e) => e.station).toList();
  }

  // 取得按線路分組的終點站列表（排除起點）
  Map<String, List<MrtStation>> get groupedEndStations {
    final Map<String, List<MrtStation>> grouped = {};

    for (final station in mrtStations) {
      // 排除已選的起點站
      if (selectedStartStation.value != null &&
          station.id == selectedStartStation.value!.id) {
        continue;
      }

      // 對於多線站點，在每條線都加入一次
      for (int i = 0; i < station.lines.length; i++) {
        final line = station.lines[i];
        if (!grouped.containsKey(line)) {
          grouped[line] = [];
        }
        grouped[line]!.add(station);
      }
    }

    return grouped;
  }

  // 路線資料
  final Map<String, List<_GraphEdge>> _graph = <String, List<_GraphEdge>>{};
  final Map<String, MrtStation> _stationById = <String, MrtStation>{};
  final Map<String, MrtStation> _stationByName = <String, MrtStation>{};

  // 預估時間（分鐘）
  int get estimatedMinutes {
    final route = _getOrComputeRoute();
    if (route == null) {
      return 0;
    }

    final minutes = (route.totalSeconds / 60).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  String get estimatedTimeText {
    if (selectedStartStation.value == null ||
        selectedEndStation.value == null) {
      return '請選擇起站和終站';
    }
    return '預估時間：$estimatedMinutes 分鐘';
  }

  bool get canStart {
    return selectedStartStation.value != null &&
        selectedEndStation.value != null &&
        selectedBodyPart.value != null &&
        selectedStartStation.value!.id != selectedEndStation.value!.id;
  }

  // 計算兩點間的距離（Haversine formula）單位：公里
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // 如果座標為 0，返回一個很大的距離
    if (lat2 == 0.0 && lon2 == 0.0) {
      return double.infinity;
    }

    const double earthRadius = 6371; // 地球半徑（公里）
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
        math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  // 載入所有資料
  Future<void> loadData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        loadMrtStations(),
        loadBodyParts(),
        loadExercises(),
        loadExercisesForRecommendation(),
        _loadUserPosition(),
      ]);

      await loadMrtConnections();

      isLoading.value = false;
    } catch (e) {
      print('Error loading data: $e');
      isLoading.value = false;
    }
  }

  // 載入使用者位置
  Future<void> _loadUserPosition() async {
    try {
      _userPosition = await _geoLocatorService.position();
      print('User position loaded: ${_userPosition?.latitude}, ${_userPosition?.longitude}');
    } catch (e) {
      print('Could not get user position: $e');
      // 不影響其他功能，繼續執行
    }
  }

  // 載入捷運站資料
  Future<void> loadMrtStations() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/mock_data/mrt_stations.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final stationList = MrtStationList.fromJson(jsonData);
      mrtStations.value = stationList.stations;
      _buildStationLookup();
    } catch (e) {
      print('Error loading MRT stations: $e');
    }
  }

  // 載入身體部位資料
  Future<void> loadBodyParts() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/mock_data/body_parts.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final bodyPartList = BodyPartList.fromJson(jsonData);
      bodyParts.value = bodyPartList.bodyParts;
    } catch (e) {
      print('Error loading body parts: $e');
    }
  }

  // 載入運動資料
  Future<void> loadExercises() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/mock_data/exercises.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final exerciseList = ExerciseList.fromJson(jsonData);
      exercises.value = exerciseList.exercises;
    } catch (e) {
      print('Error loading exercises: $e');
    }
  }

  // 載入運動推薦資料
  Future<void> loadExercisesForRecommendation() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/mock_data/exercise.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);
      _exercisesForRecommendation.clear();
      _exercisesForRecommendation.addAll(
        jsonData.map((e) => RecommendedExercise.fromJson(e as Map<String, dynamic>)),
      );
    } catch (e) {
      print('Error loading exercises for recommendation: $e');
    }
  }

  // 開始規劃運動
  void startPlanning() {
    if (!canStart) {
      Get.snackbar(
        '提醒',
        '請選擇起站、終站和要運動的部位',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final route = _getOrComputeRoute();
    if (route == null) {
      Get.snackbar(
        '提醒',
        '無法為此路線找到捷運規劃，請重新選擇',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 導向運動推薦頁面，傳遞參數
    Get.to(
      () => ExerciseRecommendationView(),
      arguments: {
        'startStation': selectedStartStation.value,
        'endStation': selectedEndStation.value,
        'bodyPart': selectedBodyPart.value,
        'estimatedMinutes': estimatedMinutes,
        'routeResult': route,
      },
    );
  }

  // 重置選擇
  void resetSelection() {
    selectedStartStation.value = null;
    selectedEndStation.value = null;
    selectedBodyPart.value = null;
  }

  Future<void> loadMrtConnections() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/mock_data/mrt_travel_times.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      final segments = jsonData
          .map((segment) =>
              MrtTravelSegment.fromJson(segment as Map<String, dynamic>))
          .where((segment) =>
              segment.stationAName.isNotEmpty &&
              segment.stationBName.isNotEmpty &&
              segment.totalSeconds > 0)
          .toList();

      _graph.clear();

      for (final segment in segments) {
        final fromStation = _findStationByName(segment.stationAName);
        final toStation = _findStationByName(segment.stationBName);

        if (fromStation == null || toStation == null) {
          continue;
        }

        _addEdge(
          fromStation.id,
          toStation.id,
          segment,
        );
        _addEdge(
          toStation.id,
          fromStation.id,
          segment,
        );
      }
    } catch (e) {
      print('Error loading MRT connections: $e');
    }
  }

  void _buildStationLookup() {
    _stationById
      ..clear()
      ..addEntries(mrtStations.map((station) => MapEntry(station.id, station)));

    _stationByName.clear();
    for (final station in mrtStations) {
      final normalized = _normalizeStationName(station.name);
      _stationByName[normalized] = station;
      _stationByName[_normalizeStationName('${station.name}站')] = station;
      _stationByName[_normalizeStationName('捷運${station.name}')] = station;
      _stationByName[_normalizeStationName('捷運${station.name}站')] = station;
    }
  }

  String _normalizeStationName(String name) {
    var normalized = name.trim();
    if (normalized.startsWith('台北捷運')) {
      normalized = normalized.replaceFirst('台北捷運', '');
    }
    if (normalized.startsWith('捷運')) {
      normalized = normalized.substring(2);
    }
    if (normalized.endsWith('站')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    normalized = normalized
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('　', '')
        .trim();
    return normalized;
  }

  MrtStation? _findStationByName(String name) {
    if (name.isEmpty) {
      return null;
    }
    final normalized = _normalizeStationName(name);
    return _stationByName[normalized];
  }

  void _addEdge(
    String fromStationId,
    String toStationId,
    MrtTravelSegment segment,
  ) {
    final edges = _graph.putIfAbsent(fromStationId, () => <_GraphEdge>[]);
    edges.add(
      _GraphEdge(
        toStationId: toStationId,
        line: segment.line,
        travelSeconds: segment.travelSeconds,
        stopSeconds: segment.stopSeconds,
      ),
    );
  }

  MrtRouteResult? _getOrComputeRoute() {
    final start = selectedStartStation.value;
    final end = selectedEndStation.value;
    if (start == null || end == null || start.id == end.id) {
      return null;
    }

    // 注意：不使用快取，因為需要根據當前選擇的 bodyPart 重新篩選運動
    // 如果未來需要優化效能，應該將 bodyPart 也加入快取 key
    final route = _computeRoute(start.id, end.id);
    return route;
  }

  MrtRouteResult? _computeRoute(String startId, String endId) {
    if (!_graph.containsKey(startId) || !_graph.containsKey(endId)) {
      return null;
    }

    final distances = <String, int>{startId: 0};
    final previous = <String, _PreviousNode>{};
    final visited = <String>{};
    final queue = PriorityQueue<_QueueNode>(
      (a, b) => a.cost.compareTo(b.cost),
    )..add(_QueueNode(startId, 0));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (!visited.add(current.stationId)) {
        continue;
      }
      if (current.stationId == endId) {
        break;
      }
      final neighbors = _graph[current.stationId];
      if (neighbors == null) {
        continue;
      }
      for (final edge in neighbors) {
        final nextCost = current.cost + edge.totalSeconds;
        final existing = distances[edge.toStationId];
        if (existing == null || nextCost < existing) {
          distances[edge.toStationId] = nextCost;
          previous[edge.toStationId] = _PreviousNode(
            fromStationId: current.stationId,
            toStationId: edge.toStationId,
            edge: edge,
          );
          queue.add(_QueueNode(edge.toStationId, nextCost));
        }
      }
    }

    if (!distances.containsKey(endId)) {
      return null;
    }

    final legs = <MrtRouteLeg>[];
    var currentId = endId;
    final startStation = _stationById[startId];
    final endStation = _stationById[endId];
    if (startStation == null || endStation == null) {
      return null;
    }

    final path = <_PreviousNode>[];
    while (currentId != startId) {
      final prev = previous[currentId];
      if (prev == null) {
        return null;
      }
      path.add(prev);
      currentId = prev.fromStationId;
    }

    var cumulativeSeconds = 0;
    for (final node in path.reversed) {
      final fromStation = _stationById[node.fromStationId];
      final toStation = _stationById[node.toStationId];
      if (fromStation == null || toStation == null) {
        continue;
      }
      cumulativeSeconds += node.edge.totalSeconds;
      legs.add(
        MrtRouteLeg(
          fromStation: fromStation,
          toStation: toStation,
          lineName: node.edge.line,
          travelSeconds: node.edge.travelSeconds,
          stopSeconds: node.edge.stopSeconds,
          cumulativeSeconds: cumulativeSeconds,
        ),
      );
    }

    // 篩選符合選擇部位的運動
    final filteredExercises = _filterExercisesByBodyPart();

    return MrtRouteResult(
      startStation: startStation,
      endStation: endStation,
      legs: legs,
      exercises: filteredExercises,
    );
  }

  /// 根據選擇的身體部位篩選運動
  List<RecommendedExercise> _filterExercisesByBodyPart() {
    final selectedPart = selectedBodyPart.value;
    if (selectedPart == null) {
      print('DEBUG: selectedPart is null');
      return [];
    }

    print('DEBUG: selectedPart.id = ${selectedPart.id}');
    print('DEBUG: _exercisesForRecommendation.length = ${_exercisesForRecommendation.length}');

    for (var i = 0; i < _exercisesForRecommendation.length; i++) {
      final ex = _exercisesForRecommendation[i];
      print('DEBUG: Exercise $i: name=${ex.name}, parts=${ex.parts}');
    }

    // 篩選 parts 陣列中包含選擇部位的運動
    final filtered = _exercisesForRecommendation
        .where((exercise) => exercise.parts.contains(selectedPart.id))
        .toList();

    print('DEBUG: Filtered exercises count = ${filtered.length}');

    return filtered;
  }
}

class _GraphEdge {
  _GraphEdge({
    required this.toStationId,
    required this.line,
    required this.travelSeconds,
    required this.stopSeconds,
  });

  final String toStationId;
  final String line;
  final int travelSeconds;
  final int stopSeconds;

  int get totalSeconds => travelSeconds + stopSeconds;
}

class _QueueNode {
  _QueueNode(this.stationId, this.cost);

  final String stationId;
  final int cost;
}

class _PreviousNode {
  _PreviousNode({
    required this.fromStationId,
    required this.toStationId,
    required this.edge,
  });

  final String fromStationId;
  final String toStationId;
  final _GraphEdge edge;
}

class _StationWithDistance {
  _StationWithDistance(this.station, this.distance);

  final MrtStation station;
  final double distance;
}

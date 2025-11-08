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
import 'package:town_pass/service/train_crowding_service.dart';
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
  final RxList<BodyPart> selectedBodyParts = <BodyPart>[].obs;

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

  // 取得所有終點站列表（去重，排除起點）
  List<MrtStation> get allEndStations {
    final allStations = <MrtStation>[];
    final seen = <String>{};

    for (final station in mrtStations) {
      // 排除已選的起點站
      if (selectedStartStation.value != null &&
          station.id == selectedStartStation.value!.id) {
        continue;
      }

      if (seen.add(station.id)) {
        allStations.add(station);
      }
    }

    return allStations;
  }

  // 路線資料
  final Map<String, List<_GraphEdge>> _graph = <String, List<_GraphEdge>>{};
  final Map<String, MrtStation> _stationById = <String, MrtStation>{};
  final Map<String, MrtStation> _stationByName = <String, MrtStation>{};

  // 換線懲罰時間（秒），預設為 4 分鐘
  static const int _transferPenaltySeconds = 240;

  // 擁擠度服務
  final TrainCrowdingService _crowdingService = TrainCrowdingService();

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
        selectedBodyParts.isNotEmpty &&
        selectedStartStation.value!.id != selectedEndStation.value!.id;
  }

  // 計算兩點間的距離（Haversine formula）單位：公里
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
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
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

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
        _crowdingService.initialize(), // 初始化擁擠度服務
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
      print(
          'User position loaded: ${_userPosition?.latitude}, ${_userPosition?.longitude}');
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
        jsonData.map(
            (e) => RecommendedExercise.fromJson(e as Map<String, dynamic>)),
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
        'bodyParts': selectedBodyParts.toList(),
        'estimatedMinutes': estimatedMinutes,
        'routeResult': route,
      },
    );
  }

  // 重置選擇
  void resetSelection() {
    selectedStartStation.value = null;
    selectedEndStation.value = null;
    selectedBodyParts.clear();
  }

  // 切換身體部位的選擇狀態
  void toggleBodyPart(BodyPart bodyPart) {
    final index =
        selectedBodyParts.indexWhere((part) => part.id == bodyPart.id);
    if (index >= 0) {
      selectedBodyParts.removeAt(index);
    } else {
      selectedBodyParts.add(bodyPart);
    }
  }

  // 檢查身體部位是否已選擇
  bool isBodyPartSelected(BodyPart bodyPart) {
    return selectedBodyParts.any((part) => part.id == bodyPart.id);
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

    // 注意：不使用快取，因為需要根據當前選擇的 bodyParts 重新篩選運動
    // 如果未來需要優化效能，應該將 bodyParts 也加入快取 key
    final route = _computeRoute(start.id, end.id);
    return route;
  }

  MrtRouteResult? _computeRoute(String startId, String endId) {
    if (!_graph.containsKey(startId) || !_graph.containsKey(endId)) {
      return null;
    }

    // 使用複合鍵 (stationId, line) 來追蹤狀態，因為同一站可能通過不同線路到達
    // 鍵格式：'stationId|line' 或 'stationId|'（起始站，無線路）
    final distances = <String, int>{};
    final previous = <String, _PreviousNode>{};
    final visited = <String>{};
    final queue = PriorityQueue<_QueueNode>(
      (a, b) => a.cost.compareTo(b.cost),
    );

    // 起始站：使用空字串作為線路標識（起始站沒有到達線路）
    final startKey = '$startId|';
    distances[startKey] = 0;
    queue.add(_QueueNode(startId, 0, arrivingLine: null));

    String? bestEndKey;

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final currentKey = current.arrivingLine != null
          ? '${current.stationId}|${current.arrivingLine}'
          : '$current.stationId|';

      if (!visited.add(currentKey)) {
        continue;
      }

      if (current.stationId == endId) {
        // 找到終點站，記錄最佳路徑的鍵
        if (bestEndKey == null || current.cost < (distances[bestEndKey] ?? double.maxFinite.toInt())) {
          bestEndKey = currentKey;
        }
        // 繼續處理隊列，因為可能還有更短的路徑（通過其他線路到達）
      }

      final neighbors = _graph[current.stationId];
      if (neighbors == null) {
        continue;
      }

      for (final edge in neighbors) {
        // 檢查是否需要換線
        final needsTransfer = current.arrivingLine != null && 
                              current.arrivingLine != edge.line;
        final transferCost = needsTransfer ? _transferPenaltySeconds : 0;
        final nextCost = current.cost + edge.totalSeconds + transferCost;

        // 構建目標站的複合鍵
        final targetKey = '${edge.toStationId}|${edge.line}';
        final existingDistance = distances[targetKey];

        if (existingDistance == null || nextCost < existingDistance) {
          distances[targetKey] = nextCost;
          previous[targetKey] = _PreviousNode(
            fromStationId: current.stationId,
            toStationId: edge.toStationId,
            edge: edge,
            fromLine: current.arrivingLine,
          );
          queue.add(_QueueNode(edge.toStationId, nextCost, arrivingLine: edge.line));
        }
      }
    }

    // 找到到達終點站的最佳路徑（可能通過不同線路到達）
    if (bestEndKey == null) {
      // 如果沒有找到 bestEndKey，嘗試從所有可能的終點鍵中找最短的
      for (final key in distances.keys) {
        if (key.startsWith('$endId|')) {
          if (bestEndKey == null || 
              (distances[key] ?? double.maxFinite.toInt()) < 
              (distances[bestEndKey] ?? double.maxFinite.toInt())) {
            bestEndKey = key;
          }
        }
      }
    }

    if (bestEndKey == null || !distances.containsKey(bestEndKey)) {
      return null;
    }

    final legs = <MrtRouteLeg>[];
    var currentKey = bestEndKey;
    final startStation = _stationById[startId];
    final endStation = _stationById[endId];
    if (startStation == null || endStation == null) {
      return null;
    }

    final path = <_PreviousNode>[];

    // 從終點回溯到起點
    while (true) {
      final prev = previous[currentKey];
      if (prev == null) {
        break;
      }

      path.add(prev);

      // 如果到達起始站（fromLine 為 null 表示起始狀態），跳出循環
      if (prev.fromLine == null && prev.fromStationId == startId) {
        break;
      }

      // 構建上一個節點的鍵
      if (prev.fromLine != null) {
        currentKey = '${prev.fromStationId}|${prev.fromLine}';
      } else {
        currentKey = '${prev.fromStationId}|';
      }

      // 安全檢查：如果找不到上一個節點，跳出
      if (!previous.containsKey(currentKey)) {
        break;
      }
    }

    // 反向路徑並計算累計時間
    var cumulativeSeconds = 0;
    String? previousLine;

    for (final node in path.reversed) {
      final fromStation = _stationById[node.fromStationId];
      final toStation = _stationById[node.toStationId];
      if (fromStation == null || toStation == null) {
        continue;
      }

      // 如果從不同線路轉換，加上換線時間
      if (previousLine != null && previousLine != node.edge.line) {
        cumulativeSeconds += _transferPenaltySeconds;
      }

      cumulativeSeconds += node.edge.totalSeconds;
      previousLine = node.edge.line;

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
    var filteredExercises = _filterExercisesByBodyPart();

    print('=== Before crowding filter ===');
    print('Total exercises: ${filteredExercises.length}');
    print(
        'Exercises: ${filteredExercises.map((e) => '${e.name}(${e.doInCrowded})').join(", ")}');

    // 檢查第一段路徑的擁擠度
    if (legs.isNotEmpty) {
      final firstLeg = legs.first;
      final isCrowded = _crowdingService.checkIfCrowded(
        firstLeg.fromStation.name,
        firstLeg.toStation.name,
      );

      // 根據擁擠度進一步篩選運動
      filteredExercises = _crowdingService.filterExercisesByCrowding(
        filteredExercises,
        isCrowded,
      );

      print('=== After crowding filter ===');
      print(
          'Route from ${firstLeg.fromStation.name} to ${firstLeg.toStation.name}: '
          'isCrowded = $isCrowded, available exercises = ${filteredExercises.length}');
      print(
          'Filtered exercises: ${filteredExercises.map((e) => '${e.name}(${e.doInCrowded})').join(", ")}');
    }

    return MrtRouteResult(
      startStation: startStation,
      endStation: endStation,
      legs: legs,
      exercises: filteredExercises,
    );
  }

  /// 根據選擇的身體部位篩選運動
  List<RecommendedExercise> _filterExercisesByBodyPart() {
    if (selectedBodyParts.isEmpty) {
      print('DEBUG: selectedBodyParts is empty');
      return [];
    }

    // 取得所有選擇的部位 ID
    final selectedPartIds = selectedBodyParts.map((part) => part.id).toSet();
    print('DEBUG: selectedPartIds = $selectedPartIds');
    print(
        'DEBUG: _exercisesForRecommendation.length = ${_exercisesForRecommendation.length}');

    // 篩選 parts 陣列中包含任何選擇部位的運動
    final filtered = _exercisesForRecommendation
        .where((exercise) =>
            exercise.parts.any((part) => selectedPartIds.contains(part)))
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
  _QueueNode(this.stationId, this.cost, {this.arrivingLine});

  final String stationId;
  final int cost;
  final String? arrivingLine; // 到達此站時使用的線路（null 表示起始站）
}

class _PreviousNode {
  _PreviousNode({
    required this.fromStationId,
    required this.toStationId,
    required this.edge,
    this.fromLine,
  });

  final String fromStationId;
  final String toStationId;
  final _GraphEdge edge;
  final String? fromLine; // 從哪條線路到達 fromStationId
}

class _StationWithDistance {
  _StationWithDistance(this.station, this.distance);

  final MrtStation station;
  final double distance;
}

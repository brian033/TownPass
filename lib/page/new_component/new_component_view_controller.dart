import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/mrt_station.dart';
import 'package:town_pass/bean/body_part.dart';
import 'package:town_pass/bean/exercise.dart';
import 'package:town_pass/page/exercise_recommendation/exercise_recommendation_view.dart';
import 'dart:math';

class NewComponentViewController extends GetxController {
  // 資料列表
  final RxList<MrtStation> mrtStations = <MrtStation>[].obs;
  final RxList<BodyPart> bodyParts = <BodyPart>[].obs;
  final RxList<Exercise> exercises = <Exercise>[].obs;

  // 使用者選擇
  final Rx<MrtStation?> selectedStartStation = Rx<MrtStation?>(null);
  final Rx<MrtStation?> selectedEndStation = Rx<MrtStation?>(null);
  final Rx<BodyPart?> selectedBodyPart = Rx<BodyPart?>(null);

  // 載入狀態
  final RxBool isLoading = true.obs;

  // 預估時間（分鐘）
  int get estimatedMinutes {
    if (selectedStartStation.value == null ||
        selectedEndStation.value == null) {
      return 0;
    }

    // 計算兩站之間的距離（簡化版本）
    final start = selectedStartStation.value!.location;
    final end = selectedEndStation.value!.location;

    // 使用 Haversine 公式計算距離
    final distance = _calculateDistance(
      start.lat,
      start.lng,
      end.lat,
      end.lng,
    );

    // 假設捷運平均速度 40 km/h，加上停靠站時間
    // 每公里約 1.5 分鐘（包含停靠時間）
    final minutes = (distance * 1.5).round();

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
      ]);

      isLoading.value = false;
    } catch (e) {
      print('Error loading data: $e');
      isLoading.value = false;
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

  // 計算兩個 GPS 座標之間的距離（公里）
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // 地球半徑（公里）

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
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

    // 導向運動推薦頁面，傳遞參數
    Get.to(
      () => ExerciseRecommendationView(),
      arguments: {
        'startStation': selectedStartStation.value,
        'endStation': selectedEndStation.value,
        'bodyPart': selectedBodyPart.value,
        'estimatedMinutes': estimatedMinutes,
      },
    );
  }

  // 重置選擇
  void resetSelection() {
    selectedStartStation.value = null;
    selectedEndStation.value = null;
    selectedBodyPart.value = null;
  }
}

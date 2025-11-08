import 'dart:async';
import 'package:get/get.dart';
import 'package:town_pass/bean/body_part.dart';
import 'package:town_pass/bean/exercise_history.dart';
import 'package:town_pass/bean/mrt_connection.dart';
import 'package:town_pass/bean/mrt_station.dart';
import 'package:town_pass/service/exercise_history_service.dart';

class ExerciseRecommendationController extends GetxController {
  // 接收的參數
  late MrtStation startStation;
  late MrtStation endStation;
  late List<BodyPart> bodyParts;
  late int estimatedMinutes;
  MrtRouteResult? routeResult;

  final Rxn<ExerciseRecommendation> _exercise = Rxn<ExerciseRecommendation>();
  final RxBool isLoading = false.obs;
  
  ExerciseHistoryService? _historyService;

  // 路徑資料（將在之後提供）
  List<MrtStation> path = [];
  List<double> estimatedMinutesList = []; // 每段路程的時間（分鐘，支援小數）
  List<String> movements = []; // 每段路程的運動類型

  // 當前狀態
  final Rx<MrtStation?> currentLocation = Rx<MrtStation?>(null);
  final RxInt remainingTimeSeconds = 0.obs; // 剩餘時間（秒）
  final RxString currentMovement = ''.obs; // 當前運動類型

  // 計時器相關
  DateTime? startTime;
  Timer? _updateTimer;
  
  // 記錄上一次的位置，用於判斷位置是否改變
  MrtStation? _previousLocation;

  Rxn<ExerciseRecommendation> get exercise => _exercise;

  @override
  void onInit() {
    super.onInit();

    // 從路由參數獲取資料
    final args = Get.arguments as Map<String, dynamic>;
    startStation = args['startStation'] as MrtStation;
    endStation = args['endStation'] as MrtStation;
    // 支援舊版本的單一 bodyPart 參數（向後相容）
    if (args.containsKey('bodyParts')) {
      bodyParts = List<BodyPart>.from(args['bodyParts'] as List);
    } else if (args.containsKey('bodyPart')) {
      bodyParts = [args['bodyPart'] as BodyPart];
    } else {
      bodyParts = [];
    }
    estimatedMinutes = args['estimatedMinutes'] as int;
    routeResult = args['routeResult'] as MrtRouteResult?;
    
    // 取得服務
    try {
      _historyService = Get.find<ExerciseHistoryService>();
    } catch (e) {
      print('ExerciseHistoryService 未找到：$e');
    }

    // 從 routeResult 初始化路徑資料
    if (routeResult != null) {
      _initializePathFromRouteResult();
    }

    // TODO: 根據參數推薦適合的運動
    loadRecommendedExercises();
  }
  
  // 取得所有選中部位的名稱（用於顯示）
  String get bodyPartsDisplayName {
    if (bodyParts.isEmpty) {
      return '未選擇';
    }
    return bodyParts.map((part) => part.name).join('、');
  }

  @override
  void onClose() {
    _updateTimer?.cancel();
    super.onClose();
  }

  // 從 routeResult 初始化路徑資料
  void _initializePathFromRouteResult() {
    if (routeResult == null || routeResult!.legs.isEmpty) {
      return;
    }

    final pathList = <MrtStation>[];
    final timeList = <double>[];
    final movementList = <String>[];

    for (var leg in routeResult!.legs) {
      if (pathList.isEmpty) {
        pathList.add(leg.fromStation);
      }
      pathList.add(leg.toStation);
      
      // 將秒數轉換為分鐘
      final minutes = (leg.travelSeconds + leg.stopSeconds) / 60.0;
      timeList.add(minutes);
    }

    // 使用 routeResult 中的 movements，如果為空則使用預設值
    if (routeResult!.movements.isNotEmpty && 
        routeResult!.movements.length == routeResult!.legs.length) {
      movementList.addAll(routeResult!.movements);
    } else {
      // 如果沒有 movements 或長度不匹配，使用預設值
      movementList.addAll(List.filled(routeResult!.legs.length, '運動'));
    }

    setPathData(
      path: pathList,
      estimatedMinutesList: timeList,
      movements: movementList,
    );
  }

  // 設定路徑資料
  void setPathData({
    required List<MrtStation> path,
    required List<double> estimatedMinutesList,
    required List<String> movements,
  }) {
    this.path = path;
    this.estimatedMinutesList = estimatedMinutesList;
    this.movements = movements;
    
    // 初始化開始時間
    startTime = DateTime.now();
    
    // 初始化當前狀態
    getCurrentStatus();
  }

  // Function B: 獲取當前位置、剩餘時間、當前運動
  void getCurrentStatus() {
    if (path.isEmpty || estimatedMinutesList.isEmpty || movements.isEmpty) {
      return;
    }

    if (startTime == null) {
      startTime = DateTime.now();
    }

    // 計算已過時間（秒）
    final elapsedSeconds = DateTime.now().difference(startTime!).inSeconds;

    // 計算總時間（秒）
    final totalSeconds = (estimatedMinutesList.fold(0.0, (sum, time) => sum + time) * 60).round();

    // 找出當前所在的路段（使用秒數計算）
    int accumulatedSeconds = 0;
    int currentSegmentIndex = 0;
    int segmentStartSeconds = 0;
    bool foundSegment = false;

    for (int i = 0; i < estimatedMinutesList.length; i++) {
      final segmentSeconds = (estimatedMinutesList[i] * 60).round();
      if (elapsedSeconds <= accumulatedSeconds + segmentSeconds) {
        currentSegmentIndex = i;
        segmentStartSeconds = accumulatedSeconds;
        foundSegment = true;
        break;
      }
      accumulatedSeconds += segmentSeconds;
    }

    // 如果已經超過所有路段，設定為最後一站
    if (elapsedSeconds >= totalSeconds) {
      currentSegmentIndex = path.length - 1;
      _updateLocation(path.last);
      currentMovement.value = movements.isNotEmpty ? movements.last : '';
      remainingTimeSeconds.value = 0;
    } else if (foundSegment) {
      // 計算到下一站的剩餘時間（當前路段的剩餘時間）
      final segmentSeconds = (estimatedMinutesList[currentSegmentIndex] * 60).round();
      final elapsedInSegment = elapsedSeconds - segmentStartSeconds;
      final remainingInSegment = (segmentSeconds - elapsedInSegment).clamp(0, segmentSeconds);
      remainingTimeSeconds.value = remainingInSegment;

      // 如果已經到達當前路段的終點站（剩餘時間為0），顯示終點站並準備下一段
      if (remainingInSegment == 0 && currentSegmentIndex < path.length - 1) {
        // 已經到達當前路段的終點，顯示終點站（即下一段的起點）
        _updateLocation(path[currentSegmentIndex + 1]);
        // 如果還有下一段，顯示下一段的運動和時間
        if (currentSegmentIndex + 1 < movements.length) {
          currentMovement.value = movements[currentSegmentIndex + 1];
        }
        if (currentSegmentIndex + 1 < estimatedMinutesList.length) {
          final nextSegmentSeconds = (estimatedMinutesList[currentSegmentIndex + 1] * 60).round();
          remainingTimeSeconds.value = nextSegmentSeconds;
        }
      } else {
        // 還在當前路段中，顯示起點站
        if (currentSegmentIndex < path.length) {
          _updateLocation(path[currentSegmentIndex]);
        }
        // 設定當前運動類型（當前路段的運動）
        if (currentSegmentIndex < movements.length) {
          currentMovement.value = movements[currentSegmentIndex];
        }
      }
    }
  }

  // TODO: 當位置改變時，此函數會被調用
  // 請在此函數中實作位置改變時的處理邏輯
  void onLocationChanged(MrtStation? location) {
    // 此函數會在 currentLocation 改變時自動調用
    // location 參數為當前的位置（MrtStation 物件）
    // 可以在這裡實作需要的邏輯，例如：更新 UI、發送通知、記錄日誌等
  }
  
  // 更新位置並觸發回調
  void _updateLocation(MrtStation? newLocation) {
    if (newLocation != _previousLocation) {
      currentLocation.value = newLocation;
      _previousLocation = newLocation;
      onLocationChanged(newLocation);
    }
  }

  // 載入推薦的運動
  Future<void> loadRecommendedExercises() async {
    // TODO: 實作推薦邏輯
    // 根據 bodyParts 和 estimatedMinutes 篩選適合的運動
    // TODO: 實作推薦邏輯（串接服務後再補上）
    print('推薦運動給：${bodyPartsDisplayName}，預估時間：$estimatedMinutes 分鐘');
  }

  /// 對外提供設定推薦運動資料的接口
  void setExercise(ExerciseRecommendation item) {
    isLoading.value = false;
    _exercise.value = item;
  }

  /// 模擬載入假資料
  Future<void> loadSampleExercises() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    setExercise(
      ExerciseRecommendation(
        name: '肩頸舒展',
        imageUrl: 'https://images.unsplash.com/photo-1547045662-28cfb6b02c42',
        description: '透過肩頸拉伸減緩長時間乘車的僵硬感。',
      ),
    );
  }
  
  /// 儲存運動紀錄
  /// 參數：
  /// - exercises: 完成的運動列表（ExerciseRecord）
  /// - totalCalories: 總消耗卡路里
  /// - totalDuration: 總運動時間（秒）
  Future<void> saveExerciseRecord({
    required List<ExerciseRecord> exercises,
    required int totalCalories,
    required int totalDuration,
  }) async {
    if (_historyService == null) {
      print('ExerciseHistoryService 不可用，無法儲存紀錄');
      Get.snackbar(
        '提示',
        '無法儲存運動紀錄',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final history = ExerciseHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startStation: startStation.name,
        endStation: endStation.name,
        startStationEn: startStation.nameEn,
        endStationEn: endStation.nameEn,
        exercises: exercises,
        totalCalories: totalCalories,
        totalDuration: totalDuration,
        timestamp: DateTime.now(),
        bodyPartName: bodyPartsDisplayName,
      );

      final success = await _historyService!.saveExerciseHistory(history);
      
      if (success) {
        print('運動紀錄已儲存');
        Get.snackbar(
          '運動完成！',
          '已記錄本次運動，消耗 $totalCalories 卡路里',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        print('儲存運動紀錄失敗');
      }
    } catch (e) {
      print('儲存運動紀錄時發生錯誤：$e');
    }
  }
}

class ExerciseRecommendation {
  ExerciseRecommendation({
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  final String name;
  final String imageUrl;
  final String description;
}

import 'dart:async';
import 'package:get/get.dart';
import 'package:town_pass/bean/mrt_station.dart';
import 'package:town_pass/bean/body_part.dart';

class ExerciseRecommendationController extends GetxController {
  // 接收的參數
  late MrtStation startStation;
  late MrtStation endStation;
  late BodyPart bodyPart;
  late int estimatedMinutes;

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

  @override
  void onInit() {
    super.onInit();

    // 從路由參數獲取資料
    final args = Get.arguments as Map<String, dynamic>;
    startStation = args['startStation'] as MrtStation;
    endStation = args['endStation'] as MrtStation;
    bodyPart = args['bodyPart'] as BodyPart;
    estimatedMinutes = args['estimatedMinutes'] as int;

    // TODO: 根據參數推薦適合的運動
    loadRecommendedExercises();
  }

  @override
  void onClose() {
    _updateTimer?.cancel();
    super.onClose();
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

  // 格式化剩餘時間為 "X分Y秒"
  String get remainingTimeFormatted {
    final totalSeconds = remainingTimeSeconds.value;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (minutes > 0 && seconds > 0) {
      return '${minutes}分${seconds}秒';
    } else if (minutes > 0) {
      return '${minutes}分';
    } else {
      return '${seconds}秒';
    }
  }

  // 載入推薦的運動
  Future<void> loadRecommendedExercises() async {
    // TODO: 實作推薦邏輯
    // 根據 bodyPart 和 estimatedMinutes 篩選適合的運動
    print('推薦運動給：${bodyPart.name}，預估時間：$estimatedMinutes 分鐘');
    
    // 初始化測試用的模擬資料
    initializeMockData();
  }

  // 初始化模擬資料用於測試
  void initializeMockData() {
    // 創建模擬的 MRT 站點路徑：8個站點
    final mockPath = [
      _createMockStation(
        id: 'R09',
        stationCode: 'R09',
        name: '中山',
        nameEn: 'Zhongshan',
        lines: ['red', 'green'],
        lineColors: ['#E3002C', '#008659'],
        lat: 25.0527,
        lng: 121.5202,
        district: '中山區',
        city: '台北市',
      ),
      _createMockStation(
        id: 'BL12',
        stationCode: 'BL12',
        name: '忠孝復興',
        nameEn: 'Zhongxiao Fuxing',
        lines: ['blue', 'green'],
        lineColors: ['#0070BD', '#008659'],
        lat: 25.0418,
        lng: 121.5440,
        district: '大安區',
        city: '台北市',
      ),
      _createMockStation(
        id: 'BL15',
        stationCode: 'BL15',
        name: '市政府',
        nameEn: 'Taipei City Hall',
        lines: ['blue'],
        lineColors: ['#0070BD'],
        lat: 25.0408,
        lng: 121.5657,
        district: '信義區',
        city: '台北市',
      ),
      _createMockStation(
        id: 'R11',
        stationCode: 'R11',
        name: '台北101/世貿',
        nameEn: 'Taipei 101/World Trade Center',
        lines: ['red'],
        lineColors: ['#E3002C'],
        lat: 25.0330,
        lng: 121.5654,
        district: '信義區',
        city: '台北市',
      ),
      _createMockStation(
        id: 'R12',
        stationCode: 'R12',
        name: '象山',
        nameEn: 'Xiangshan',
        lines: ['red'],
        lineColors: ['#E3002C'],
        lat: 25.0330,
        lng: 121.5698,
        district: '信義區',
        city: '台北市',
      ),
      _createMockStation(
        id: 'O07',
        stationCode: 'O07',
        name: '忠孝新生',
        nameEn: 'Zhongxiao Xinsheng',
        lines: ['orange', 'blue'],
        lineColors: ['#F8B61C', '#0070BD'],
        lat: 25.0423,
        lng: 121.5329,
        district: '大安區',
        city: '台北市',
      ),
      _createMockStation(
        id: 'O05',
        stationCode: 'O05',
        name: '南京復興',
        nameEn: 'Nanjing Fuxing',
        lines: ['orange', 'green'],
        lineColors: ['#F8B61C', '#008659'],
        lat: 25.0520,
        lng: 121.5440,
        district: '中山區',
        city: '台北市',
      ),
      _createMockStation(
        id: 'O12',
        stationCode: 'O12',
        name: '東門',
        nameEn: 'Dongmen',
        lines: ['orange', 'green'],
        lineColors: ['#F8B61C', '#008659'],
        lat: 25.0338,
        lng: 121.5284,
        district: '大安區',
        city: '台北市',
      ),
    ];

    // 每段路程的預估時間（分鐘）- 8個站點有7段路程，每段時間在 0.05 到 0.15 之間
    final mockEstimatedMinutes = [0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05];

    // 每段路程的運動類型（對應7段路程）
    final mockMovements = [
      '深蹲',
      '手臂伸展',
      '頸部轉動',
      '腿部拉伸',
      '腰部扭轉',
      '肩部放鬆',
      '全身伸展',
    ];

    // 設定路徑資料
    setPathData(
      path: mockPath,
      estimatedMinutesList: mockEstimatedMinutes,
      movements: mockMovements,
    );

    print('模擬資料已初始化：');
    print('路徑：${mockPath.map((s) => s.name).join(' → ')}');
    print('時間：${mockEstimatedMinutes.join(', ')} 分鐘');
    print('運動：${mockMovements.join(', ')}');
  }

  // 輔助方法：創建模擬的 MRT 站點
  MrtStation _createMockStation({
    required String id,
    required String stationCode,
    required String name,
    required String nameEn,
    required List<String> lines,
    required List<String> lineColors,
    required double lat,
    required double lng,
    required String district,
    required String city,
  }) {
    return MrtStation(
      id: id,
      stationCode: stationCode,
      name: name,
      nameEn: nameEn,
      lines: lines,
      lineColors: lineColors,
      location: Location(lat: lat, lng: lng),
      district: district,
      city: city,
    );
  }
}

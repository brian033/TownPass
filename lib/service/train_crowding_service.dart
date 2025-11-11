import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:town_pass/bean/mrt_connection.dart';

/// 列車資訊
class TrainInfo {
  TrainInfo({
    required this.trainNumber,
    required this.trainSetId,
    required this.direction,
    required this.currentStation,
    required this.currentStationCode,
    required this.carriages,
    required this.nextStation,
    required this.arrivalTime,
    required this.updateTime,
  });

  final String trainNumber;
  final String trainSetId;
  final String direction;
  final String currentStation;
  final String currentStationCode;
  final List<CarriageInfo> carriages;
  final String nextStation;
  final String arrivalTime;
  final String updateTime;

  factory TrainInfo.fromJson(Map<String, dynamic> json) {
    return TrainInfo(
      trainNumber: json['trainNumber']?.toString() ?? '',
      trainSetId: json['trainSetId']?.toString() ?? '',
      direction: json['direction']?.toString() ?? '',
      currentStation: json['currentStation']?.toString() ?? '',
      currentStationCode: json['currentStationCode']?.toString() ?? '',
      carriages: (json['carriages'] as List<dynamic>?)
              ?.map((e) => CarriageInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextStation: json['nextStation']?.toString() ?? '',
      arrivalTime: json['arrivalTime']?.toString() ?? '',
      updateTime: json['updateTime']?.toString() ?? '',
    );
  }

  /// 計算平均擁擠度
  double get averageCrowdingLevel {
    if (carriages.isEmpty) return 0;
    final sum = carriages.fold<int>(
      0,
      (prev, carriage) => prev + carriage.crowdingLevel,
    );
    return sum / carriages.length;
  }

  /// 是否擁擠（平均擁擠度 > 2）
  bool get isCrowded => averageCrowdingLevel > 2;
}

/// 車廂資訊
class CarriageInfo {
  CarriageInfo({
    required this.carriageNumber,
    required this.crowdingLevel,
    required this.crowdingLevelText,
  });

  final int carriageNumber;
  final int crowdingLevel;
  final String crowdingLevelText;

  factory CarriageInfo.fromJson(Map<String, dynamic> json) {
    return CarriageInfo(
      carriageNumber: json['carriageNumber'] as int? ?? 0,
      crowdingLevel: json['crowdingLevel'] as int? ?? 0,
      crowdingLevelText: json['crowdingLevelText']?.toString() ?? '',
    );
  }
}

/// 列車擁擠度服務
class TrainCrowdingService {
  TrainCrowdingService._();
  
  static final TrainCrowdingService _instance = TrainCrowdingService._();
  factory TrainCrowdingService() => _instance;

  List<TrainInfo> _crowdingData = [];
  Map<String, List<String>> _stationNumbers = {};

  /// 初始化服務
  Future<void> initialize() async {
    await Future.wait([
      _loadCrowdingData(),
      _loadStationNumbers(),
    ]);
  }

  /// 載入擁擠度資料
  Future<void> _loadCrowdingData() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/mock_data/train_crowding.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);
      final trains = data['trains'] as List<dynamic>?;
      if (trains != null) {
        _crowdingData = trains
            .map((e) => TrainInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading train crowding data: $e');
    }
  }

  /// 載入站名編號對照表
  Future<void> _loadStationNumbers() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/mock_data/mrt_station_inshort.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);
      _stationNumbers = data.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e.toString()).toList(),
        ),
      );
    } catch (e) {
      print('Error loading station numbers: $e');
    }
  }

  /// 判斷方向（上行或下行）
  /// 從 fromCode 到 toCode，如果編號增加是上行，編號減少是下行
  String? _determineDirection(String fromCode, String toCode) {
    // 提取數字部分
    final fromMatch = RegExp(r'\d+').firstMatch(fromCode);
    final toMatch = RegExp(r'\d+').firstMatch(toCode);
    
    if (fromMatch == null || toMatch == null) return null;
    
    final fromNum = int.tryParse(fromMatch.group(0) ?? '');
    final toNum = int.tryParse(toMatch.group(0) ?? '');
    
    if (fromNum == null || toNum == null) return null;
    
    return toNum > fromNum ? '上行' : '下行';
  }

  /// 尋找最近的列車
  /// startStationName: 起始站名稱
  /// nextStationName: 下一站名稱（路徑中的下一個站）
  /// direction: 行駛方向（上行或下行）
  TrainInfo? _findNearestTrain(
    String startStationName,
    String nextStationName,
    String direction,
    List<String> stationCodes,
  ) {
    final startCode = stationCodes.first;
    final startNum = int.tryParse(RegExp(r'\d+').firstMatch(startCode)?.group(0) ?? '');
    
    if (startNum == null) return null;
    
    final linePrefix = startCode.replaceAll(RegExp(r'\d+'), '');

    print('Finding train: startStation=$startStationName, userDirection=$direction');
    print('Start code: $startCode, number: $startNum');

    // 重要：使用者的行進方向是上行 → 列車從編號小的站過來
    // 使用者的行進方向是下行 → 列車從編號大的站過來
    // 例如：台北車站(R10) → 中山(R11) 是上行，要找從 R09, R08... 來的列車
    final searchRange = direction == '上行'
        ? List.generate(5, (i) => startNum - i - 1) // 從小編號找（R09, R08, R07...）
        : List.generate(5, (i) => startNum + i + 1); // 從大編號找（R11, R12, R13...）

    print('Search range (stations where trains are coming from): $searchRange');

    // 首先檢查起始站本身是否有列車準備出發
    final trainsAtStart = _crowdingData.where((train) {
      return train.currentStation == startStationName &&
          train.direction == direction;
    }).toList();

    if (trainsAtStart.isNotEmpty) {
      print('✓ Found ${trainsAtStart.length} train(s) at $startStationName heading $direction');
      trainsAtStart.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
      return trainsAtStart.first;
    }

    // 從前面的站找即將進站的列車
    for (final targetNum in searchRange) {
      if (targetNum <= 0) continue;
      
      final targetCode = '$linePrefix$targetNum';
      
      // 反查站名
      String? targetStationName;
      for (final entry in _stationNumbers.entries) {
        if (entry.value.contains(targetCode)) {
          targetStationName = entry.key;
          break;
        }
      }
      
      if (targetStationName == null) {
        print('  Station code $targetCode not found');
        continue;
      }

      print('  Checking station: $targetStationName ($targetCode)');

      // 找該站往使用者方向行駛的列車
      final trainsAtTarget = _crowdingData.where((train) {
        return train.currentStation == targetStationName &&
            train.direction == direction;
      }).toList();

      if (trainsAtTarget.isNotEmpty) {
        print('  ✓ Found ${trainsAtTarget.length} train(s) at $targetStationName heading $direction');
        trainsAtTarget.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
        final selectedTrain = trainsAtTarget.first;
        print('  → Selected train ${selectedTrain.trainNumber}, next stop: ${selectedTrain.nextStation}');
        return selectedTrain;
      }
    }

    print('✗ No trains found in search range');
    return null;
  }

  /// 檢查路徑是否擁擠
  /// fromStationName: 起始站名稱
  /// toStationName: 目的站名稱（路徑中的下一個站）
  bool checkIfCrowded(String fromStationName, String toStationName) {
    print('=== Checking crowding: $fromStationName -> $toStationName ===');
    
    // 清理站名：移除括號及其內容（如 "台北車站(板南線)" -> "台北車站"）
    final cleanFromName = fromStationName.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    final cleanToName = toStationName.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    
    print('Cleaned names: $cleanFromName -> $cleanToName');
    
    // 1. 取得兩個站的編號
    final fromCodes = _stationNumbers[cleanFromName];
    final toCodes = _stationNumbers[cleanToName];
    
    print('From codes: $fromCodes, To codes: $toCodes');
    
    if (fromCodes == null || toCodes == null) {
      print('❌ Station codes not found for $cleanFromName or $cleanToName');
      print('Available stations: ${_stationNumbers.keys.take(10).join(", ")}...');
      return false; // 找不到資料時預設不擁擠
    }

    // 2. 找出共同路線的編號
    String? fromCode;
    String? toCode;
    
    for (final from in fromCodes) {
      final linePrefix = from.replaceAll(RegExp(r'\d+'), '');
      for (final to in toCodes) {
        if (to.startsWith(linePrefix)) {
          fromCode = from;
          toCode = to;
          break;
        }
      }
      if (fromCode != null) break;
    }

    if (fromCode == null || toCode == null) {
      print('❌ No common line found between $cleanFromName and $cleanToName');
      return false;
    }
    
    print('Station codes: $fromCode -> $toCode');

    // 3. 判斷方向
    final direction = _determineDirection(fromCode, toCode);
    if (direction == null) {
      print('❌ Could not determine direction');
      return false;
    }
    
    print('Direction: $direction');

    // 4. 尋找最近的列車
    final train = _findNearestTrain(
      cleanFromName,
      cleanToName,
      direction,
      [fromCode, toCode],
    );

    if (train == null) {
      print('❌ No train found for route $cleanFromName -> $cleanToName');
      print('Available trains: ${_crowdingData.map((t) => '${t.trainNumber}@${t.currentStation}').take(3).join(", ")}');
      return false; // 找不到列車時預設不擁擠
    }

    // 5. 檢查擁擠度
    final isCrowded = train.isCrowded;
    print('✅ Train ${train.trainNumber} from $cleanFromName to $cleanToName: '
        'avg crowding = ${train.averageCrowdingLevel.toStringAsFixed(2)}, '
        'isCrowded = $isCrowded');
    print('=== End checking ===\n');
    
    return isCrowded;
  }

  /// 根據擁擠度篩選運動
  /// exercises: 原始運動清單
  /// isCrowded: 是否擁擠
  List<RecommendedExercise> filterExercisesByCrowding(
    List<RecommendedExercise> exercises,
    bool isCrowded,
  ) {
    print('=== Filtering exercises ===');
    print('isCrowded: $isCrowded');
    print('Original exercises count: ${exercises.length}');
    
    if (!isCrowded) {
      // 不擁擠時，所有運動都可以做
      print('✅ Not crowded - returning all exercises');
      print('=== End filtering ===\n');
      return exercises;
    }
    
    // 擁擠時，只能做 doInCrowded = true 的運動
    final filtered = exercises.where((exercise) => exercise.doInCrowded).toList();
    print('⚠️ Crowded - filtered to ${filtered.length} exercises (doInCrowded=true only)');
    print('Filtered exercises: ${filtered.map((e) => e.name).join(", ")}');
    print('=== End filtering ===\n');
    return filtered;
  }
}

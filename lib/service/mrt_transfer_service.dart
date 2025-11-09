import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:town_pass/bean/mrt_station.dart';

/// 捷運轉乘站服務
/// 負責管理轉乘站資訊和判斷是否需要轉乘
class MrtTransferService {
  // Singleton 實例
  static final MrtTransferService _instance = MrtTransferService._internal();
  factory MrtTransferService() => _instance;
  MrtTransferService._internal();

  /// 轉乘站資料：站名 -> 路線代碼列表
  /// 例如：{"台北車站": ["R10", "BL12"], "中山": ["R11", "G14"]}
  Map<String, List<String>> _transferStations = {};

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化轉乘站資料
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // 讀取 mrt_station_inshort.json
      final String jsonString = await rootBundle.loadString(
        'assets/mock_data/mrt_station_inshort.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      // 篩選出有兩個或以上路線代碼的站（轉乘站）
      _transferStations = {};
      data.forEach((stationName, codes) {
        if (codes is List && codes.length >= 2) {
          _transferStations[stationName] = List<String>.from(codes);
        }
      });

      _isInitialized = true;
      print('✅ MrtTransferService 初始化完成，轉乘站數量：${_transferStations.length}');
    } catch (e) {
      print('❌ MrtTransferService 初始化失敗：$e');
    }
  }

  /// 獲取所有轉乘站名稱列表
  List<String> get transferStationNames => _transferStations.keys.toList();

  /// 檢查是否為轉乘站
  bool isTransferStation(String stationName) {
    return _transferStations.containsKey(stationName);
  }

  /// 獲取車站的路線代碼列表
  List<String>? getStationLineCodes(String stationName) {
    return _transferStations[stationName];
  }

  /// 提取路線代碼的英文字母部分（路線識別碼）
  /// 例如：R10 -> R, BL12 -> BL
  String _extractLineId(String code) {
    // 移除所有數字，只保留英文字母
    return code.replaceAll(RegExp(r'[0-9]'), '');
  }

  /// 判斷兩個站點的路線代碼是否有共同的路線
  /// 返回 true 表示有共同路線（不需要轉乘）
  /// 返回 false 表示沒有共同路線（需要轉乘）
  bool _hasCommonLine(List<String> codes1, List<String> codes2) {
    final lines1 = codes1.map(_extractLineId).toSet();
    final lines2 = codes2.map(_extractLineId).toSet();
    return lines1.intersection(lines2).isNotEmpty;
  }

  /// 檢查從前一站到下一站是否需要轉乘
  /// 
  /// 參數：
  /// - currentStation: 當前站（可能是轉乘站）
  /// - previousStation: 前一站
  /// - nextStation: 下一站
  /// 
  /// 返回：
  /// - true: 需要轉乘
  /// - false: 不需要轉乘
  Future<bool> needsTransfer({
    required MrtStation currentStation,
    required MrtStation previousStation,
    required MrtStation nextStation,
  }) async {
    // 確保已初始化
    if (!_isInitialized) {
      await initialize();
    }

    // 1. 檢查當前站是否為轉乘站
    if (!isTransferStation(currentStation.name)) {
      return false;
    }

    // 2. 讀取完整的站點資料（包含所有站點的路線代碼）
    final String jsonString = await rootBundle.loadString(
      'assets/mock_data/mrt_station_inshort.json',
    );
    final Map<String, dynamic> allStations = json.decode(jsonString);

    // 3. 獲取前一站的路線代碼
    final previousCodes = allStations[previousStation.name];
    if (previousCodes == null || previousCodes is! List) {
      return false;
    }
    final prevLinesList = List<String>.from(previousCodes);

    // 4. 獲取下一站的路線代碼
    final nextCodes = allStations[nextStation.name];
    if (nextCodes == null || nextCodes is! List) {
      return false;
    }
    final nextLinesList = List<String>.from(nextCodes);

    // 5. 檢查前一站和下一站是否有共同的路線
    final hasCommon = _hasCommonLine(prevLinesList, nextLinesList);

    // 6. 如果沒有共同路線，表示需要轉乘
    return !hasCommon;
  }

  /// 獲取轉乘資訊（用於顯示）
  Future<TransferInfo?> getTransferInfo({
    required MrtStation currentStation,
    required MrtStation previousStation,
    required MrtStation nextStation,
  }) async {
    final needsTransferFlag = await needsTransfer(
      currentStation: currentStation,
      previousStation: previousStation,
      nextStation: nextStation,
    );

    if (!needsTransferFlag) {
      return null;
    }

    // 讀取站點資料
    final String jsonString = await rootBundle.loadString(
      'assets/mock_data/mrt_station_inshort.json',
    );
    final Map<String, dynamic> allStations = json.decode(jsonString);

    final previousCodes = List<String>.from(allStations[previousStation.name] ?? []);
    final nextCodes = List<String>.from(allStations[nextStation.name] ?? []);

    final prevLines = previousCodes.map(_extractLineId).toSet();
    final nextLines = nextCodes.map(_extractLineId).toSet();

    return TransferInfo(
      transferStation: currentStation,
      fromLine: prevLines.join('/'),
      toLine: nextLines.join('/'),
      needsTransfer: true,
    );
  }
}

/// 轉乘資訊
class TransferInfo {
  final MrtStation transferStation;
  final String fromLine; // 來源路線（例如：BL）
  final String toLine; // 目的路線（例如：R）
  final bool needsTransfer;

  TransferInfo({
    required this.transferStation,
    required this.fromLine,
    required this.toLine,
    required this.needsTransfer,
  });

  @override
  String toString() {
    return '轉乘站：${transferStation.name}，從 $fromLine 線轉乘 $toLine 線';
  }
}

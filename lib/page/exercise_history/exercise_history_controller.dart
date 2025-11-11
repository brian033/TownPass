import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/exercise_history.dart';
import 'package:town_pass/service/exercise_history_service.dart';

class ExerciseHistoryController extends GetxController {
  ExerciseHistoryService? _historyService;

  final RxList<ExerciseHistory> histories = <ExerciseHistory>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt totalCount = 0.obs;
  final RxInt totalCalories = 0.obs;
  final RxInt totalDuration = 0.obs; // 分鐘
  final RxMap<String, bool> expandedStates = <String, bool>{}.obs; // 追蹤每個歷史記錄的展開狀態

  @override
  void onInit() {
    super.onInit();
    _initService();
  }

  Future<void> _initService() async {
    try {
      _historyService = Get.find<ExerciseHistoryService>();
    } catch (e) {
      print('ExerciseHistoryService 未初始化，嘗試建立新實例');
      try {
        _historyService = await Get.putAsync<ExerciseHistoryService>(
          () async => await ExerciseHistoryService().init(),
        );
      } catch (e) {
        print('無法初始化 ExerciseHistoryService: $e');
      }
    }
    await loadHistories();
    await loadStatistics();
    
    // 如果沒有資料，加入一些示範資料
    if (histories.isEmpty && _historyService != null) {
      await _addSampleData();
    }
  }

  Future<void> _addSampleData() async {
    if (_historyService == null) return;
    
    // 示範資料 1
    final sample1 = ExerciseHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startStation: '台北車站',
      endStation: '中山',
      startStationEn: 'Taipei Main Station',
      endStationEn: 'Zhongshan',
      exercises: [
        ExerciseRecord(
          exerciseName: '頸部伸展',
          duration: 90,
          calories: 3,
          stationSegment: '台北車站 → 中山',
        ),
      ],
      totalCalories: 3,
      totalDuration: 90,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      bodyPartName: '頸部肩膀',
    );

    // 示範資料 2
    final sample2 = ExerciseHistory(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      startStation: '公館',
      endStation: '古亭',
      startStationEn: 'Gongguan',
      endStationEn: 'Guting',
      exercises: [
        ExerciseRecord(
          exerciseName: '坐姿腿部伸展',
          duration: 90,
          calories: 10,
          stationSegment: '公館 → 台電大樓',
        ),
        ExerciseRecord(
          exerciseName: '深呼吸放鬆',
          duration: 60,
          calories: 2,
          stationSegment: '台電大樓 → 古亭',
        ),
      ],
      totalCalories: 12,
      totalDuration: 150,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      bodyPartName: '下半身',
    );

    await _historyService!.saveExerciseHistory(sample1);
    await _historyService!.saveExerciseHistory(sample2);
    
    // 重新載入資料
    await loadHistories();
    await loadStatistics();
  }

  Future<void> loadHistories() async {
    if (_historyService == null) {
      print('ExerciseHistoryService 不可用');
      return;
    }
    
    isLoading.value = true;
    try {
      final data = await _historyService!.getExerciseHistories();
      histories.value = data;
    } catch (e) {
      print('載入運動紀錄失敗：$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStatistics() async {
    if (_historyService == null) return;
    
    try {
      totalCount.value = await _historyService!.getTotalExerciseCount();
      totalCalories.value = await _historyService!.getTotalCaloriesBurned();
      totalDuration.value = await _historyService!.getTotalExerciseDuration();
    } catch (e) {
      print('載入統計資料失敗：$e');
    }
  }

  Future<void> deleteHistory(String id) async {
    if (_historyService == null) return;
    
    final success = await _historyService!.deleteExerciseHistory(id);
    if (success) {
      await loadHistories();
      await loadStatistics();
      Get.snackbar(
        '刪除成功',
        '已刪除該筆運動紀錄',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        '刪除失敗',
        '無法刪除該筆運動紀錄',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> clearAllHistories() async {
    if (_historyService == null) return;
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('確認清空'),
        content: const Text('確定要清空所有運動紀錄嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('確定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _historyService!.clearAllHistories();
      if (success) {
        await loadHistories();
        await loadStatistics();
        Get.snackbar(
          '清空成功',
          '已清空所有運動紀錄',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void refresh() {
    loadHistories();
    loadStatistics();
  }

  /// 切換指定歷史記錄的展開/收合狀態
  void toggleExerciseExpansion(String historyId) {
    expandedStates[historyId] = !(expandedStates[historyId] ?? false);
  }

  /// 檢查指定歷史記錄是否展開
  bool isExpanded(String historyId) {
    return expandedStates[historyId] ?? false;
  }
}

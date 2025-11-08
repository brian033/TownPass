import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/bean/exercise_history.dart';

class ExerciseHistoryService extends GetxService {
  static const String _keyExerciseHistory = 'exercise_history_list';
  
  SharedPreferences? _prefs;

  Future<ExerciseHistoryService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  /// 儲存一筆新的運動紀錄
  Future<bool> saveExerciseHistory(ExerciseHistory history) async {
    try {
      final histories = await getExerciseHistories();
      histories.insert(0, history); // 最新的放前面
      
      // 只保留最近 100 筆
      if (histories.length > 100) {
        histories.removeRange(100, histories.length);
      }
      
      final jsonList = histories.map((h) => h.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      return await _prefs?.setString(_keyExerciseHistory, jsonString) ?? false;
    } catch (e) {
      print('儲存運動紀錄失敗：$e');
      return false;
    }
  }

  /// 取得所有運動紀錄
  Future<List<ExerciseHistory>> getExerciseHistories() async {
    try {
      final jsonString = _prefs?.getString(_keyExerciseHistory);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => ExerciseHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('讀取運動紀錄失敗：$e');
      return [];
    }
  }

  /// 刪除指定 ID 的紀錄
  Future<bool> deleteExerciseHistory(String id) async {
    try {
      final histories = await getExerciseHistories();
      histories.removeWhere((h) => h.id == id);
      
      final jsonList = histories.map((h) => h.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      return await _prefs?.setString(_keyExerciseHistory, jsonString) ?? false;
    } catch (e) {
      print('刪除運動紀錄失敗：$e');
      return false;
    }
  }

  /// 清空所有紀錄
  Future<bool> clearAllHistories() async {
    try {
      return await _prefs?.remove(_keyExerciseHistory) ?? false;
    } catch (e) {
      print('清空運動紀錄失敗：$e');
      return false;
    }
  }

  /// 取得總運動次數
  Future<int> getTotalExerciseCount() async {
    final histories = await getExerciseHistories();
    return histories.length;
  }

  /// 取得總消耗卡路里
  Future<int> getTotalCaloriesBurned() async {
    final histories = await getExerciseHistories();
    return histories.fold<int>(0, (sum, h) => sum + h.totalCalories);
  }

  /// 取得總運動時間（分鐘）
  Future<int> getTotalExerciseDuration() async {
    final histories = await getExerciseHistories();
    final totalSeconds = histories.fold<int>(0, (sum, h) => sum + h.totalDuration);
    return totalSeconds ~/ 60;
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/mrt_connection.dart';
import 'package:town_pass/bean/mrt_station.dart';
import 'package:town_pass/bean/exercise_history.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';
import 'package:town_pass/page/exercise_recommendation/widget/exercise_timer_card.dart';
import 'package:town_pass/page/exercise_recommendation/widget/exercise_info_card.dart';
import 'package:town_pass/page/exercise_recommendation/exercise_recommendation_controller.dart';
import 'package:town_pass/service/mrt_transfer_service.dart';

class JourneyTrackerWidget extends StatefulWidget {
  const JourneyTrackerWidget({
    super.key,
    required this.routeResult,
    required this.timerCardKey,
    required this.exerciseInfoCardKey,
    this.onJourneyCompleted,
  });

  final MrtRouteResult routeResult;
  final GlobalKey<ExerciseTimerCardState> timerCardKey;
  final GlobalKey<ExerciseInfoCardState> exerciseInfoCardKey;
  final void Function(Duration totalDuration, List<ExerciseRecord> exercises)? onJourneyCompleted;

  @override
  State<JourneyTrackerWidget> createState() => JourneyTrackerWidgetState();
}

class JourneyTrackerWidgetState extends State<JourneyTrackerWidget> {
  int _currentLegIndex = 0;
  bool _journeyStarted = false;
  bool _journeyCompleted = false;
  RecommendedExercise? _currentExercise;
  RecommendedExercise? _nextExercise;
  bool _isAtFinalStation = false;
  Timer? _autoProgressTimer;
  int _remainingSecondsToNextStation = 0;
  Timer? _countdownTimer;

  /// 記錄完成的運動列表
  final List<ExerciseRecord> _completedExercises = [];

  /// 追蹤動作狀態：當前動作開始的 leg index
  int? _currentExerciseStartLegIndex;
  /// 追蹤動作狀態：上一次記錄的動作名稱
  String? _previousExerciseName;
  /// 追蹤最後一個記錄的 leg index（用於防止重複記錄）
  int _lastRecordedLegIndex = -1;
  /// 追蹤當前動作開始的實際時間
  DateTime? _currentExerciseStartTime;
  /// 追蹤最後記錄的實際時間（用於部分記錄）
  DateTime? _lastRecordedTime;

  /// 轉乘相關狀態
  final MrtTransferService _transferService = MrtTransferService();
  bool _isTransferPaused = false; // 是否處於轉乘暫停狀態
  bool _needsTransferAtCurrentStation = false; // 當前站是否需要轉乘
  TransferInfo? _currentTransferInfo; // 當前轉乘資訊

  /// 對外提供當前運動的 getter
  RecommendedExercise? get currentExercise => _currentExercise;

  /// 從 routeResult 構建路徑資料
  List<MrtStation> _buildPath() {
    if (widget.routeResult.legs.isEmpty) {
      return [];
    }
    final pathList = <MrtStation>[];
    for (var leg in widget.routeResult.legs) {
      if (pathList.isEmpty) {
        pathList.add(leg.fromStation);
      }
      pathList.add(leg.toStation);
    }
    return pathList;
  }


  /// 獲取當前位置索引
  int _getCurrentIndex() {
    if (!_journeyStarted || widget.routeResult.legs.isEmpty) {
      return 0;
    }
    // 根據 _currentLegIndex 計算當前位置
    // path 的結構：path[0] 是起點（第一個 leg 的 fromStation），path[1] 是第一個 leg 的終點，以此類推
    // 當 _currentLegIndex = 0 時，我們在第一個 leg 中，應該顯示 path[0]（起點站）
    // 當 _currentLegIndex = 1 時，我們在第二個 leg 中，應該顯示 path[1]（第一個 leg 的終點站）
    return _currentLegIndex;
  }

  /// 獲取當前路段的進度（0.0 到 1.0）
  double _getSegmentProgress() {
    if (!_journeyStarted || widget.routeResult.legs.isEmpty) {
      return 0.0;
    }
    if (_currentLegIndex >= widget.routeResult.legs.length) {
      return 1.0;
    }
    final currentLeg = widget.routeResult.legs[_currentLegIndex];
    final totalSeconds = currentLeg.travelSeconds + currentLeg.stopSeconds;
    if (totalSeconds == 0) {
      return 1.0;
    }
    final elapsedSeconds = totalSeconds - _remainingSecondsToNextStation;
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _autoProgressTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 開始行程
  void _startJourney() {
    if (widget.routeResult.legs.isEmpty) return;

    setState(() {
      _journeyStarted = true;
      _journeyCompleted = false;
      _currentLegIndex = 0;
      _isAtFinalStation = false;
    });

    _selectRandomExercises();
    // 初始化動作追蹤狀態
    _currentExerciseStartLegIndex = 0;
    _previousExerciseName = _currentExercise?.name;
    _lastRecordedLegIndex = -1; // 重置最後記錄的 leg index
    _currentExerciseStartTime = DateTime.now(); // 記錄當前動作開始的實際時間
    _lastRecordedTime = null; // 重置最後記錄的時間
    _updateTimerCard();
    _startAutoProgressTimer();
  }

  /// 下一站
  void _nextStation() async {
    // path 有 legs.length + 1 个站（起点 + 每个 leg 的终点）
    // 当 _currentLegIndex = legs.length - 1 时，我们在 last - 1 station，应该能前进到 last station
    if (_currentLegIndex < widget.routeResult.legs.length) {
      // 在切換到下一站之前，保存當前動作資訊
      final oldExerciseName = _previousExerciseName;
      final oldExerciseStartLegIndex = _currentExerciseStartLegIndex;
      final oldExerciseStartTime = _currentExerciseStartTime;
      final isLastLeg = _currentLegIndex == widget.routeResult.legs.length - 1;
      
      // 如果這是最後一個 leg，在切換前記錄當前動作
      if (isLastLeg && _currentExercise != null && _currentExerciseStartLegIndex != null) {
        _recordCurrentExerciseAtLeg(_currentLegIndex);
      }
      
      setState(() {
        _currentLegIndex++;
      });

      final path = _buildPath();
      if (path.isNotEmpty) {
        final stationIndex =
            _currentLegIndex >= path.length ? path.length - 1 : _currentLegIndex;
        final reachedStation = path[stationIndex];
        Get.find<ExerciseRecommendationController>()
            .onLocationChanged(reachedStation);
      }
      
      // 如果已经到达最后一个站，完成旅程
      if (_currentLegIndex >= widget.routeResult.legs.length) {
        _autoProgressTimer?.cancel();
        _countdownTimer?.cancel();
        setState(() {
          _remainingSecondsToNextStation = 0;
          _isAtFinalStation = true;
        });
        widget.timerCardKey.currentState?.clear(showFinalMessage: true);
        widget.exerciseInfoCardKey.currentState?.clear(showFinalMessage: true);
      } else {
        // 選擇新的動作（可能會改變）
        _selectRandomExercises();
        final newExerciseName = _currentExercise?.name;
        
        // 如果動作改變了，記錄前一個動作（使用保存的資訊和時間）
        if (oldExerciseName != null && 
            newExerciseName != null && 
            oldExerciseName != newExerciseName &&
            oldExerciseStartLegIndex != null &&
            oldExerciseStartTime != null &&
            !isLastLeg) { // 如果不是最後一個 leg，才記錄前一個動作（最後一個已經記錄過了）
          _recordPreviousExercise(oldExerciseName, oldExerciseStartLegIndex, oldExerciseStartTime);
        }
        
        // 如果動作改變了，更新開始的 leg index 和時間
        if (newExerciseName != oldExerciseName) {
          _currentExerciseStartLegIndex = _currentLegIndex;
          _previousExerciseName = newExerciseName;
          _currentExerciseStartTime = DateTime.now(); // 記錄新動作開始的實際時間
        }
        
        // 先更新運動資訊顯示
        _updateTimerCard();
        
        // 再檢查是否需要轉乘（這樣運動資訊會先顯示出來）
        await _checkTransferAtCurrentStation();
        
        // 如果需要轉乘，不自動開始計時（已在 _checkTransferAtCurrentStation 中暫停）
        // 如果不需要轉乘，才啟動計時器
        if (!_needsTransferAtCurrentStation) {
          _startAutoProgressTimer();
        }
      }
    }
  }

  /// 上一站
  void _previousStation() async {
    if (_currentLegIndex > 0) {
      setState(() {
        _currentLegIndex--;
        _isAtFinalStation = false;
      });
      
      // 選擇新的動作（可能會改變）
      _selectRandomExercises();
      final newExerciseName = _currentExercise?.name;
      
      // 如果動作改變了，更新開始的 leg index 和時間（但不記錄，因為是回退）
      if (newExerciseName != _previousExerciseName) {
        _currentExerciseStartLegIndex = _currentLegIndex;
        _previousExerciseName = newExerciseName;
        _currentExerciseStartTime = DateTime.now(); // 重置開始時間，因為動作改變了
      }
      
      // 先更新運動資訊顯示
      _updateTimerCard();
      
      // 檢查是否需要轉乘（回到上一站時也要檢查）
      await _checkTransferAtCurrentStation();
      
      // 如果需要轉乘，不自動開始計時
      if (!_needsTransferAtCurrentStation) {
        _startAutoProgressTimer();
      }
    }
  }

  /// 隨機選擇兩個運動（current != next）
  void _selectRandomExercises() {
    final exercises = widget.routeResult.exercises;
    if (exercises.isEmpty) {
      _currentExercise = null;
      _nextExercise = null;
      return;
    }

    final random = Random();

    // 選擇 current
    _currentExercise = exercises[random.nextInt(exercises.length)];

    // 選擇 next（確保不同）
    if (exercises.length == 1) {
      _nextExercise = _currentExercise;
    } else {
      do {
        _nextExercise = exercises[random.nextInt(exercises.length)];
      } while (_nextExercise == _currentExercise);
    }
  }

  /// 檢查當前站是否需要轉乘
  Future<void> _checkTransferAtCurrentStation() async {
    // 重置轉乘狀態
    setState(() {
      _needsTransferAtCurrentStation = false;
      _currentTransferInfo = null;
      _isTransferPaused = false;
    });

    // 如果在起點或終點，不檢查轉乘
    if (_currentLegIndex == 0 || _currentLegIndex >= widget.routeResult.legs.length) {
      return;
    }

    final path = _buildPath();
    if (path.length < 3 || _currentLegIndex >= path.length) {
      return;
    }

    // 獲取當前站、前一站、下一站
    final currentStation = path[_currentLegIndex];
    final previousStation = path[_currentLegIndex - 1];
    final nextStation = _currentLegIndex + 1 < path.length 
        ? path[_currentLegIndex + 1] 
        : null;

    // 如果沒有下一站，不需要檢查轉乘
    if (nextStation == null) {
      return;
    }

    // 檢查是否需要轉乘
    final transferInfo = await _transferService.getTransferInfo(
      currentStation: currentStation,
      previousStation: previousStation,
      nextStation: nextStation,
    );

    if (transferInfo != null && transferInfo.needsTransfer) {
      setState(() {
        _needsTransferAtCurrentStation = true;
        _currentTransferInfo = transferInfo;
        _isTransferPaused = true; // 自動進入暫停狀態
      });

      // 暫停捷運路線計時器
      _autoProgressTimer?.cancel();
      _countdownTimer?.cancel();
      
      // 暫停運動計時器
      widget.timerCardKey.currentState?.pause();

      print('🚇 偵測到轉乘：${transferInfo.toString()}');
    }
  }

  /// 處理轉乘暫停/繼續按鈕點擊
  void _handleTransferPause() {
    setState(() {
      _isTransferPaused = !_isTransferPaused;
    });

    if (!_isTransferPaused) {
      // 繼續捷運路線計時
      _startAutoProgressTimer();
      
      // 繼續運動計時
      widget.timerCardKey.currentState?.resume();
      
      print('✅ 轉乘完成，繼續計時');
    } else {
      // 暫停捷運路線計時
      _autoProgressTimer?.cancel();
      _countdownTimer?.cancel();
      
      // 暫停運動計時
      widget.timerCardKey.currentState?.pause();
      
      print('⏸️ 轉乘暫停中');
    }
  }

  /// 更新 ExerciseTimerCard 和 ExerciseInfoCard
  void _updateTimerCard() {
    if (_currentLegIndex >= widget.routeResult.legs.length) {
      widget.timerCardKey.currentState?.clear(showFinalMessage: true);
      widget.exerciseInfoCardKey.currentState?.clear(showFinalMessage: true);
      return;
    }

    if (_currentExercise == null || _nextExercise == null) return;

    final currentLeg = widget.routeResult.legs[_currentLegIndex];
    final remainingSeconds = currentLeg.travelSeconds + currentLeg.stopSeconds;

    // 更新 ExerciseTimerCard
    widget.timerCardKey.currentState?.setDisplayCard(
      _currentExercise!.name,
      remainingSeconds,
    );

    // 更新 ExerciseInfoCard
    widget.exerciseInfoCardKey.currentState?.setExercise(_currentExercise!);

    // 不再在這裡記錄運動，改為在動作改變或結束時記錄
  }

  /// 記錄前一個完成的運動（當動作改變時調用）
  /// [exerciseName] 要記錄的動作名稱
  /// [startLegIndex] 動作開始的 leg index
  /// [startTime] 動作開始的實際時間
  void _recordPreviousExercise(String exerciseName, int startLegIndex, DateTime startTime) {
    if (_currentLegIndex <= startLegIndex) return;
    
    // 計算結束 leg index
    final endLegIndex = _currentLegIndex - 1; // 當前 leg 之前
    
    // 找到對應的運動對象
    final exercise = widget.routeResult.exercises.firstWhere(
      (e) => e.name == exerciseName,
      orElse: () => widget.routeResult.exercises.first,
    );
    
    // 計算實際經過的時間（秒）
    final now = DateTime.now();
    DateTime actualStartTime;
    
    // 檢查是否已經記錄過這個範圍
    if (startLegIndex <= _lastRecordedLegIndex && _lastRecordedTime != null) {
      // 如果結束 leg index 也比最後記錄的還要小或相等，完全重複，不記錄
      if (endLegIndex <= _lastRecordedLegIndex) {
        return;
      }
      // 如果結束 leg index 比最後記錄的還要大，只記錄新的部分（從最後記錄的時間開始）
      actualStartTime = _lastRecordedTime!;
    } else {
      // 使用原始開始時間
      actualStartTime = startTime;
    }
    
    // 計算實際經過的秒數
    final elapsed = now.difference(actualStartTime);
    final totalDuration = elapsed.inSeconds;
    
    // 記錄運動，即使持續時間為 0（但不記錄負數時間，這表示邏輯錯誤）
    if (totalDuration >= 0 && startLegIndex < widget.routeResult.legs.length) {
      final startLeg = widget.routeResult.legs[startLegIndex];
      final endLeg = widget.routeResult.legs[endLegIndex];
      final stationSegment = '${startLeg.fromStation.name} → ${endLeg.toStation.name}';
      
      final calories = (exercise.calPerSec * totalDuration).round();
      
      final record = ExerciseRecord(
        exerciseName: exercise.name,
        duration: totalDuration,
        calories: calories,
        stationSegment: stationSegment,
      );
      
      _completedExercises.add(record);
      // 更新最後記錄的 leg index 和時間
      _lastRecordedLegIndex = endLegIndex;
      _lastRecordedTime = now;
    }
  }

  /// 在指定 leg 記錄當前動作（用於結束旅程時）
  /// [endLegIndex] 結束的 leg index（包含）
  void _recordCurrentExerciseAtLeg(int endLegIndex) {
    if (_currentExercise == null || _currentExerciseStartLegIndex == null || _currentExerciseStartTime == null) return;
    
    final startLegIndex = _currentExerciseStartLegIndex!;
    final actualEndLegIndex = endLegIndex < widget.routeResult.legs.length 
        ? endLegIndex 
        : widget.routeResult.legs.length - 1;
    
    // 計算實際經過的時間（秒）
    final now = DateTime.now();
    DateTime actualStartTime;
    
    // 檢查是否已經記錄過這個範圍
    if (startLegIndex <= _lastRecordedLegIndex && _lastRecordedTime != null) {
      // 如果結束 leg index 也比最後記錄的還要小或相等，完全重複，不記錄
      if (actualEndLegIndex <= _lastRecordedLegIndex) {
        return;
      }
      // 如果結束 leg index 比最後記錄的還要大，只記錄新的部分（從最後記錄的時間開始）
      actualStartTime = _lastRecordedTime!;
    } else {
      // 使用原始開始時間
      actualStartTime = _currentExerciseStartTime!;
    }
    
    if (endLegIndex < startLegIndex) {
      // 如果沒有進度，不記錄
      return;
    }
    
    // 計算實際經過的秒數
    final elapsed = now.difference(actualStartTime);
    final totalDuration = elapsed.inSeconds;
    
    // 記錄運動，即使持續時間為 0（但不記錄負數時間，這表示邏輯錯誤）
    if (totalDuration >= 0 && startLegIndex < widget.routeResult.legs.length) {
      final startLeg = widget.routeResult.legs[startLegIndex];
      final endLeg = widget.routeResult.legs[actualEndLegIndex];
      final stationSegment = '${startLeg.fromStation.name} → ${endLeg.toStation.name}';
      
      final calories = (_currentExercise!.calPerSec * totalDuration).round();
      
      final record = ExerciseRecord(
        exerciseName: _currentExercise!.name,
        duration: totalDuration,
        calories: calories,
        stationSegment: stationSegment,
      );
      
      _completedExercises.add(record);
      // 更新最後記錄的 leg index 和時間
      _lastRecordedLegIndex = actualEndLegIndex;
      _lastRecordedTime = now;
    }
  }

  /// 啟動自動進站計時器和倒數計時器
  void _startAutoProgressTimer() {
    _autoProgressTimer?.cancel();
    _countdownTimer?.cancel();

    if (_journeyCompleted) {
      return;
    }

    final currentLeg = widget.routeResult.legs[_currentLegIndex];
    final totalSeconds = currentLeg.travelSeconds + currentLeg.stopSeconds;

    // 設定初始剩餘秒數
    setState(() {
      _remainingSecondsToNextStation = totalSeconds;
    });

    // 啟動倒數計時器（每秒更新一次）
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSecondsToNextStation > 0) {
          _remainingSecondsToNextStation--;
        }
      });
    });

    // 啟動自動進站計時器
    _autoProgressTimer = Timer(Duration(seconds: totalSeconds), () {
      if (!mounted) return;
      // 統一使用 _nextStation() 處理，它會自動判斷是否到達最後一站
      _nextStation();
    });
  }

  void _completeJourney() {
    if (_journeyCompleted) {
      return;
    }

    // 如果還沒有到達最後一站，記錄當前動作
    // 如果已經到達最後一站（_isAtFinalStation == true），動作已經在 _nextStation() 中記錄過了
    if (!_isAtFinalStation && 
        _currentExercise != null && 
        _currentExerciseStartLegIndex != null &&
        _currentLegIndex < widget.routeResult.legs.length) {
      // 記錄當前動作（到當前 leg）
      _recordCurrentExerciseAtLeg(_currentLegIndex);
    }

    _autoProgressTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      _journeyCompleted = true;
      _remainingSecondsToNextStation = 0;
    });

    widget.onJourneyCompleted
        ?.call(Duration(seconds: widget.routeResult.totalSeconds), _completedExercises);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TPColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TPText(
            '旅程追蹤',
            style: TPTextStyles.bodySemiBold,
            color: TPColors.grayscale900,
          ),
          const SizedBox(height: 16),
          _buildProgressBar(),
          const SizedBox(height: 20),
          _buildControlButtons(),
        ],
      ),
    );
  }

  /// 建立路徑視覺化
  Widget _buildProgressBar() {
    if (widget.routeResult.legs.isEmpty) {
      return const TPText(
        '無路線資訊',
        style: TPTextStyles.caption,
        color: TPColors.grayscale500,
      );
    }

    final path = _buildPath();
    if (path.isEmpty) {
      return const TPText(
        '無路線資訊',
        style: TPTextStyles.caption,
        color: TPColors.grayscale500,
      );
    }

    final currentIndex = _getCurrentIndex();
    final segmentProgress = _getSegmentProgress();

    return _AnimatedPathWidget(
      path: path,
      currentIndex: currentIndex,
      segmentProgress: segmentProgress,
    );
  }

  /// 格式化時間顯示
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// 建立控制按鈕
  Widget _buildControlButtons() {
    if (!_journeyStarted) {
      // 顯示「開始行程」按鈕
      return Center(
        child: ElevatedButton(
          onPressed: _startJourney,
          style: ElevatedButton.styleFrom(
            backgroundColor: TPColors.primary500,
            foregroundColor: TPColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const TPText(
            '開始行程',
            style: TPTextStyles.bodySemiBold,
            color: TPColors.white,
          ),
        ),
      );
    }

    if (_journeyCompleted) {
      return _buildCompletedMessage();
    }

    // 如果需要轉乘，顯示特殊的按鈕佈局
    if (_needsTransferAtCurrentStation && _currentTransferInfo != null) {
      return Column(
        children: [
          // 轉乘提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: TPColors.orange50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TPColors.orange300, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TPColors.orange100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.transfer_within_a_station,
                    color: TPColors.orange600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TPText(
                      '轉乘站：${_currentTransferInfo!.transferStation.name}',
                      style: TPTextStyles.bodySemiBold,
                      color: TPColors.orange700,
                    ),
                    const SizedBox(height: 2),
                    const TPText(
                      '請完成轉乘後點擊繼續',
                      style: TPTextStyles.caption,
                      color: TPColors.orange600,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 按鈕區域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 上一站按鈕
              ElevatedButton(
                onPressed: _currentLegIndex > 0 ? _previousStation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TPColors.grayscale300,
                  foregroundColor: TPColors.grayscale700,
                  disabledBackgroundColor: TPColors.grayscale100,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const TPText(
                  '上一站',
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.grayscale700,
                ),
              ),
              // 轉乘暫停/繼續按鈕
              ElevatedButton.icon(
                onPressed: _handleTransferPause,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTransferPaused 
                      ? TPColors.orange500 
                      : TPColors.primary500,
                  foregroundColor: TPColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                icon: Icon(
                  _isTransferPaused ? Icons.play_arrow : Icons.pause,
                  size: 20,
                ),
                label: TPText(
                  _isTransferPaused ? '繼續' : '暫停',
                  style: TPTextStyles.bodySemiBold,
                  color: TPColors.white,
                ),
              ),
              // 下一站按鈕
              ElevatedButton(
                onPressed: _nextStation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TPColors.primary500,
                  foregroundColor: TPColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const TPText(
                  '下一站',
                  style: TPTextStyles.bodySemiBold,
                  color: TPColors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 一般情況：顯示「上一站」和「下一站」按鈕
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _currentLegIndex > 0 ? _previousStation : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: TPColors.grayscale300,
            foregroundColor: TPColors.grayscale700,
            disabledBackgroundColor: TPColors.grayscale100,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: const TPText(
            '上一站',
            style: TPTextStyles.bodyRegular,
            color: TPColors.grayscale700,
          ),
        ),
        ElevatedButton(
          onPressed: _isAtFinalStation ? _completeJourney : _nextStation,
          style: ElevatedButton.styleFrom(
            backgroundColor: TPColors.primary500,
            foregroundColor: TPColors.white,
            disabledBackgroundColor: TPColors.grayscale100,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: TPText(
            _isAtFinalStation ? '完成旅程' : '下一站',
            style: TPTextStyles.bodySemiBold,
            color: TPColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedMessage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.flag_rounded,
            color: TPColors.primary500,
            size: 28,
          ),
          SizedBox(height: 8),
          TPText(
            '旅程完成，準備查看結果！',
            style: TPTextStyles.bodySemiBold,
            color: TPColors.primary500,
          ),
        ],
      ),
    );
  }
}

class _AnimatedPathWidget extends StatefulWidget {
  final List<MrtStation> path;
  final int currentIndex;
  final double segmentProgress;

  const _AnimatedPathWidget({
    required this.path,
    required this.currentIndex,
    required this.segmentProgress,
  });

  @override
  State<_AnimatedPathWidget> createState() => _AnimatedPathWidgetState();
}

class _AnimatedPathWidgetState extends State<_AnimatedPathWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _animatingIndex; // 当前正在播放动画的节点索引

  @override
  void initState() {
    super.initState();
    // 动画总时长为 0.5 秒，forward 和 reverse 各 0.25 秒
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    // 使用一个从1.0到0.7再到1.0的动画
    // 通过 forward 和 reverse 实现缩小再放大的效果
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(_AnimatedPathWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 currentIndex 改变时，触发动画
    if (oldWidget.currentIndex != widget.currentIndex) {
      _triggerAnimation(widget.currentIndex);
    }
  }

  void _triggerAnimation(int currentIndex) {
    // 取消之前的动画（如果有）
    _animationController.stop();
    _animationController.reset();
    
    setState(() {
      _animatingIndex = currentIndex;
    });
    
    // 先 forward（缩小到 0.7），然后 reverse（放大回 1.0）
    _animationController.forward(from: 0.0).then((_) {
      if (mounted && _animatingIndex == currentIndex) {
        _animationController.reverse().then((_) {
          if (mounted && _animatingIndex == currentIndex) {
            setState(() {
              _animatingIndex = null;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Return full station name (no truncation)
  String _truncateStationName(String name) {
    return name; // Return full name without truncation
  }

  /// 获取站在 path 中的索引
  int _getStationIndex(MrtStation? station, List<MrtStation> path) {
    if (station == null) return -1;
    for (int i = 0; i < path.length; i++) {
      if (path[i].id == station.id) {
        return i;
      }
    }
    return -1;
  }

  /// 检查两个站是否在 path 中是连续的（索引差为1）
  bool _areStationsConsecutive(MrtStation? station1, MrtStation? station2, List<MrtStation> path) {
    if (station1 == null || station2 == null) return false;
    final index1 = _getStationIndex(station1, path);
    final index2 = _getStationIndex(station2, path);
    if (index1 == -1 || index2 == -1) return false;
    return (index2 - index1).abs() == 1;
  }

  /// 绘制虚线
  Widget _buildDashedLine({Color color = TPColors.primary300, double height = 3}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 4.0;

        return CustomPaint(
          size: Size(constraints.maxWidth, height),
          painter: _DashedLinePainter(
            color: color,
            dashWidth: dashWidth,
            dashSpace: dashSpace,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    final currentIndex = widget.currentIndex;
    final pathLength = path.length;

    // Handle edge cases
    if (pathLength == 1) {
      return _buildSingleNode(path[0]);
    } else if (pathLength == 2) {
      return _buildTwoNodes(path, currentIndex);
    } else if (pathLength == 3) {
      return _buildThreeNodes(path, currentIndex);
    } else {
      return _buildFourNodes(path, currentIndex);
    }
  }

  Widget _buildSingleNode(MrtStation station) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNodeCircle(
            isActive: true,
            size: 1.0,
            nodeIndex: 0,
          ),
          const SizedBox(height: 8),
          TPText(
            _truncateStationName(station.name),
            style: TPTextStyles.caption,
            color: TPColors.grayscale700,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTwoNodes(List<MrtStation> path, int currentIndex) {
    return Row(
      children: [
        Expanded(
          child: _buildNode(
            station: path[0],
            isActive: currentIndex == 0,
            size: currentIndex == 0 ? 1.0 : 0.6,
            nodeIndex: 0,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 3,
            color: TPColors.primary300,
          ),
        ),
        Expanded(
          child: _buildNode(
            station: path[1],
            isActive: currentIndex == 1,
            size: currentIndex == 1 ? 1.0 : 0.6,
            nodeIndex: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildThreeNodes(List<MrtStation> path, int currentIndex) {
    return Row(
      children: [
        Expanded(
          child: _buildNode(
            station: path[0],
            isActive: currentIndex == 0,
            size: currentIndex == 0 ? 1.0 : 0.5,
            nodeIndex: 0,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 3,
            color: TPColors.primary300,
          ),
        ),
        Expanded(
          child: _buildNode(
            station: path[1],
            isActive: currentIndex == 1,
            size: currentIndex == 1 ? 1.0 : (currentIndex == 0 ? 0.8 : 0.5),
            nodeIndex: 1,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 3,
            color: TPColors.primary300,
          ),
        ),
        Expanded(
          child: _buildNode(
            station: path[2],
            isActive: currentIndex == 2,
            size: currentIndex == 2 ? 1.0 : 0.5,
            nodeIndex: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildFourNodes(List<MrtStation> path, int currentIndex) {
    // Determine which stations to show
    MrtStation? startStation;
    MrtStation? currentStation;
    MrtStation? nextStation;
    MrtStation? destinationStation;

    // Check if we're in the last 3 stations (last - 2, last - 1, last)
    // Or if last - 1 or last station is current - keep the same stations in middle-left and middle-right positions
    final isInLastThree = currentIndex >= path.length - 3;
    final isLastMinusOne = currentIndex == path.length - 2;
    final isLast = currentIndex >= path.length - 1;

    if (currentIndex == 0) {
      // At start - left shows start station, middle-left shows next station (like middle-right)
      startStation = path[0];
      currentStation = path.length > 1 ? path[1] : path[0]; // Next station in middle-left
      nextStation = path.length > 2 ? path[2] : null; // Station after next in middle-right
      destinationStation = path.length > 2 ? path[path.length - 1] : (path.length > 1 ? path[1] : path[0]);
    } else if (isInLastThree || isLastMinusOne || isLast) {
      // When in last 3 stations, at last - 1, or at last, keep positions fixed:
      // middle-left always shows last - 2, middle-right always shows last - 1
      startStation = path[0];
      if (path.length >= 3) {
        currentStation = path[path.length - 3]; // Last - 2 station in middle-left (fixed position)
        nextStation = path[path.length - 2]; // Last - 1 station in middle-right (fixed position)
      } else if (path.length >= 2) {
        currentStation = path[path.length - 2]; // Last - 1 station in middle-left if only 2 stations
        nextStation = null;
      } else {
        currentStation = path[0];
        nextStation = null;
      }
      destinationStation = path[path.length - 1];
    } else if (currentIndex > path.length - 1) {
      // After last stop - same as at last stop
      startStation = path[0];
      if (path.length >= 2) {
        currentStation = path[path.length - 2]; // Last - 2 station in middle-left (non-current)
      } else {
        currentStation = path[0]; // Fallback if path is too short
      }
      nextStation = null; // Don't show in middle-right
      destinationStation = path[path.length - 1]; // This will be shown in right node as current
    } else {
      // In the middle - left is inactive start, middle-left is current, middle-right is next
      startStation = path[0];
      currentStation = path[currentIndex];
      nextStation = currentIndex + 1 < path.length ? path[currentIndex + 1] : null;
      destinationStation = path[path.length - 1];
    }

    // Calculate node sizes
    // When middle-left is current: it should have same size as left node
    // All non-current nodes should have the same size (larger than before)
    final isRightNodeCurrent = currentIndex >= path.length - 1;
    final nonCurrentSize = 0.7; // Same size for all non-current nodes (increased from 0.4)
    final currentSize = currentIndex == 0 ? 1.0 : 1.0; // Current node same size as left node (1.0)
    // When right node is current, left node should be non-current
    final startSize = (currentIndex == 0 && !isRightNodeCurrent) ? 1.0 : nonCurrentSize;
    final nextSize = nonCurrentSize; // Same size for middle-right (non-current)
    final destinationSize = isRightNodeCurrent ? 1.0 : nonCurrentSize; // Large when reached, same as non-current otherwise

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row for nodes only - aligned horizontally
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Start station (left node) - active and large at start, inactive and small after
            // When right node is current (currentIndex >= path.length - 1), this should be non-current
            Expanded(
              child: Center(
                child: _buildNodeCircle(
                  isActive: currentIndex == 0 && currentIndex < path.length - 1, // Only active at start, not when right is current
                  size: startSize,
                  nodeIndex: 0, // Start station is always at index 0
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _areStationsConsecutive(startStation, currentStation, path)
                  ? Container(
                      height: 3,
                      color: TPColors.primary300,
                    )
                  : _buildDashedLine(color: TPColors.primary300, height: 3),
            ),
            // Middle-left: shows next station at start, shows current station after moving, shows previous station at last stop
            Expanded(
              child: Center(
                child: _buildMiddleLeftNodeCircle(
                  currentStation: currentStation,
                  currentIndex: currentIndex,
                  pathLength: path.length,
                  currentSize: currentSize,
                  nonCurrentSize: nonCurrentSize,
                  path: path,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                height: 3,
                color: TPColors.primary300,
              ),
            ),
            // Next station (middle-right) - should not show last station (only right node shows it)
            // Also should not show anything when at or after last stop
            // IMPORTANT: Never show as active/current - always isActive: false
            Expanded(
              child: Center(
                child: _buildMiddleRightNodeCircle(
                  nextStation: nextStation,
                  destinationStation: destinationStation,
                  currentIndex: currentIndex,
                  pathLength: path.length,
                  nextSize: nextSize,
                  path: path,
                ),
              ),
            ),
            // Show connecting line if middle-right node is visible
            // It should be visible when nextStation exists and is different from destination
            // Also show when at last station (currentIndex >= path.length - 1) if middle-right is showing
            if (nextStation != null &&
                nextStation.id != destinationStation.id &&
                currentIndex <= path.length - 1)
              Expanded(
                flex: 2,
                child: _areStationsConsecutive(nextStation, destinationStation, path)
                    ? Container(
                        height: 3,
                        color: TPColors.primary300,
                      )
                    : _buildDashedLine(color: TPColors.primary300, height: 3),
              ),
            // Destination (right) - becomes current when at last stop
            Expanded(
              child: Center(
                child: _buildNodeCircle(
                  isActive: currentIndex >= path.length - 1, // Active when at last stop
                  size: currentIndex >= path.length - 1 ? currentSize : destinationSize,
                  nodeIndex: path.length - 1, // Destination is always at last index
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Row for station names - aligned below their respective nodes
        Row(
          children: [
            Expanded(
              child: Center(
                child: _buildStationName(
                  station: startStation,
                  isActive: currentIndex == 0 && currentIndex < path.length - 1,
                ),
              ),
            ),
            Expanded(flex: 2, child: const SizedBox.shrink()),
            Expanded(
              child: Center(
                child: _buildStationName(
                  station: currentStation,
                  isActive: (currentIndex > 0 && currentIndex < path.length - 1) ||
                            (currentIndex == path.length - 3),
                ),
              ),
            ),
            Expanded(flex: 2, child: const SizedBox.shrink()),
            Expanded(
              child: Center(
                child: _buildStationName(
                  station: nextStation,
                  isActive: currentIndex == path.length - 2,
                ),
              ),
            ),
            if (nextStation != null &&
                nextStation.id != destinationStation.id &&
                currentIndex <= path.length - 1)
              Expanded(flex: 2, child: const SizedBox.shrink()),
            Expanded(
              child: Center(
                child: _buildStationName(
                  station: destinationStation,
                  isActive: currentIndex >= path.length - 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNode({
    required MrtStation station,
    required bool isActive,
    required double size,
    int? nodeIndex,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNodeCircle(
          isActive: isActive,
          size: size,
          nodeIndex: nodeIndex,
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: TPText(
            _truncateStationName(station.name),
            style: TPTextStyles.caption,
            color: isActive ? TPColors.grayscale900 : TPColors.grayscale600,
            maxLines: 1,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildNodeCircle({
    required bool isActive,
    required double size,
    int? nodeIndex,
  }) {
    Widget circleWidget = Container(
      width: 24,
      height: 24,
      decoration: isActive
          ? BoxDecoration(
              color: TPColors.primary500,
              shape: BoxShape.circle,
            )
          : BoxDecoration(
              color: TPColors.grayscale400,
              shape: BoxShape.circle,
              border: Border.all(
                color: TPColors.grayscale300,
                width: 2,
              ),
            ),
    );

    // 如果是当前节点且正在播放动画，应用动画缩放
    final shouldAnimate = isActive && 
        nodeIndex != null && 
        _animatingIndex != null && 
        nodeIndex == _animatingIndex;
    
    if (shouldAnimate) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          // 计算动画缩放值：从1.0缩小到0.7再回到1.0
          final animationScale = _scaleAnimation.value;
          // 基础缩放乘以动画缩放
          final totalScale = size * animationScale;
          return Transform.scale(
            scale: totalScale,
            child: circleWidget,
          );
        },
      );
    }

    // 不需要动画时，直接应用基础缩放
    return Transform.scale(
      scale: size,
      child: circleWidget,
    );
  }

  Widget _buildMiddleLeftNodeCircle({
    required MrtStation? currentStation,
    required int currentIndex,
    required int pathLength,
    required double currentSize,
    required double nonCurrentSize,
    required List<MrtStation> path,
  }) {
    final stationToShow = currentStation ?? (pathLength > 0 && path.isNotEmpty ? path[0] : null);
    if (stationToShow == null) {
      return const SizedBox.shrink();
    }

    // 找到当前站在 path 中的索引
    final nodeIndex = _getStationIndex(stationToShow, path);

    final isRightNodeCurrent = currentIndex >= pathLength - 1;
    if (isRightNodeCurrent) {
      return _buildNodeCircle(
        isActive: false,
        size: nonCurrentSize,
        nodeIndex: nodeIndex >= 0 ? nodeIndex : null,
      );
    }

    final isInLastThree = currentIndex >= pathLength - 3;
    final isLastMinusOne = currentIndex == pathLength - 2;
    final isLast = currentIndex >= pathLength - 1;
    if (isInLastThree || isLastMinusOne || isLast) {
      final isLastMinusTwo = currentIndex == pathLength - 3;
      return _buildNodeCircle(
        isActive: isLastMinusTwo,
        size: isLastMinusTwo ? currentSize : nonCurrentSize,
        nodeIndex: nodeIndex >= 0 ? nodeIndex : null,
      );
    }

    if (currentIndex == 0) {
      return _buildNodeCircle(
        isActive: false,
        size: nonCurrentSize,
        nodeIndex: nodeIndex >= 0 ? nodeIndex : null,
      );
    } else {
      return _buildNodeCircle(
        isActive: true,
        size: currentSize,
        nodeIndex: nodeIndex >= 0 ? nodeIndex : null,
      );
    }
  }

  Widget _buildMiddleRightNodeCircle({
    required MrtStation? nextStation,
    required MrtStation? destinationStation,
    required int currentIndex,
    required int pathLength,
    required double nextSize,
    required List<MrtStation> path,
  }) {
    if (nextStation == null ||
        destinationStation == null ||
        nextStation.id == destinationStation.id ||
        currentIndex > pathLength - 1) {
      return const SizedBox.shrink();
    }

    // 找到下一站在 path 中的索引
    final nodeIndex = _getStationIndex(nextStation, path);

    final isInLastThree = currentIndex >= pathLength - 3;
    final isLastMinusOne = currentIndex == pathLength - 2;
    final isLast = currentIndex >= pathLength - 1;
    if (isInLastThree || isLastMinusOne || isLast) {
      final shouldBeActive = isLastMinusOne && !isLast;
      return _buildNodeCircle(
        isActive: shouldBeActive,
        size: shouldBeActive ? 1.0 : nextSize,
        nodeIndex: nodeIndex >= 0 ? nodeIndex : null,
      );
    }

    return _buildNodeCircle(
      isActive: false,
      size: nextSize,
      nodeIndex: nodeIndex >= 0 ? nodeIndex : null,
    );
  }

  Widget _buildStationName({
    required MrtStation? station,
    required bool isActive,
  }) {
    if (station == null) {
      return const SizedBox.shrink();
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: TPText(
        _truncateStationName(station.name),
        style: TPTextStyles.caption,
        color: isActive ? TPColors.grayscale900 : TPColors.grayscale600,
        maxLines: 1,
        overflow: TextOverflow.visible,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 虚线绘制器
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  _DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..style = PaintingStyle.fill;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(startX, 0, dashWidth, size.height),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}



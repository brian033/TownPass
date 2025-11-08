import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:town_pass/bean/mrt_connection.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';
import 'package:town_pass/page/exercise_recommendation/widget/exercise_timer_card.dart';
import 'package:town_pass/page/exercise_recommendation/widget/exercise_info_card.dart';

class JourneyTrackerWidget extends StatefulWidget {
  const JourneyTrackerWidget({
    super.key,
    required this.routeResult,
    required this.timerCardKey,
    required this.exerciseInfoCardKey,
  });

  final MrtRouteResult routeResult;
  final GlobalKey<ExerciseTimerCardState> timerCardKey;
  final GlobalKey<ExerciseInfoCardState> exerciseInfoCardKey;

  @override
  State<JourneyTrackerWidget> createState() => JourneyTrackerWidgetState();
}

class JourneyTrackerWidgetState extends State<JourneyTrackerWidget> {
  int _currentLegIndex = 0;
  bool _journeyStarted = false;
  RecommendedExercise? _currentExercise;
  RecommendedExercise? _nextExercise;
  Timer? _autoProgressTimer;
  int _remainingSecondsToNextStation = 0;
  Timer? _countdownTimer;

  /// 對外提供當前運動的 getter
  RecommendedExercise? get currentExercise => _currentExercise;

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
      _currentLegIndex = 0;
    });

    _selectRandomExercises();
    _updateTimerCard();
    _startAutoProgressTimer();
  }

  /// 下一站
  void _nextStation() {
    if (_currentLegIndex < widget.routeResult.legs.length - 1) {
      setState(() {
        _currentLegIndex++;
      });
      _selectRandomExercises();
      _updateTimerCard();
      _startAutoProgressTimer();
    }
  }

  /// 上一站
  void _previousStation() {
    if (_currentLegIndex > 0) {
      setState(() {
        _currentLegIndex--;
      });
      _selectRandomExercises();
      _updateTimerCard();
      _startAutoProgressTimer();
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

  /// 更新 ExerciseTimerCard 和 ExerciseInfoCard
  void _updateTimerCard() {
    if (_currentExercise == null || _nextExercise == null) return;

    final currentLeg = widget.routeResult.legs[_currentLegIndex];
    final remainingSeconds = currentLeg.travelSeconds + currentLeg.stopSeconds;

    // 更新 ExerciseTimerCard
    widget.timerCardKey.currentState?.setDisplayCard(
      _currentExercise!.name,
      remainingSeconds,
      _nextExercise!.name,
    );

    // 更新 ExerciseInfoCard
    widget.exerciseInfoCardKey.currentState?.setExercise(_currentExercise!);
  }

  /// 啟動自動進站計時器和倒數計時器
  void _startAutoProgressTimer() {
    _autoProgressTimer?.cancel();
    _countdownTimer?.cancel();

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
      if (_currentLegIndex < widget.routeResult.legs.length - 1) {
        _nextStation();
      }
    });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TPText(
                '旅程追蹤',
                style: TPTextStyles.bodySemiBold,
                color: TPColors.grayscale900,
              ),
              if (_journeyStarted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TPColors.primary50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TPColors.primary200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: TPColors.primary500,
                      ),
                      const SizedBox(width: 4),
                      TPText(
                        _formatTime(_remainingSecondsToNextStation),
                        style: TPTextStyles.caption,
                        color: TPColors.primary500,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(),
          const SizedBox(height: 16),
          _buildControlButtons(),
        ],
      ),
    );
  }

  /// 建立橫向站點進度條
  Widget _buildProgressBar() {
    if (widget.routeResult.legs.isEmpty) {
      return const TPText(
        '無路線資訊',
        style: TPTextStyles.caption,
        color: TPColors.grayscale500,
      );
    }

    // 決定顯示範圍
    final legs = widget.routeResult.legs;
    int startIndex, endIndex;

    if (_currentLegIndex == 0) {
      // 開頭：顯示前 2-3 個 leg
      startIndex = 0;
      endIndex = min(2, legs.length - 1);
    } else if (_currentLegIndex == legs.length - 1) {
      // 結尾：顯示最後 2-3 個 leg
      startIndex = max(0, legs.length - 3);
      endIndex = legs.length - 1;
    } else {
      // 中間：顯示當前 leg 和前後各一個
      startIndex = max(0, _currentLegIndex - 1);
      endIndex = min(legs.length - 1, _currentLegIndex + 1);
    }

    // 收集要顯示的站點
    List<String> stationNames = [];
    for (int i = startIndex; i <= endIndex; i++) {
      if (i == startIndex) {
        stationNames.add(legs[i].fromStation.name);
      }
      stationNames.add(legs[i].toStation.name);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < stationNames.length; i++) ...[
            _buildStationDot(
              stationNames[i],
              isActive: _journeyStarted && i <= (_currentLegIndex - startIndex + 1),
            ),
            if (i < stationNames.length - 1)
              _buildConnector(
                isActive: _journeyStarted && i < (_currentLegIndex - startIndex + 1),
              ),
          ],
        ],
      ),
    );
  }

  /// 建立站點圓點
  Widget _buildStationDot(String stationName, {required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? TPColors.primary500 : TPColors.grayscale300,
          ),
        ),
        const SizedBox(height: 4),
        TPText(
          stationName,
          style: TPTextStyles.caption,
          color: isActive ? TPColors.primary500 : TPColors.grayscale600,
        ),
      ],
    );
  }

  /// 建立連接線
  Widget _buildConnector({required bool isActive}) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 28),
      color: isActive ? TPColors.primary500 : TPColors.grayscale300,
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

    // 顯示「上一站」和「下一站」按鈕
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
          onPressed: _currentLegIndex < widget.routeResult.legs.length - 1
              ? _nextStation
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: TPColors.primary500,
            foregroundColor: TPColors.white,
            disabledBackgroundColor: TPColors.grayscale100,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: const TPText(
            '下一站',
            style: TPTextStyles.bodySemiBold,
            color: TPColors.white,
          ),
        ),
      ],
    );
  }
}


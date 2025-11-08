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
    if (_currentLegIndex < widget.routeResult.legs.length) {
      setState(() {
        _currentLegIndex++;
      });

      // 如果已經抵達終點，不需要更新運動和計時器
      if (_currentLegIndex < widget.routeResult.legs.length) {
        _selectRandomExercises();
        _updateTimerCard();
        _startAutoProgressTimer();
      } else {
        // 抵達終點，停止計時器
        _autoProgressTimer?.cancel();
        _countdownTimer?.cancel();
      }
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
              if (_journeyStarted && _currentLegIndex < widget.routeResult.legs.length)
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
              if (_journeyStarted && _currentLegIndex == widget.routeResult.legs.length)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TPColors.primary50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TPColors.primary200),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: TPColors.primary500,
                      ),
                      SizedBox(width: 4),
                      TPText(
                        '已抵達',
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

    final legs = widget.routeResult.legs;

    // 收集所有站點名稱和索引
    final List<String> allStationNames = [];
    for (int i = 0; i < legs.length; i++) {
      if (i == 0) {
        allStationNames.add(legs[i].fromStation.name);
      }
      allStationNames.add(legs[i].toStation.name);
    }

    final totalStations = allStationNames.length;

    // 如果站點數 <= 4，全部顯示
    if (totalStations <= 4) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < totalStations; i++) ...[
            _buildStationDot(
              allStationNames[i],
              isActive: _journeyStarted && i <= _currentLegIndex,
              isCurrent: _journeyStarted && i == _currentLegIndex,
            ),
            if (i < totalStations - 1)
              Expanded(
                child: _buildConnector(
                  isActive: _journeyStarted && i < _currentLegIndex,
                ),
              ),
          ],
        ],
      );
    }

    // 站點數 > 4：固定顯示起點、終點，中間顯示2個站點
    final List<int> visibleIndices = [];
    final List<String> visibleNames = [];

    // 永遠顯示起點
    visibleIndices.add(0);
    visibleNames.add(allStationNames[0]);

    // 中間2個站點：顯示當前站點和下一個站點（但排除起點和終點）
    final int currentStationIndex = _currentLegIndex;
    final int nextStationIndex = _currentLegIndex + 1;

    if (currentStationIndex == 0) {
      // 如果當前在起點，中間顯示站點 1, 2
      visibleIndices.addAll([1, 2]);
      visibleNames.addAll([allStationNames[1], allStationNames[2]]);
    } else if (currentStationIndex >= totalStations - 1) {
      // 已抵達終點或接近終點，固定顯示倒數第二、第三個站點
      final middleIndex1 = totalStations - 3;
      final middleIndex2 = totalStations - 2;
      visibleIndices.addAll([middleIndex1, middleIndex2]);
      visibleNames.addAll([allStationNames[middleIndex1], allStationNames[middleIndex2]]);
    } else if (nextStationIndex < totalStations - 1) {
      // 當前站點和下一個站點都不是終點，顯示它們
      visibleIndices.addAll([currentStationIndex, nextStationIndex]);
      visibleNames.addAll([allStationNames[currentStationIndex], allStationNames[nextStationIndex]]);
    } else {
      // 接近終點時，固定顯示倒數第二、第三個站點
      final middleIndex1 = totalStations - 3;
      final middleIndex2 = totalStations - 2;
      visibleIndices.addAll([middleIndex1, middleIndex2]);
      visibleNames.addAll([allStationNames[middleIndex1], allStationNames[middleIndex2]]);
    }

    // 永遠顯示終點
    visibleIndices.add(totalStations - 1);
    visibleNames.add(allStationNames[totalStations - 1]);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < visibleNames.length; i++) ...[
          _buildStationDot(
            visibleNames[i],
            isActive: _journeyStarted && visibleIndices[i] <= _currentLegIndex,
            isCurrent: _journeyStarted && visibleIndices[i] == _currentLegIndex,
          ),
          if (i < visibleNames.length - 1)
            Expanded(
              child: _buildConnector(
                isActive: _journeyStarted &&
                  visibleIndices[i] < _currentLegIndex,
              ),
            ),
        ],
      ],
    );
  }

  /// 建立站點圓點
  Widget _buildStationDot(
    String stationName, {
    required bool isActive,
    required bool isCurrent,
  }) {
    return SizedBox(
      width: 70, // 固定寬度避免抖動
      child: Column(
        children: [
          Container(
            width: isCurrent ? 16 : 12,
            height: isCurrent ? 16 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? TPColors.primary500 : TPColors.grayscale300,
            ),
          ),
          const SizedBox(height: 4),
          TPText(
            stationName,
            style: isCurrent
              ? TPTextStyles.caption
              : TPTextStyles.caption.copyWith(fontSize: 10),
            color: isCurrent ? TPColors.primary500 : TPColors.grayscale400,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 建立連接線
  Widget _buildConnector({required bool isActive}) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 28, left: 4, right: 4),
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
          onPressed: _currentLegIndex < widget.routeResult.legs.length
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


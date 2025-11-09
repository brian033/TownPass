import 'dart:async';
import 'package:flutter/material.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class ExerciseTimerCard extends StatefulWidget {
  const ExerciseTimerCard({super.key});

  @override
  State<ExerciseTimerCard> createState() => ExerciseTimerCardState();
}

class ExerciseTimerCardState extends State<ExerciseTimerCard> {
  String? _currentExercise;
  int? _remainingSeconds;
  Timer? _timer;
  bool _isTimerFinished = false;
  bool _showFinalMessage = false;
  bool _isPaused = false;

  /// 清空顯示內容
  void clear({bool showFinalMessage = false}) {
    _timer?.cancel();
    setState(() {
      _currentExercise = null;
      _remainingSeconds = null;
      _isTimerFinished = false;
      _showFinalMessage = showFinalMessage;
    });
  }

  /// 設置卡片顯示內容並開始倒數計時
  void setDisplayCard(String currentExercise, int remainingSeconds) {
    // 取消之前的計時器
    _timer?.cancel();

    setState(() {
      _currentExercise = currentExercise;
      _remainingSeconds = remainingSeconds;
      _isTimerFinished = false;
      _showFinalMessage = false;
      _isPaused = false; // 重置暂停状态
    });

    // 開始倒數計時
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) {
        return; // 如果暂停，不更新计时器
      }
      if (_remainingSeconds != null && _remainingSeconds! > 0) {
        setState(() {
          _remainingSeconds = _remainingSeconds! - 1;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerFinished = true;
        });
      }
    });
  }

  /// 暂停计时器
  void pauseTimer() {
    if (_isPaused) return;
    setState(() {
      _isPaused = true;
    });
    // 计时器继续运行，但不会更新显示
  }

  /// 继续计时器
  void resumeTimer() {
    if (!_isPaused) return;
    setState(() {
      _isPaused = false;
    });
    // 计时器继续运行，恢复更新显示
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes 分 ${secs.toString().padLeft(2, '0')} 秒';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果尚未設置內容，顯示預設狀態
    if (_currentExercise == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TPColors.primary50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TPColors.primary200,
            width: 1,
          ),
        ),
        child: Center(
          child: TPText(
            _showFinalMessage
                ? '已抵達最後一站，請點選完成旅程結束本次捷運動'
                : '等待運動開始...',
            style: TPTextStyles.bodyRegular,
            color: _showFinalMessage
                ? TPColors.primary500
                : TPColors.grayscale500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TPColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TPColors.primary200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 當前運動
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              TPText(
                '當前運動',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale700,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: TPText(
              _currentExercise!,
              style: TPTextStyles.h3SemiBold,
              color: TPColors.grayscale900,
            ),
          ),
          const SizedBox(height: 16),

          // 剩餘時間或完成訊息
          Row(
            children: [
              const Icon(
                Icons.timer,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              TPText(
                '剩餘時間',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale700,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: TPText(
              _isTimerFinished ? '休息一下吧～' : _formatTime(_remainingSeconds!),
              style: TPTextStyles.h3SemiBold,
              color: _isTimerFinished
                  ? TPColors.secondary500
                  : TPColors.primary500,
            ),
          ),
          const SizedBox(height: 12),

          // 下一個運動
          //   Row(
          //     children: [
          //       const Icon(
          //         Icons.next_plan,
          //         color: TPColors.primary500,
          //         size: 20,
          //       ),
          //       const SizedBox(width: 8),
          //       TPText(
          //         '接下來',
          //         style: TPTextStyles.bodyRegular,
          //         color: TPColors.grayscale700,
          //       ),
          //     ],
          //   ),
          //   const SizedBox(height: 8),
          //   Padding(
          //     padding: const EdgeInsets.only(left: 28),
          //     child: TPText(
          //       _nextExercise!,
          //       style: TPTextStyles.bodySemiBold,
          //       color: TPColors.grayscale900,
          //     ),
          //   ),
          //
        ],
      ),
    );
  }
}

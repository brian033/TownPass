import 'package:flutter/material.dart';
import 'package:town_pass/bean/mrt_connection.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class ExerciseInfoCard extends StatefulWidget {
  const ExerciseInfoCard({super.key});

  @override
  State<ExerciseInfoCard> createState() => ExerciseInfoCardState();
}

class ExerciseInfoCardState extends State<ExerciseInfoCard> {
  RecommendedExercise? _currentExercise;

  /// 設定當前運動並更新顯示
  void setExercise(RecommendedExercise exercise) {
    setState(() {
      _currentExercise = exercise;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentExercise == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: TPColors.grayscale50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TPColors.grayscale200),
        ),
        child: const Center(
          child: TPText(
            '請點擊「開始行程」開始運動',
            style: TPTextStyles.bodyRegular,
            color: TPColors.grayscale500,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TPColors.grayscale200),
        boxShadow: [
          BoxShadow(
            color: TPColors.grayscale200.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圖片
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              _currentExercise!.media,
              fit: BoxFit.fitHeight,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  color: TPColors.grayscale100,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(TPColors.primary500),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // 圖片載入失敗時顯示 fallback
                return Container(
                  color: TPColors.grayscale100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: TPColors.grayscale400,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        TPText(
                          _currentExercise!.name,
                          style: TPTextStyles.caption,
                          color: TPColors.grayscale500,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 資訊
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TPText(
                  _currentExercise!.name,
                  style: TPTextStyles.h3SemiBold,
                  color: TPColors.grayscale900,
                ),
                const SizedBox(height: 8),
                TPText(
                  _currentExercise!.description,
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.grayscale600,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _currentExercise!.doInCrowded
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: _currentExercise!.doInCrowded
                          ? TPColors.secondary500
                          : TPColors.grayscale400,
                    ),
                    const SizedBox(width: 4),
                    TPText(
                      _currentExercise!.doInCrowded ? '適合擁擠環境' : '需要較大空間',
                      style: TPTextStyles.caption,
                      color: TPColors.grayscale600,
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: TPColors.secondary500,
                    ),
                    const SizedBox(width: 4),
                    TPText(
                      '${_currentExercise!.calPerSec} 卡/秒',
                      style: TPTextStyles.caption,
                      color: TPColors.grayscale600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

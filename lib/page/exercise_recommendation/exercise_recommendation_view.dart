import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/exercise_recommendation/exercise_recommendation_controller.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class ExerciseRecommendationView extends StatelessWidget {
  ExerciseRecommendationView({super.key});

  final controller = Get.put(ExerciseRecommendationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TPColors.white,
      appBar: const TPAppBar(
        title: '運動推薦',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TPText(
              '您的旅程',
              style: TPTextStyles.h3SemiBold,
              color: TPColors.grayscale900,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 24),
            TPText(
              '推薦運動',
              style: TPTextStyles.h3SemiBold,
              color: TPColors.grayscale900,
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: Center(
                child: TPText(
                  '運動推薦功能開發中...',
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.grayscale500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
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
          Row(
            children: [
              const Icon(
                Icons.train,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              TPText(
                '${controller.startStation.name} → ${controller.endStation.name}',
                style: TPTextStyles.bodySemiBold,
                color: TPColors.grayscale900,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              TPText(
                '預估時間：${controller.estimatedMinutes} 分鐘',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale700,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              TPText(
                '運動部位：${controller.bodyPart.name}',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}


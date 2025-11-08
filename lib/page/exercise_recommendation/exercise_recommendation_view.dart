import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/exercise_recommendation/exercise_recommendation_controller.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class ExerciseRecommendationView extends StatefulWidget {
  const ExerciseRecommendationView({super.key});

  @override
  State<ExerciseRecommendationView> createState() => _ExerciseRecommendationViewState();
}

class _ExerciseRecommendationViewState extends State<ExerciseRecommendationView> {
  final controller = Get.put(ExerciseRecommendationController());
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    // 每秒調用一次 function B，以便秒數顯示能即時更新
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      controller.getCurrentStatus();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TPColors.white,
      appBar: const TPAppBar(
        title: '運動推薦',
      ),
      body: SingleChildScrollView(
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
            Container(
              height: 200,
              alignment: Alignment.center,
              child: TPText(
                '運動推薦功能開發中...',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale500,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatusWidget(),
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

  Widget _buildStatusWidget() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TPColors.grayscale50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TPColors.grayscale200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TPText(
            '即時狀態',
            style: TPTextStyles.bodySemiBold,
            color: TPColors.grayscale900,
          ),
          const SizedBox(height: 12),
          if (controller.currentLocation.value != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: TPColors.primary500,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TPText(
                    '當前位置：${controller.currentLocation.value!.name}',
                    style: TPTextStyles.bodyRegular,
                    color: TPColors.grayscale700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Icon(
                Icons.timer,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TPText(
                  '剩餘時間：${controller.remainingTimeFormatted}',
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.grayscale700,
                ),
              ),
            ],
          ),
          if (controller.currentMovement.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.directions_run,
                  color: TPColors.primary500,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TPText(
                    '當前運動：${controller.currentMovement.value}',
                    style: TPTextStyles.bodyRegular,
                    color: TPColors.grayscale700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ));
  }
}

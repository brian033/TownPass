import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/exercise_result/exercise_result_view.dart';
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: controller.loadSampleExercises,
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('載入範例運動'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TPColors.primary500,
                  foregroundColor: TPColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: TPTextStyles.bodySemiBold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(TPColors.primary500),
                    ),
                  );
                }

                final exercise = controller.exercise.value;

                if (exercise == null) {
                  return const Center(
                    child: TPText(
                      '目前尚未有推薦的運動，請先載入範例資料。',
                      style: TPTextStyles.bodyRegular,
                      color: TPColors.grayscale500,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: _buildExerciseCard(exercise),
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final sampleData = ExerciseResultData(
                    startStation: '捷運北門站',
                    endStation: '公館',
                    totalDuration: const Duration(minutes: 38),
                    venues: const [],
                  );

                  Get.to(() => ExerciseResultView(initialData: sampleData));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TPColors.primary500,
                  foregroundColor: TPColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: TPTextStyles.bodySemiBold,
                ),
                child: const Text('查看運動結果'),
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

  Widget _buildExerciseCard(ExerciseRecommendation exercise) {
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
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              exercise.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  color: TPColors.grayscale100,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(TPColors.primary500),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: TPColors.grayscale100,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: TPColors.grayscale400,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TPText(
                  exercise.name,
                  style: TPTextStyles.bodySemiBold,
                  color: TPColors.grayscale900,
                ),
                const SizedBox(height: 8),
                TPText(
                  exercise.description,
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.grayscale600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
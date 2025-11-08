import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/mrt_connection.dart';
import 'package:town_pass/page/exercise_recommendation/exercise_recommendation_controller.dart';
import 'package:town_pass/page/exercise_recommendation/widget/exercise_timer_card.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class ExerciseRecommendationView extends StatelessWidget {
  ExerciseRecommendationView({super.key});

  final controller = Get.put(ExerciseRecommendationController());
  final GlobalKey<ExerciseTimerCardState> _timerCardKey =
      GlobalKey<ExerciseTimerCardState>();

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
              '捷運路線',
              style: TPTextStyles.h3SemiBold,
              color: TPColors.grayscale900,
            ),
            const SizedBox(height: 16),
            _buildRouteSection(),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: TPTextStyles.bodySemiBold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ExerciseTimerCard(key: _timerCardKey),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(TPColors.primary500),
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
              return _buildExerciseCard(exercise);
            }),
            const SizedBox(height: 16),
            // 測試按鈕 (之後要移除)
            ElevatedButton(
              onPressed: () {
                _timerCardKey.currentState?.setDisplayCard(
                  '深蹲',
                  100,
                  '伏地挺身',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TPColors.primary500,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const TPText(
                '測試開始運動 (Mock)',
                style: TPTextStyles.bodyRegular,
                color: TPColors.white,
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(TPColors.primary500),
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

  Widget _buildRouteSection() {
    final route = controller.routeResult;
    if (route == null || route.legs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TPColors.grayscale50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TPColors.grayscale100,
          ),
        ),
        child: const TPText(
          '目前無法取得捷運路線資訊，請返回重新選擇站點。',
          style: TPTextStyles.bodyRegular,
          color: TPColors.grayscale600,
        ),
      );
    }

    final legs = route.legs;
    return Column(
      children: [
        for (var i = 0; i < legs.length; i++) ...[
          _RouteLegTile(
            leg: legs[i],
            departureSeconds: i == 0 ? 0 : legs[i - 1].cumulativeSeconds,
          ),
          if (i != legs.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RouteLegTile extends StatelessWidget {
  const _RouteLegTile({
    required this.leg,
    required this.departureSeconds,
  });

  final MrtRouteLeg leg;
  final int departureSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TPColors.primary100),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TPText(
                  '${leg.fromStation.name} → ${leg.toStation.name}',
                  style: TPTextStyles.bodySemiBold,
                  color: TPColors.grayscale900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TPText(
            '路線：${leg.lineName}',
            style: TPTextStyles.caption,
            color: TPColors.grayscale600,
          ),
          const SizedBox(height: 8),
          TPText(
            '出發時間：${_formatSeconds(departureSeconds)} · 抵達時間：${_formatSeconds(leg.cumulativeSeconds)}',
            style: TPTextStyles.caption,
            color: TPColors.grayscale600,
          ),
          const SizedBox(height: 8),
          TPText(
            '行駛 ${_formatSeconds(leg.travelSeconds)} · 停靠 ${_formatSeconds(leg.stopSeconds)}',
            style: TPTextStyles.caption,
            color: TPColors.grayscale600,
          ),
        ],
      ),
    );
  }

  static String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (minutes == 0) {
      return '${remaining}秒';
    }
    if (remaining == 0) {
      return '${minutes}分鐘';
    }
    return '${minutes}分${remaining}秒';
  }
}

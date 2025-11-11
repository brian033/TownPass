import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/mrt_connection.dart';
import 'package:town_pass/bean/mrt_station.dart';
import 'package:town_pass/bean/exercise_history.dart';
import 'package:town_pass/page/exercise_recommendation/exercise_recommendation_controller.dart';
import 'package:town_pass/page/exercise_recommendation/widget/exercise_timer_card.dart';
import 'package:town_pass/page/exercise_recommendation/widget/exercise_info_card.dart';
import 'package:town_pass/page/exercise_recommendation/widget/journey_tracker_widget.dart';
import 'package:town_pass/page/exercise_result/exercise_result_view.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class ExerciseRecommendationView extends StatefulWidget {
  const ExerciseRecommendationView({super.key});

  @override
  State<ExerciseRecommendationView> createState() =>
      _ExerciseRecommendationViewState();
}

class _ExerciseRecommendationViewState
    extends State<ExerciseRecommendationView> {
  final controller = Get.put(ExerciseRecommendationController());
  final GlobalKey<ExerciseTimerCardState> _timerCardKey =
      GlobalKey<ExerciseTimerCardState>();
  final GlobalKey<ExerciseInfoCardState> _exerciseInfoCardKey =
      GlobalKey<ExerciseInfoCardState>();
  final GlobalKey<JourneyTrackerWidgetState> _journeyTrackerKey =
      GlobalKey<JourneyTrackerWidgetState>();
  Timer? _statusTimer;

  bool _isRouteExpanded = false; // 捷運路線摺疊狀態
  bool _hasNavigatedToResult = false;

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
            // _buildInfoCard(),
            // const SizedBox(height: 24),
            // _buildDebugExercisesCard(),
            // const SizedBox(height: 24),
            if (controller.routeResult != null)
              JourneyTrackerWidget(
                key: _journeyTrackerKey,
                routeResult: controller.routeResult!,
                timerCardKey: _timerCardKey,
                exerciseInfoCardKey: _exerciseInfoCardKey,
                onJourneyCompleted: _handleJourneyCompleted,
              ),
            const SizedBox(height: 24),
            TPText(
              '推薦運動',
              style: TPTextStyles.h3SemiBold,
              color: TPColors.grayscale900,
            ),
            const SizedBox(height: 16),
            ExerciseTimerCard(key: _timerCardKey),
            const SizedBox(height: 16),
            ExerciseInfoCard(key: _exerciseInfoCardKey),
          ],
        ),
      ),
    );
  }

  void _handleJourneyCompleted(
      Duration totalDuration, List<ExerciseRecord> exercises) {
    if (_hasNavigatedToResult) {
      return;
    }

    final route = controller.routeResult;
    if (route == null) {
      return;
    }

    _hasNavigatedToResult = true;
    final pointsEarned = route.legs.length;

    // 使用實際運動紀錄計算總時長與總卡路里
    final totalDurationSeconds =
        exercises.fold<int>(0, (sum, exercise) => sum + exercise.duration);
    final actualDuration = totalDurationSeconds > 0
        ? Duration(seconds: totalDurationSeconds)
        : totalDuration;
    final totalCalories =
        exercises.fold<int>(0, (sum, exercise) => sum + exercise.calories);

    // 儲存運動歷史紀錄
    controller.saveExerciseRecord(
      exercises: exercises,
      totalCalories: totalCalories,
      totalDuration:
          totalDurationSeconds > 0 ? totalDurationSeconds : totalDuration.inSeconds,
    );

    final resultData = ExerciseResultData(
      startStation: controller.startStation.name,
      endStation: controller.endStation.name,
      totalDuration: actualDuration,
      venues: const [],
      points: pointsEarned,
      calories: totalCalories,
      exerciseHistory: exercises,
    );

    Get.off(() => ExerciseResultView(initialData: resultData));
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.fitness_center,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TPText(
                  '運動部位：${controller.bodyPartsDisplayName}',
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.grayscale700,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebugExercisesCard() {
    final exercises = controller.routeResult?.exercises ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TPColors.grayscale100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TPColors.grayscale300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bug_report,
                color: TPColors.grayscale700,
                size: 20,
              ),
              const SizedBox(width: 8),
              TPText(
                'DEBUG: 推薦運動資料 (${exercises.length} 項)',
                style: TPTextStyles.bodySemiBold,
                color: TPColors.grayscale900,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (exercises.isEmpty)
            const TPText(
              '無推薦運動資料',
              style: TPTextStyles.bodyRegular,
              color: TPColors.grayscale600,
            )
          else
            ...exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index > 0) const Divider(height: 24),
                  TPText(
                    '${index + 1}. ${exercise.name}',
                    style: TPTextStyles.bodySemiBold,
                    color: TPColors.grayscale900,
                  ),
                  const SizedBox(height: 8),
                  TPText(
                    'calPerSec: ${exercise.calPerSec}',
                    style: TPTextStyles.caption,
                    color: TPColors.grayscale700,
                  ),
                  const SizedBox(height: 4),
                  TPText(
                    'doInCrowded: ${exercise.doInCrowded}',
                    style: TPTextStyles.caption,
                    color: TPColors.grayscale700,
                  ),
                  const SizedBox(height: 4),
                  TPText(
                    'parts: [${exercise.parts.join(", ")}]',
                    style: TPTextStyles.caption,
                    color: TPColors.grayscale700,
                  ),
                  const SizedBox(height: 4),
                  TPText(
                    'media: ${exercise.media}',
                    style: TPTextStyles.caption,
                    color: TPColors.grayscale700,
                  ),
                  const SizedBox(height: 4),
                  TPText(
                    'description: ${exercise.description}',
                    style: TPTextStyles.caption,
                    color: TPColors.grayscale700,
                  ),
                ],
              );
            }).toList(),
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

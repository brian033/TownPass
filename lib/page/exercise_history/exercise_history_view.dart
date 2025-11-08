import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/exercise_history.dart';
import 'package:town_pass/page/exercise_history/exercise_history_controller.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class ExerciseHistoryView extends StatelessWidget {
  const ExerciseHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExerciseHistoryController());

    return Scaffold(
      backgroundColor: TPColors.grayscale50,
      appBar: TPAppBar(
        title: '運動歷史',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 24),
            onPressed: controller.refresh,
            tooltip: '重新整理',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 24),
            onSelected: (value) {
              if (value == 'clear') {
                controller.clearAllHistories();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: TPColors.red500, size: 20),
                    SizedBox(width: 12),
                    Text('清空所有紀錄'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refresh();
        },
        child: Obx(() {
          if (controller.isLoading.value && controller.histories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TPColors.primary500),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // 統計卡片
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildStatisticsCard(controller),
                ),
              ),

              // 歷史紀錄列表
              Obx(() {
                if (controller.histories.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: TPColors.grayscale100,
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              size: 60,
                              color: TPColors.grayscale400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TPText(
                            '尚無運動紀錄',
                            style: TPTextStyles.h3SemiBold,
                            color: TPColors.grayscale600,
                          ),
                          const SizedBox(height: 8),
                          TPText(
                            '完成運動後會自動記錄在此',
                            style: TPTextStyles.bodyRegular,
                            color: TPColors.grayscale400,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final history = controller.histories[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildHistoryCard(history, controller),
                        );
                      },
                      childCount: controller.histories.length,
                    ),
                  ),
                );
              }),

              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatisticsCard(ExerciseHistoryController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TPColors.primary500, TPColors.primary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TPColors.primary500.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TPText(
            '運動統計',
            style: TPTextStyles.h3SemiBold,
            color: TPColors.white,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.emoji_events_rounded,
                  label: '運動次數',
                  value: '${controller.totalCount}',
                  unit: '次',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: TPColors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department_rounded,
                  label: '消耗熱量',
                  value: '${controller.totalCalories}',
                  unit: '卡',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: TPColors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer_rounded,
                  label: '運動時間',
                  value: '${controller.totalDuration}',
                  unit: '分',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Icon(icon, color: TPColors.white, size: 24),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            TPText(
              value,
              style: TPTextStyles.h2SemiBold,
              color: TPColors.white,
            ),
            const SizedBox(width: 2),
            TPText(
              unit,
              style: TPTextStyles.caption,
              color: TPColors.white.withOpacity(0.8),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TPText(
          label,
          style: TPTextStyles.caption,
          color: TPColors.white.withOpacity(0.9),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
    ExerciseHistory history,
    ExerciseHistoryController controller,
  ) {
    return Dismissible(
      key: Key(history.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('確認刪除'),
            content: const Text('確定要刪除這筆運動紀錄嗎？'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                style: TextButton.styleFrom(
                  foregroundColor: TPColors.red500,
                ),
                child: const Text('刪除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        controller.deleteHistory(history.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [TPColors.red400, TPColors.red600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_rounded,
              color: TPColors.white,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              '刪除',
              style: TextStyle(
                color: TPColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TPColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TPColors.grayscale200),
          boxShadow: [
            BoxShadow(
              color: TPColors.grayscale200.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [TPColors.primary400, TPColors.primary600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_subway_rounded,
                    color: TPColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TPText(
                        history.routeDisplay,
                        style: TPTextStyles.bodySemiBold,
                        color: TPColors.grayscale900,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: TPColors.grayscale500,
                          ),
                          const SizedBox(width: 4),
                          TPText(
                            history.dateDisplay,
                            style: TPTextStyles.caption,
                            color: TPColors.grayscale500,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: TPColors.white,
                      ),
                      const SizedBox(width: 4),
                      TPText(
                        '${history.totalCalories}',
                        style: TPTextStyles.bodySemiBold,
                        color: TPColors.white,
                      ),
                      const SizedBox(width: 2),
                      const TPText(
                        '卡',
                        style: TPTextStyles.caption,
                        color: TPColors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (history.bodyPartName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: TPColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TPColors.primary100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.accessibility_new_rounded,
                      size: 16,
                      color: TPColors.primary500,
                    ),
                    const SizedBox(width: 6),
                    TPText(
                      history.bodyPartName!,
                      style: TPTextStyles.caption,
                      color: TPColors.primary700,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: TPColors.grayscale200),
            const SizedBox(height: 12),
            TPText(
              '運動項目 (${history.exercises.length})',
              style: TPTextStyles.bodySemiBold,
              color: TPColors.grayscale700,
            ),
            const SizedBox(height: 8),
            ...history.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < history.exercises.length - 1 ? 6 : 0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [TPColors.primary400, TPColors.primary600],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TPText(
                        exercise.exerciseName,
                        style: TPTextStyles.bodyRegular,
                        color: TPColors.grayscale800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: TPColors.grayscale100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: TPColors.grayscale600,
                          ),
                          const SizedBox(width: 4),
                          TPText(
                            exercise.durationDisplay,
                            style: TPTextStyles.caption,
                            color: TPColors.grayscale600,
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.whatshot,
                            size: 12,
                            color: TPColors.orange500,
                          ),
                          const SizedBox(width: 2),
                          TPText(
                            '${exercise.calories}',
                            style: TPTextStyles.caption,
                            color: TPColors.grayscale600,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/mrt_station.dart';
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
    return Obx(() {
      if (controller.path.isEmpty || controller.currentLocation.value == null) {
        return Container(
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
              TPText(
                '等待路徑資料...',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale500,
              ),
            ],
          ),
        );
      }

      return Container(
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
            const SizedBox(height: 24),
            _buildPathVisualization(),
          ],
        ),
      );
    });
  }

  Widget _buildPathVisualization() {
    return Obx(() {
      final path = controller.path;
      final currentLocation = controller.currentLocation.value;
      
      if (path.isEmpty || currentLocation == null) {
        return const SizedBox.shrink();
      }

      // Find current index
      int currentIndex = path.indexWhere((station) => station.id == currentLocation.id);
      if (currentIndex == -1) currentIndex = 0;

      // Calculate progress in current segment (0.0 to 1.0)
      final remainingSeconds = controller.remainingTimeSeconds.value;
      double segmentProgress = 0.0;
      
      if (currentIndex < controller.estimatedMinutesList.length) {
        final segmentSeconds = (controller.estimatedMinutesList[currentIndex] * 60).round();
        if (segmentSeconds > 0) {
          segmentProgress = 1.0 - (remainingSeconds / segmentSeconds);
        }
      }

      return SizedBox(
        height: 120,
        child: _AnimatedPathWidget(
          path: path,
          currentIndex: currentIndex,
          segmentProgress: segmentProgress,
        ),
      );
    });
  }
}

class _AnimatedPathWidget extends StatefulWidget {
  final List<dynamic> path;
  final int currentIndex;
  final double segmentProgress;

  const _AnimatedPathWidget({
    required this.path,
    required this.currentIndex,
    required this.segmentProgress,
  });

  @override
  State<_AnimatedPathWidget> createState() => _AnimatedPathWidgetState();
}

class _AnimatedPathWidgetState extends State<_AnimatedPathWidget> {
  // Return full station name (no truncation)
  String _truncateStationName(String name) {
    return name; // Return full name without truncation
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    final currentIndex = widget.currentIndex;
    final pathLength = path.length;

    // Handle edge cases
    if (pathLength == 1) {
      return _buildSingleNode(path[0]);
    } else if (pathLength == 2) {
      return _buildTwoNodes(path, currentIndex);
    } else if (pathLength == 3) {
      return _buildThreeNodes(path, currentIndex);
    } else {
      return _buildFourNodes(path, currentIndex);
    }
  }

  Widget _buildSingleNode(dynamic station) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: TPColors.primary500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
            TPText(
            _truncateStationName(station.name),
            style: TPTextStyles.caption,
            color: TPColors.grayscale700,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTwoNodes(List<dynamic> path, int currentIndex) {
    return Row(
      children: [
        Expanded(
          child: _buildNode(
            station: path[0],
            isActive: currentIndex == 0,
            size: currentIndex == 0 ? 1.0 : 0.6,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 2,
            color: TPColors.primary300,
          ),
        ),
        Expanded(
          child: _buildNode(
            station: path[1],
            isActive: currentIndex == 1,
            size: currentIndex == 1 ? 1.0 : 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildThreeNodes(List<dynamic> path, int currentIndex) {
    return Row(
      children: [
        Expanded(
          child: _buildNode(
            station: path[0],
            isActive: currentIndex == 0,
            size: currentIndex == 0 ? 1.0 : 0.5,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 2,
            color: TPColors.primary300,
          ),
        ),
        Expanded(
          child: _buildNode(
            station: path[1],
            isActive: currentIndex == 1,
            size: currentIndex == 1 ? 1.0 : (currentIndex == 0 ? 0.8 : 0.5),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 2,
            color: TPColors.primary300,
          ),
        ),
        Expanded(
          child: _buildNode(
            station: path[2],
            isActive: currentIndex == 2,
            size: currentIndex == 2 ? 1.0 : 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFourNodes(List<dynamic> path, int currentIndex) {
    // Determine which stations to show
    MrtStation? startStation;
    MrtStation? currentStation;
    MrtStation? nextStation;
    MrtStation? destinationStation;

    // Check if we're in the last 3 stations (last - 2, last - 1, last)
    // Or if last - 1 or last station is current - keep the same stations in middle-left and middle-right positions
    final isInLastThree = currentIndex >= path.length - 3;
    final isLastMinusOne = currentIndex == path.length - 2;
    final isLast = currentIndex >= path.length - 1;
    
    if (currentIndex == 0) {
      // At start - left shows start station, middle-left shows next station (like middle-right)
      startStation = path[0];
      currentStation = path.length > 1 ? path[1] : path[0]; // Next station in middle-left
      nextStation = path.length > 2 ? path[2] : null; // Station after next in middle-right
      destinationStation = path.length > 2 ? path[path.length - 1] : (path.length > 1 ? path[1] : path[0]);
    } else if (isInLastThree || isLastMinusOne || isLast) {
      // When in last 3 stations, at last - 1, or at last, keep positions fixed:
      // middle-left always shows last - 2, middle-right always shows last - 1
      startStation = path[0];
      if (path.length >= 3) {
        currentStation = path[path.length - 3]; // Last - 2 station in middle-left (fixed position)
        nextStation = path[path.length - 2]; // Last - 1 station in middle-right (fixed position)
      } else if (path.length >= 2) {
        currentStation = path[path.length - 2]; // Last - 1 station in middle-left if only 2 stations
        nextStation = null;
      } else {
        currentStation = path[0];
        nextStation = null;
      }
      destinationStation = path[path.length - 1];
    } else if (currentIndex > path.length - 1) {
      // After last stop - same as at last stop
      startStation = path[0];
      if (path.length >= 2) {
        currentStation = path[path.length - 2]; // Last - 2 station in middle-left (non-current)
      } else {
        currentStation = path[0]; // Fallback if path is too short
      }
      nextStation = null; // Don't show in middle-right
      destinationStation = path[path.length - 1]; // This will be shown in right node as current
    } else {
      // In the middle - left is inactive start, middle-left is current, middle-right is next
      startStation = path[0];
      currentStation = path[currentIndex];
      nextStation = currentIndex + 1 < path.length ? path[currentIndex + 1] : null;
      destinationStation = path[path.length - 1];
    }

    // Calculate node sizes
    // When middle-left is current: it should have same size as left node
    // All non-current nodes should have the same size (larger than before)
    final isRightNodeCurrent = currentIndex >= path.length - 1;
    final nonCurrentSize = 0.7; // Same size for all non-current nodes (increased from 0.4)
    final currentSize = currentIndex == 0 ? 1.0 : 1.0; // Current node same size as left node (1.0)
    // When right node is current, left node should be non-current
    final startSize = (currentIndex == 0 && !isRightNodeCurrent) ? 1.0 : nonCurrentSize;
    final nextSize = nonCurrentSize; // Same size for middle-right (non-current)
    final destinationSize = isRightNodeCurrent ? 1.0 : nonCurrentSize; // Large when reached, same as non-current otherwise

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row for nodes only - aligned horizontally
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Start station (left node) - active and large at start, inactive and small after
            // When right node is current (currentIndex >= path.length - 1), this should be non-current
            Expanded(
              child: Center(
                child: _buildNodeCircle(
                  isActive: currentIndex == 0 && currentIndex < path.length - 1, // Only active at start, not when right is current
                  size: startSize,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                height: 2,
                color: TPColors.primary300,
              ),
            ),
            // Middle-left: shows next station at start, shows current station after moving, shows previous station at last stop
            Expanded(
              child: Center(
                child: _buildMiddleLeftNodeCircle(
                  currentStation: currentStation,
                  currentIndex: currentIndex,
                  pathLength: path.length,
                  currentSize: currentSize,
                  nonCurrentSize: nonCurrentSize,
                  path: path,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                height: 2,
                color: TPColors.primary300,
              ),
            ),
            // Next station (middle-right) - should not show last station (only right node shows it)
            // Also should not show anything when at or after last stop
            // IMPORTANT: Never show as active/current - always isActive: false
            Expanded(
              child: Center(
                child: _buildMiddleRightNodeCircle(
                  nextStation: nextStation,
                  destinationStation: destinationStation,
                  currentIndex: currentIndex,
                  pathLength: path.length,
                  nextSize: nextSize,
                ),
              ),
            ),
            // Show connecting line if middle-right node is visible
            // It should be visible when nextStation exists and is different from destination
            // Also show when at last station (currentIndex >= path.length - 1) if middle-right is showing
            if (nextStation != null && 
                nextStation.id != destinationStation?.id &&
                currentIndex <= path.length - 1)
              Expanded(
                flex: 2,
                child: Container(
                  height: 2,
                  color: TPColors.primary300,
                ),
              ),
            // Destination (right) - becomes current when at last stop
            Expanded(
              child: destinationStation != null
                  ? Center(
                      child: _buildNodeCircle(
                        isActive: currentIndex >= path.length - 1, // Active when at last stop
                        size: currentIndex >= path.length - 1 ? currentSize : destinationSize,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row for station names - aligned below their respective nodes
        Row(
          children: [
            Expanded(
              child: Center(
                child: _buildStationName(
                  station: startStation,
                  isActive: currentIndex == 0 && currentIndex < path.length - 1,
                ),
              ),
            ),
            Expanded(flex: 2, child: const SizedBox.shrink()),
            Expanded(
              child: Center(
                child: _buildStationName(
                  station: currentStation,
                  isActive: (currentIndex > 0 && currentIndex < path.length - 1) || 
                            (currentIndex == path.length - 3),
                ),
              ),
            ),
            Expanded(flex: 2, child: const SizedBox.shrink()),
            Expanded(
              child: Center(
                child: _buildStationName(
                  station: nextStation,
                  isActive: currentIndex == path.length - 2,
                ),
              ),
            ),
            if (nextStation != null && 
                nextStation.id != destinationStation?.id &&
                currentIndex <= path.length - 1)
              Expanded(flex: 2, child: const SizedBox.shrink()),
            Expanded(
              child: destinationStation != null
                  ? Center(
                      child: _buildStationName(
                        station: destinationStation,
                        isActive: currentIndex >= path.length - 1,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildNode({
    required dynamic station,
    required bool isActive,
    required double size,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: size,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? TPColors.primary500 : TPColors.grayscale400,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? TPColors.primary700 : TPColors.grayscale300,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: TPText(
            _truncateStationName(station.name),
            style: TPTextStyles.caption,
            color: isActive ? TPColors.grayscale900 : TPColors.grayscale600,
            maxLines: 1,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildNodeCircle({
    required bool isActive,
    required double size,
  }) {
    return Transform.scale(
      scale: size,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isActive ? TPColors.primary500 : TPColors.grayscale400,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? TPColors.primary700 : TPColors.grayscale300,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildMiddleLeftNodeCircle({
    required MrtStation? currentStation,
    required int currentIndex,
    required int pathLength,
    required double currentSize,
    required double nonCurrentSize,
    required List<dynamic> path,
  }) {
    final stationToShow = currentStation ?? (pathLength > 0 && path.isNotEmpty ? path[0] : null);
    if (stationToShow == null) {
      return const SizedBox.shrink();
    }

    final isRightNodeCurrent = currentIndex >= pathLength - 1;
    if (isRightNodeCurrent) {
      return _buildNodeCircle(
        isActive: false,
        size: nonCurrentSize,
      );
    }

    final isInLastThree = currentIndex >= pathLength - 3;
    final isLastMinusOne = currentIndex == pathLength - 2;
    final isLast = currentIndex >= pathLength - 1;
    if (isInLastThree || isLastMinusOne || isLast) {
      final isLastMinusTwo = currentIndex == pathLength - 3;
      return _buildNodeCircle(
        isActive: isLastMinusTwo,
        size: isLastMinusTwo ? currentSize : nonCurrentSize,
      );
    }

    if (currentIndex == 0) {
      return _buildNodeCircle(
        isActive: false,
        size: nonCurrentSize,
      );
    } else {
      return _buildNodeCircle(
        isActive: true,
        size: currentSize,
      );
    }
  }

  Widget _buildMiddleRightNodeCircle({
    required MrtStation? nextStation,
    required MrtStation? destinationStation,
    required int currentIndex,
    required int pathLength,
    required double nextSize,
  }) {
    if (nextStation == null || 
        nextStation.id == destinationStation?.id ||
        currentIndex > pathLength - 1) {
      return const SizedBox.shrink();
    }

    final isInLastThree = currentIndex >= pathLength - 3;
    final isLastMinusOne = currentIndex == pathLength - 2;
    final isLast = currentIndex >= pathLength - 1;
    if (isInLastThree || isLastMinusOne || isLast) {
      final shouldBeActive = isLastMinusOne && !isLast;
      return _buildNodeCircle(
        isActive: shouldBeActive,
        size: shouldBeActive ? 1.0 : nextSize,
      );
    }

    return _buildNodeCircle(
      isActive: false,
      size: nextSize,
    );
  }

  Widget _buildStationName({
    required dynamic station,
    required bool isActive,
  }) {
    if (station == null) {
      return const SizedBox.shrink();
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: TPText(
        _truncateStationName(station.name),
        style: TPTextStyles.caption,
        color: isActive ? TPColors.grayscale900 : TPColors.grayscale600,
        maxLines: 1,
        overflow: TextOverflow.visible,
        textAlign: TextAlign.center,
      ),
    );
  }
}
 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/points_service.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class PointsRankingPage extends StatefulWidget {
  const PointsRankingPage({super.key});

  @override
  State<PointsRankingPage> createState() => _PointsRankingPageState();
}

class _PointsRankingPageState extends State<PointsRankingPage> {
  final PointsService _pointsService = PointsService();
  late final String _username;
  late final Future<_PointsRankingData> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _username = Get.find<AccountService>().account?.username ?? '';
    _rankingFuture = _loadData();
  }

  Future<_PointsRankingData> _loadData() async {
    List<PointsRankingEntry> rankingEntries;
    try {
      rankingEntries = await _pointsService.fetchRanking();
    } catch (error, stackTrace) {
      debugPrint('Failed to fetch ranking list: $error');
      debugPrintStack(stackTrace: stackTrace);
      Get.snackbar(
        '提醒',
        '取得排行榜失敗，請稍後再試',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }

    int? totalPoints;
    if (_username.isNotEmpty) {
      try {
        totalPoints = await _pointsService.fetchTotalPoints(
          username: _username,
        );
      } catch (error, stackTrace) {
        debugPrint('Failed to fetch total points: $error');
        debugPrintStack(stackTrace: stackTrace);
        Get.snackbar(
          '提醒',
          '取得累積分數失敗，請稍後再試',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    final rankedEntries = rankingEntries.asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final data = entry.value;
      return RankedEntry(
        username: data.username,
        points: data.points,
        rank: rank,
      );
    }).toList();

    RankedEntry? extraEntry;
    final currentIndex =
        rankedEntries.indexWhere((entry) => entry.username == _username);
    if (currentIndex >= 0) {
      final currentEntry = rankedEntries[currentIndex];
      extraEntry = currentEntry.rank > 10 ? currentEntry : null;
    }

    final topEntries = rankedEntries.take(10).toList();

    return _PointsRankingData(
      totalPoints: totalPoints,
      topEntries: topEntries,
      extraEntry: extraEntry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TPColors.white,
      appBar: const TPAppBar(
        title: '排行榜',
        foregroundColor: TPColors.grayscale900,
      ),
      body: FutureBuilder<_PointsRankingData>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: TPColors.primary500),
            );
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error);
          }

          final data = snapshot.data;
          if (data == null) {
            return _buildError('無法取得排行榜資料');
          }

          return _buildContent(data);
        },
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: TPText(
          '取得排行榜時發生錯誤\n${error ?? ''}',
          style: TPTextStyles.bodyRegular,
          color: TPColors.grayscale500,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildContent(_PointsRankingData data) {
    return Stack(
      children: [
        ListView.separated(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            data.extraEntry != null ? 128 : 32,
          ),
          itemCount: data.topEntries.length + 2,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSummaryCard(data);
            }
            if (index == 1) {
              return TPText(
                '目前的排行榜',
                style: TPTextStyles.h3SemiBold,
                color: TPColors.grayscale900,
              );
            }

            final rankingIndex = index - 2;
            final entry = data.topEntries[rankingIndex];
            final rank = entry.rank;
            final isCurrentUser = entry.username == _username;
            return _buildRankingTile(
              rank: rank,
              entry: entry,
              highlight: isCurrentUser,
            );
          },
        ),
        if (data.extraEntry != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white.withOpacity(0.95),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TPText(
                    '我的排名',
                    style: TPTextStyles.caption,
                    color: TPColors.grayscale600,
                  ),
                  const SizedBox(height: 8),
                  _buildRankingTile(
                    rank: data.extraEntry!.rank,
                    entry: data.extraEntry!,
                    highlight: true,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(_PointsRankingData data) {
    final totalPointsText =
        data.totalPoints != null ? data.totalPoints.toString() : '--';
    String rankText = '--';
    if (data.extraEntry != null) {
      rankText = '#${data.extraEntry!.rank}';
    } else {
      final currentInTop = data.topEntries
          .firstWhereOrNull((entry) => entry.username == _username);
      if (currentInTop != null) {
        rankText = '#${currentInTop.rank}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TPColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TPColors.primary200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TPText(
            '累積分數',
            style: TPTextStyles.h3SemiBold,
            color: TPColors.grayscale700,
          ),
          const SizedBox(height: 8),
          TPText(
            totalPointsText,
            style: TPTextStyles.h1SemiBold,
            color: TPColors.primary600,
          ),
          const SizedBox(height: 12),
          TPText(
            '目前排名：$rankText',
            style: TPTextStyles.bodyRegular,
            color: TPColors.grayscale600,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTile({
    required int rank,
    required PointsRankingEntry entry,
    required bool highlight,
  }) {
    final Color backgroundColor =
        highlight ? TPColors.secondary50 : TPColors.white;
    final Color borderColor =
        highlight ? TPColors.secondary200 : TPColors.grayscale200;
    final Color textColor =
        highlight ? TPColors.secondary600 : TPColors.grayscale900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: TPColors.grayscale200.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: TPText(
              '$rank',
              style: TPTextStyles.h3SemiBold,
              color: textColor,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TPText(
              entry.username,
              style: TPTextStyles.bodyRegular,
              color: textColor,
            ),
          ),
          const SizedBox(width: 12),
          TPText(
            '${entry.points}',
            style: TPTextStyles.bodySemiBold,
            color: textColor,
          ),
        ],
      ),
    );
  }
}

class _PointsRankingData {
  const _PointsRankingData({
    required this.totalPoints,
    required this.topEntries,
    required this.extraEntry,
  });

  final int? totalPoints;
  final List<RankedEntry> topEntries;
  final RankedEntry? extraEntry;
}

class RankedEntry extends PointsRankingEntry {
  RankedEntry({
    required super.username,
    required super.points,
    required this.rank,
  });

  final int rank;
}



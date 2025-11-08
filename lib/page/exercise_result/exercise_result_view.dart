import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:town_pass/bean/exercise_history.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/points_service.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';
import 'exercise_places_repository.dart';

class ExerciseResultData {
  const ExerciseResultData({
    required this.startStation,
    required this.endStation,
    required this.totalDuration,
    required this.venues,
    required this.points,
    this.calories = 0,
    this.exerciseHistory = const [],
  });

  final String startStation;
  final String endStation;
  final Duration totalDuration;
  final List<ExerciseVenue> venues;
  final int points;
  final int calories;
  final List<ExerciseRecord> exerciseHistory;
}

class ExerciseVenue {
  const ExerciseVenue({
    required this.name,
    required this.imageUrl,
    required this.locationUrl,
  });

  final String name;
  final String imageUrl;
  final String locationUrl;
}

class ExerciseResultView extends StatefulWidget {
  const ExerciseResultView({
    super.key,
    ExerciseResultData? initialData,
  }) : _initialData = initialData;

  final ExerciseResultData? _initialData;

  static ExerciseResultViewState? of(BuildContext context) {
    return context.findAncestorStateOfType<ExerciseResultViewState>();
  }

  @override
  State<ExerciseResultView> createState() => ExerciseResultViewState();
}

class ExerciseResultViewState extends State<ExerciseResultView> {
  late ExerciseResultData _data;
  final PointsService _pointsService = PointsService();
  bool _hasSubmittedPoints = false;
  final GlobalKey _shareBoundaryKey = GlobalKey();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _data = _defaultData;
    final initialData = widget._initialData;
    if (initialData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setExerciseResult(initialData);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVenuesForStation(_data.endStation);
      });
    }
  }

  ExerciseResultData get _defaultData => ExerciseResultData(
        startStation: '台北車站',
        endStation: '市政府站',
        totalDuration: const Duration(minutes: 42),
        venues: const [],
        points: 0,
        calories: 0,
        exerciseHistory: const [],
      );

  ExerciseResultData _normalizeData(ExerciseResultData data) {
    final history = data.exerciseHistory;
    if (history.isEmpty) {
      return data;
    }

    final totalDurationSeconds =
        history.fold<int>(0, (sum, record) => sum + record.duration);
    final totalCalories =
        history.fold<int>(0, (sum, record) => sum + record.calories);

    return ExerciseResultData(
      startStation: data.startStation,
      endStation: data.endStation,
      totalDuration: totalDurationSeconds > 0
          ? Duration(seconds: totalDurationSeconds)
          : data.totalDuration,
      venues: data.venues,
      points: data.points,
      calories: totalCalories,
      exerciseHistory: history,
    );
  }

  void setExerciseResult(ExerciseResultData data) {
    final normalizedData = _normalizeData(data);
    setState(() {
      _data = normalizedData;
    });
    _loadVenuesForStation(normalizedData.endStation);
    _submitPointsIfNeeded(normalizedData);
  }

  @override
  Widget build(BuildContext context) {
    final durationText = _formatDuration(_data.totalDuration);

    return Scaffold(
      backgroundColor: TPColors.white,
      appBar: const TPAppBar(
        title: '運動結果',
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverToBoxAdapter(
              child: _buildSharePreview(durationText),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverToBoxAdapter(
              child: TPText(
                '終點站推薦運動場館',
                style: TPTextStyles.h3SemiBold,
                color: TPColors.grayscale900,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            sliver: _data.venues.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: TPText(
                          '此地點附近沒有推薦的運動場館',
                          style: TPTextStyles.bodyRegular,
                          color: TPColors.grayscale500,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final venue = _data.venues[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _data.venues.length - 1 ? 0 : 16,
                          ),
                          child: _VenueCard(
                            venue: venue,
                            onTap: () => _launchVenue(venue.locationUrl),
                          ),
                        );
                      },
                      childCount: _data.venues.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharePreview(String durationText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _shareBoundaryKey,
          child: _ShareResultCard(
            data: _data,
            durationText: durationText,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _isCapturing
              ? const SizedBox.shrink()
              : TextButton.icon(
                  onPressed: _shareResult,
                  style: TextButton.styleFrom(
                    foregroundColor: TPColors.primary500,
                  ),
                  icon: const Icon(
                    Icons.ios_share,
                    size: 18,
                  ),
                  label: const TPText(
                    '分享',
                    style: TPTextStyles.bodySemiBold,
                    color: TPColors.primary500,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _launchVenue(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法開啟連結')),
      );
    }
  }

  Future<void> _loadVenuesForStation(String stationName) async {
    final places =
        await ExercisePlacesRepository.findByStation(stationName);
    if (!mounted || _data.endStation != stationName) {
      return;
    }
    final reference = _data;
    final venues = places
        .map(
          (place) => ExerciseVenue(
            name: place.name,
            imageUrl: place.imageUrl,
            locationUrl: place.locationUrl,
          ),
        )
        .toList(growable: false);
    setState(() {
      _data = ExerciseResultData(
        startStation: reference.startStation,
        endStation: reference.endStation,
        totalDuration: reference.totalDuration,
        venues: venues,
        points: reference.points,
        calories: reference.calories,
        exerciseHistory: reference.exerciseHistory,
      );
    });
  }

  Future<void> _submitPointsIfNeeded(ExerciseResultData data) async {
    if (_hasSubmittedPoints || data.points <= 0) {
      return;
    }

    final username = Get.find<AccountService>().account?.username;
    if (username == null || username.isEmpty) {
      return;
    }

    try {
      await _pointsService.addPoints(username: username, points: data.points);
      _hasSubmittedPoints = true;
    } catch (error, stackTrace) {
      debugPrint('積分登入失敗: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      const snackBar = SnackBar(
        content: Text('積分登入失敗，請稍後再試'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final totalSeconds = duration.inSeconds.remainder(60);
    return totalSeconds == 0
        ? '$totalMinutes 分鐘'
        : '$totalMinutes 分 $totalSeconds 秒';
  }

  Future<void> _shareResult() async {
    if (kIsWeb) {
      await _shareResultAsText();
      return;
    }

    final shared = await _shareResultAsImage();
    if (!shared) {
      await _shareResultAsText();
    }
  }

  Future<bool> _shareResultAsImage() async {
    if (_shareBoundaryKey.currentContext == null) {
      return false;
    }

    setState(() {
      _isCapturing = true;
    });
    await Future.delayed(const Duration(milliseconds: 20));

    try {
      final boundary = _shareBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        return false;
      }

      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return false;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();
      final shareText = _buildShareText();
      final xFile = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'exercise_result.png',
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'Town Pass 運動結果',
        // text: shareText,
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('分享截圖失敗: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法分享截圖，請稍後再試')),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _shareResultAsText() async {
    final buffer = StringBuffer()
      ..writeln(_buildShareText());
    await Share.share(
      buffer.toString(),
      subject: 'Town Pass 運動結果',
    );
  }

  String _buildShareText() {
    final lines = <String>[
      '我的運動成果分享',
      '${_data.startStation} ➜ ${_data.endStation}',
      '總運動時間：${_formatDuration(_data.totalDuration)}',
    ];

    if (_data.calories > 0) {
      lines.add('消耗熱量：${_data.calories} kcal');
    }

    lines.add('本趟積分：${_data.points} 點');

    if (_data.exerciseHistory.isNotEmpty) {
      lines.add('');
      lines.add('運動歷程：');
      final history = _data.exerciseHistory;
      for (final record in history.take(3)) {
        final segment = record.stationSegment?.isNotEmpty == true
            ? '（${record.stationSegment}）'
            : '';
        lines.add(
          '- ${record.exerciseName}$segment · ${record.durationDisplay} · ${record.calories} kcal',
        );
      }
      if (history.length > 3) {
        lines.add('... 共 ${history.length} 段運動');
      }
    }

    return lines.join('\n');
  }
}

class _ShareResultCard extends StatelessWidget {
  const _ShareResultCard({
    required this.data,
    required this.durationText,
  });

  final ExerciseResultData data;
  final String durationText;

  @override
  Widget build(BuildContext context) {
    final history = data.exerciseHistory;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TPColors.primary500, TPColors.primary300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TPColors.primary500.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    TPText(
                      'Town Pass',
                      style: TPTextStyles.caption,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    TPText(
                      '我的運動成果',
                      style: TPTextStyles.h2SemiBold,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/svg/logo_S.svg',
                width: 48,
                height: 48,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.directions_subway_filled_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TPText(
                        '${data.startStation} ➜ ${data.endStation}',
                        style: TPTextStyles.h3SemiBold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ShareMetricTile(
                      icon: Icons.timer_outlined,
                      label: '總運動時間',
                      value: durationText,
                    ),
                    _ShareMetricTile(
                      icon: Icons.local_fire_department_outlined,
                      label: '消耗熱量',
                      value:
                          data.calories > 0 ? '${data.calories} kcal' : '— kcal',
                    ),
                    _ShareMetricTile(
                      icon: Icons.emoji_events_outlined,
                      label: '本趟積分',
                      value: '${data.points} 點',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 24),
            const TPText(
              '運動歷程',
              style: TPTextStyles.bodySemiBold,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            ...history.take(3).map(
              (record) => _ShareHistoryRow(record: record),
            ),
            if (history.length > 3) ...[
              const SizedBox(height: 8),
              TPText(
                '... 等 ${history.length} 段運動',
                style: TPTextStyles.caption,
                color: Colors.white.withOpacity(0.7),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ShareMetricTile extends StatelessWidget {
  const _ShareMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TPText(
                label,
                style: TPTextStyles.caption,
                color: Colors.white.withOpacity(0.75),
              ),
              const SizedBox(height: 2),
              TPText(
                value,
                style: TPTextStyles.bodySemiBold,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareHistoryRow extends StatelessWidget {
  const _ShareHistoryRow({
    required this.record,
  });

  final ExerciseRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TPText(
                  record.exerciseName,
                  style: TPTextStyles.bodySemiBold,
                  color: Colors.white,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                TPText(
                  '${record.durationDisplay} · ${record.calories} kcal',
                  style: TPTextStyles.caption,
                  color: Colors.white.withOpacity(0.75),
                ),
                if (record.stationSegment?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  TPText(
                    record.stationSegment!,
                    style: TPTextStyles.caption,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.onTap,
  });

  final ExerciseVenue venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: TPColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TPColors.grayscale200),
          boxShadow: [
            BoxShadow(
              color: TPColors.grayscale200.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  venue.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: TPColors.grayscale100,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: TPColors.grayscale400,
                      ),
                    ),
                  ),
loadingBuilder: (context, child, progress) {
  if (progress == null) {
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
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TPText(
                    venue.name,
                    style: TPTextStyles.h3SemiBold,
                    color: TPColors.grayscale900,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: TPColors.primary500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TPText(
                          venue.locationUrl,
                          style: TPTextStyles.caption,
                          color: TPColors.grayscale600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTap,
                      child: const TPText(
                        '查看地點',
                        style: TPTextStyles.bodySemiBold,
                        color: TPColors.primary500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



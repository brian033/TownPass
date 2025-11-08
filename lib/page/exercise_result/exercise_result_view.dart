import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
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
  });

  final String startStation;
  final String endStation;
  final Duration totalDuration;
  final List<ExerciseVenue> venues;
  final int points;
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
      );

  void setExerciseResult(ExerciseResultData data) {
    setState(() {
      _data = data;
    });
    _loadVenuesForStation(data.endStation);
    _submitPointsIfNeeded(data);
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _data.totalDuration.inMinutes;
    final totalSeconds = _data.totalDuration.inSeconds.remainder(60);
    final durationText = totalSeconds == 0
        ? '$totalMinutes 分鐘'
        : '$totalMinutes 分 $totalSeconds 秒';

    return Scaffold(
      backgroundColor: TPColors.white,
      appBar: const TPAppBar(
        title: '運動結果',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(durationText),
            const SizedBox(height: 24),
            TPText(
              '終點站推薦運動場館',
              style: TPTextStyles.h3SemiBold,
              color: TPColors.grayscale900,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _data.venues.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: TPText(
                          '此地點附近沒有推薦的運動場館',
                          style: TPTextStyles.bodyRegular,
                          color: TPColors.grayscale500,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _data.venues.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final venue = _data.venues[index];
                        return _VenueCard(
                          venue: venue,
                          onTap: () => _launchVenue(venue.locationUrl),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String durationText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TPColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TPColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_subway_filled_rounded,
                color: TPColors.primary500,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TPText(
                  '${_data.startStation} ➜ ${_data.endStation}',
                  style: TPTextStyles.h3SemiBold,
                  color: TPColors.grayscale900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              TPText(
                '總運動時間：$durationText',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale700,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: TPColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              TPText(
                '本趟積分：${_data.points} 點',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale700,
              ),
            ],
          ),
        ],
      ),
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


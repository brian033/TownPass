import 'dart:convert';

import 'package:http/http.dart' as http;

class PointsService {
  static const String _addEndpoint =
      'https://election.ntusa.ntu.edu.tw/api/points/add/';
  static const String _totalEndpoint =
      'https://election.ntusa.ntu.edu.tw/api/points/total/';
  static const String _rankingEndpoint =
      'https://election.ntusa.ntu.edu.tw/api/points/ranking/';

  Future<void> addPoints({
    required String username,
    required int points,
  }) async {
    final response = await http.post(
      Uri.parse(_addEndpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'username': username,
        'points': points,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to submit points. Status: ${response.statusCode}, body: ${response.body}',
      );
    }
  }

  Future<int> fetchTotalPoints({required String username}) async {
    final response = await http.post(
      Uri.parse(_totalEndpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'username': username,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch total points. Status: ${response.statusCode}, body: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      for (final key in ['total', 'total_points', 'points', 'score']) {
        final value = decoded[key];
        if (value is num) {
          return value.toInt();
        }
      }
    } else if (decoded is num) {
      return decoded.toInt();
    }

    throw Exception('Unexpected total points response: ${response.body}');
  }

  Future<List<PointsRankingEntry>> fetchRanking() async {
    final response = await http.get(Uri.parse(_rankingEndpoint));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch ranking. Status: ${response.statusCode}, body: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map((entry) => PointsRankingEntry.fromJson(entry))
          .toList();
    }

    throw Exception('Unexpected ranking response: ${response.body}');
  }
}

class PointsRankingEntry {
  PointsRankingEntry({
    required this.username,
    required this.points,
  });

  factory PointsRankingEntry.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final dynamic username = json['username'];
      final dynamic points = json['points'] ?? json['total_points'];
      return PointsRankingEntry(
        username: username?.toString() ?? '-',
        points: (points is num) ? points.toInt() : 0,
      );
    }

    return PointsRankingEntry(username: '-', points: 0);
  }

  final String username;
  final int points;
}


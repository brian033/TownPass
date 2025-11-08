import 'dart:convert';

import 'package:http/http.dart' as http;

class PointsService {
  static const String _endpoint =
      'https://election.ntusa.ntu.edu.tw/api/points/add/';

  Future<void> addPoints({
    required String username,
    required int points,
  }) async {
    final response = await http.post(
      Uri.parse(_endpoint),
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
}


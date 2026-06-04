import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/job.dart';

class JobRepository {
  static const _assetPath = 'assets/mock/jobs.json';

  Future<List<Job>> fetchAll() async {
    final jsonString = await rootBundle.loadString(_assetPath);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((e) => Job.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

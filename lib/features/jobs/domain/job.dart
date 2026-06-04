import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required String title,
    required String company,
    required String location,
    required bool isRemote,
    required String salaryRange,
    required List<String> skills,
    required String description,
    required String source,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

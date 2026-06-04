// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobImpl _$$JobImplFromJson(Map<String, dynamic> json) => _$JobImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  company: json['company'] as String,
  location: json['location'] as String,
  isRemote: json['isRemote'] as bool,
  salaryRange: json['salaryRange'] as String,
  skills: (json['skills'] as List<dynamic>).map((e) => e as String).toList(),
  description: json['description'] as String,
  source: json['source'] as String,
  url: json['url'] as String?,
  crawledAt: json['crawledAt'] == null
      ? null
      : DateTime.parse(json['crawledAt'] as String),
);

Map<String, dynamic> _$$JobImplToJson(_$JobImpl instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'company': instance.company,
  'location': instance.location,
  'isRemote': instance.isRemote,
  'salaryRange': instance.salaryRange,
  'skills': instance.skills,
  'description': instance.description,
  'source': instance.source,
  'url': instance.url,
  'crawledAt': instance.crawledAt?.toIso8601String(),
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarPath: json['avatarPath'] as String?,
      expectedSalary: json['expectedSalary'] as String? ?? '',
      expectedLocation: json['expectedLocation'] as String? ?? '',
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'skills': instance.skills,
      'name': instance.name,
      'bio': instance.bio,
      'avatarPath': instance.avatarPath,
      'expectedSalary': instance.expectedSalary,
      'expectedLocation': instance.expectedLocation,
    };

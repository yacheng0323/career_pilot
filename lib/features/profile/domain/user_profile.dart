import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @Default([]) List<String> skills,
    @Default('') String name,
    @Default('') String bio,
    String? avatarPath,
    @Default('') String expectedSalary,
    @Default('') String expectedLocation,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

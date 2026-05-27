import 'package:freezed_annotation/freezed_annotation.dart';

part 'userprofile_state.freezed.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    required String name,
    required String avatarPath,
    required DateTime quitDate,
    @Default(0) int achievementsCount,
  }) = _UserProfile;

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    final rawQuitDate = data['quitDate'] as String?;
    final parsedQuitDate =
        rawQuitDate != null && rawQuitDate.isNotEmpty
            ? DateTime.tryParse(rawQuitDate)?.toLocal() ?? DateTime.now()
            : DateTime.now();

    return UserProfile(
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? 'User',
      avatarPath: data['profileIcon'] as String? ?? 'assets/icons/account.png',
      achievementsCount: (data['achievementsCount'] as num?)?.toInt() ?? 0,
      quitDate: parsedQuitDate,
    );
  }
}

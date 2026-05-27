import 'package:appwrite/models.dart' as appwrite;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement_state.freezed.dart';

@freezed
class AchievementState with _$AchievementState {
  const factory AchievementState({
    required String id,
    required String userId,
    required String title,
    required String description,
    required DateTime achievedAt,
    required String icon,
    @Default('bronze') String level,
    @Default(1) int targetValue,
    @Default('general') String category,
  }) = _AchievementState;

  factory AchievementState.initial() => AchievementState(
    id: '',
    userId: '',
    title: '',
    description: '',
    achievedAt: DateTime.now(),
    icon: 'default_achievement',
  );

  factory AchievementState.fromAppwriteDocument(appwrite.Document doc) {
    return AchievementState(
      id: doc.data['achievementId'],
      userId: doc.data['userId'] as String? ?? '',
      title: doc.data['title'] as String? ?? '',
      description: doc.data['description'] as String? ?? '',
      achievedAt: DateTime.parse(
        doc.data['achievedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      icon: doc.data['icon'] as String? ?? 'default_achievement',
      level: doc.data['level'] as String? ?? 'bronze',
      targetValue: (doc.data['targetValue'] as int?) ?? 1,
      category: doc.data['category'] as String? ?? 'general',
    );
  }
}

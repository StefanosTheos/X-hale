import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge_state.freezed.dart';

@freezed
class ChallengeEntry with _$ChallengeEntry {
  const factory ChallengeEntry({
    required String id,
    required String challengeId,
    required String userId,
    required String message,
    required DateTime createdAt,
  }) = _ChallengeEntry;
}

@freezed
class Challenge with _$Challenge {
  const factory Challenge({
    required String id,
    required String userId,
    required String title,
    required String type,
    required String iconPath,
    required String status,
    required DateTime createdAt,

    // Financial-only fields
    double? goalBudget,
    double? progress,
    double? collected,

    // Physical-only fields
    DateTime? lastEntry,

    @Default([]) List<ChallengeEntry> entries,
  }) = _Challenge;

  const Challenge._();

  bool get isPhysical => type == 'physical';
  bool get isFinancial => type == 'financial';

  bool get isActive => status.toLowerCase() == 'active';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isForfeited => status.toLowerCase() == 'forfeited';
}

@freezed
class ChallengeState with _$ChallengeState {
  const factory ChallengeState({
    @Default([]) List<Challenge> challenges,
    @Default(false) bool isLoading,
    @Default(false) bool hasError,
  }) = _ChallengeState;

  const ChallengeState._();

  factory ChallengeState.initial() => const ChallengeState();

  List<Challenge> get active => challenges.where((c) => c.isActive).toList();
  List<Challenge> get completed =>
      challenges.where((c) => c.isCompleted).toList();
  List<Challenge> get forfeited =>
      challenges.where((c) => c.isForfeited).toList();
}

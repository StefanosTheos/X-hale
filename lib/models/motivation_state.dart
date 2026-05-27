import 'package:appwrite/models.dart' as appwrite;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'motivation_state.freezed.dart';

@freezed
class MotivationState with _$MotivationState {
  const factory MotivationState({
    required String id,
    required String userId,
    required String motivationText,
    required DateTime createdAt,
    @Default(false) bool isPinned,
    @Default('#48CAE4') String color,
    @Default('goal') String icon,
  }) = _MotivationState;

  factory MotivationState.initial() => MotivationState(
    id: '',
    userId: '',
    motivationText: '',
    createdAt: DateTime.now(),
  );

  factory MotivationState.fromAppwriteDocument(appwrite.Document doc) {
    return MotivationState(
      id: doc.$id,
      userId: doc.data['userId'] as String? ?? '',
      motivationText: doc.data['motivationText'] as String? ?? '',
      createdAt: DateTime.parse(
        doc.data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isPinned: doc.data['isPinned'] as bool? ?? false,
      color: doc.data['color'] as String? ?? '#48CAE4',
      icon: doc.data['icon'] as String? ?? 'goal',
    );
  }
}

@freezed
class MotivationsListState with _$MotivationsListState {
  const factory MotivationsListState({
    @Default([]) List<MotivationState> motivations,
    @Default(false) bool isLoading,
    @Default(false) bool hasError,
    String? errorMessage,
  }) = _MotivationsListState;

  factory MotivationsListState.initial() => const MotivationsListState();
}

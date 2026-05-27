import 'package:freezed_annotation/freezed_annotation.dart';

part 'forum_state.freezed.dart';

@freezed
class ForumPost with _$ForumPost {
  const factory ForumPost({
    required String id,
    required String userId,
    required String username,
    required String message,
    required DateTime createdAt,
    required String userAvatar,
  }) = _ForumPost;
}

@freezed
class ForumPostState with _$ForumPostState {
  const factory ForumPostState({
    @Default([]) List<ForumPost> posts,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasError,
  }) = _ForumPostState;

  const ForumPostState._();

  factory ForumPostState.initial() => const ForumPostState();

  List<ForumPost> get sorted =>
      [...posts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

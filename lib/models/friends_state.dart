import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:smoking/models/userprofile_state.dart';

part 'friends_state.freezed.dart';

@freezed
class FriendRequest with _$FriendRequest {
  const factory FriendRequest({
    required String requestId,
    required String senderId,
    required String receiverId,
    required String status, // 'pending', 'accepted', 'declined'
    required DateTime sentAt,
  }) = _FriendRequest;
}

@freezed
class Friendship with _$Friendship {
  const factory Friendship({
    required String friendshipId,
    required String user1Id,
    required String user2Id,
    required DateTime createdAt,
  }) = _Friendship;
}

@freezed
class Message with _$Message {
  const factory Message({
    required String messageId,
    required String senderId,
    required String receiverId,
    required String message,
    required DateTime sentAt,
    @Default(false) bool read,
  }) = _Message;
}

@freezed
class FriendPageState with _$FriendPageState {
  const factory FriendPageState({
    @Default([]) List<Friendship> friends,
    @Default([]) List<FriendRequest> incomingRequests,
    @Default([]) List<FriendRequest> outgoingRequests,
    @Default([]) List<Message> messages,
    // Friend profiles preloaded in one batch from `fetchFriendProfiles`,
    // keyed by the other user's id. Lets the friends list render each tile
    // synchronously from cache instead of firing two `listDocuments` calls
    // per row (one for profile, one for quitDate) on every rebuild.
    @Default({}) Map<String, UserProfile> friendProfiles,
    // Same idea for the Friend Requests tab — preloaded sender profiles
    // (incl. their quitDate) so `_buildFriendRequests`'s `ListView.builder`
    // doesn't fire two `listDocuments` calls per row per rebuild.
    @Default({}) Map<String, UserProfile> incomingRequestProfiles,
    @Default(false) bool isLoading,
    @Default(false) bool hasError,
    UserProfile? searchResult,
  }) = _FriendPageState;
}

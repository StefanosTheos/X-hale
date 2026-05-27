import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:smoking/models/friends_state.dart';
import 'package:flutter/foundation.dart';
import 'package:smoking/models/userprofile_state.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';

final friendProvider = StateNotifierProvider<FriendNotifier, FriendPageState>((
  ref,
) {
  // Watch userId so the notifier is torn down on logout / login-as-other-user.
  // Without this, the same `FriendNotifier` instance survives identity changes
  // and keeps the previous user's friends / incomingRequests / messages until
  // the page explicitly refetches. The userId itself isn't threaded through —
  // the notifier still reads the current user from `userProvider` when needed
  // — but the `watch` forces a fresh instance with empty state.
  ref.watch(userProvider.select((u) => u.userId));
  return FriendNotifier(ref, ref.watch(databasesProvider));
});

class FriendNotifier extends StateNotifier<FriendPageState> {
  final Ref _ref;
  final Databases _db;
  final String _databaseId = AppwriteConfig.databaseId;
  final String _friendshipCollection = AppwriteCollections.friendships;
  final String _requestCollection = AppwriteCollections.friendRequests;
  final String _messagesCollection = AppwriteCollections.directMessages;

  FriendNotifier(this._ref, this._db) : super(const FriendPageState());

  Future<void> fetchFriendships(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _friendshipCollection,
        queries: [
          Query.or([
            Query.equal('user1Id', userId),
            Query.equal('user2Id', userId),
          ]),
        ],
      );

      final friends =
          res.documents.map((doc) {
            return Friendship(
              friendshipId: doc.$id,
              user1Id: doc.data['user1Id'],
              user2Id: doc.data['user2Id'],
              createdAt: DateTime.parse(doc.data['createdAt']).toLocal(),
            );
          }).toList();

      state = state.copyWith(friends: friends, isLoading: false);
    } catch (e) {
      debugPrint('fetchFriendships error: $e');
      state = state.copyWith(hasError: true, isLoading: false);
    }
  }

  Future<void> fetchIncomingRequests(String userId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _requestCollection,
        queries: [
          Query.equal('receiverId', userId),
          Query.equal('status', 'pending'),
        ],
      );

      final requests =
          res.documents.map((doc) {
            return FriendRequest(
              requestId: doc.$id,
              senderId: doc.data['senderId'],
              receiverId: doc.data['receiverId'],
              status: doc.data['status'],
              sentAt: DateTime.parse(doc.data['sentAt']).toLocal(),
            );
          }).toList();
      debugPrint("Fetched incoming requests: ${requests.length}");
      state = state.copyWith(incomingRequests: requests);
    } catch (e) {
      debugPrint('fetchIncomingRequests error: $e');
    }
  }

  Future<void> fetchOutgoingRequests(String userId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _requestCollection,
        queries: [
          Query.equal('senderId', userId),
          Query.equal('status', 'pending'),
        ],
      );

      final requests =
          res.documents.map((doc) {
            return FriendRequest(
              requestId: doc.$id,
              senderId: doc.data['senderId'],
              receiverId: doc.data['receiverId'],
              status: doc.data['status'],
              sentAt: DateTime.parse(doc.data['sentAt']).toLocal(),
            );
          }).toList();

      state = state.copyWith(outgoingRequests: requests);
    } catch (e) {
      debugPrint('fetchOutgoingRequests error: $e');
    }
  }

  Future<void> searchUserByName(String username) async {
    // Don't clear `searchResult` on entry — keeping the previous value
    // visible during the in-flight call lets the friends page hold the
    // last EmptyState / user card stable instead of flashing through a
    // null intermediate state on every keystroke (see audit #45).
    state = state.copyWith(isLoading: true, hasError: false);
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      // Prefer fulltext search so typos and different casing still match —
      // requires a fulltext index on `name` (Appwrite console → collection →
      // indexes). When that index is missing, Appwrite returns a 400 with
      // `general_query_invalid`; fall back to exact-match `Query.equal` so
      // the feature still works for users who type a full username.
      var documents = const <dynamic>[];
      try {
        final result = await _db.listDocuments(
          databaseId: _databaseId,
          collectionId: AppwriteCollections.users,
          queries: [Query.search('name', trimmed), Query.limit(1)],
        );
        documents = result.documents;
      } on AppwriteException catch (e) {
        final isFulltextMissing = e.type == 'general_query_invalid' ||
            (e.message?.contains('fulltext index') ?? false);
        if (!isFulltextMissing) rethrow;
        debugPrint(
          'searchUserByName: fulltext index missing, falling back to exact match',
        );
        final fallback = await _db.listDocuments(
          databaseId: _databaseId,
          collectionId: AppwriteCollections.users,
          queries: [Query.equal('name', trimmed), Query.limit(1)],
        );
        documents = fallback.documents;
      }

      if (documents.isNotEmpty) {
        final data = documents.first.data;
        final userProfile = UserProfile.fromMap(data);
        state = state.copyWith(searchResult: userProfile, isLoading: false);
      } else {
        state = state.copyWith(searchResult: null, isLoading: false);
      }
    } catch (e) {
      debugPrint('searchUserByName error: $e');
      state = state.copyWith(hasError: true, isLoading: false);
    }
  }

  Future<void> removeFriend(String friendshipId) async {
    final userId = _ref.read(userProvider).userId;
    try {
      final friendshipDoc = await _db.getDocument(
        databaseId: _databaseId,
        collectionId: _friendshipCollection,
        documentId: friendshipId,
      );

      final user1Id = friendshipDoc.data['user1Id'];
      final user2Id = friendshipDoc.data['user2Id'];
      final friendId = user1Id == userId ? user2Id : user1Id;

      final dmResults = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _messagesCollection,
        queries: [
          Query.or([
            Query.and([
              Query.equal('senderId', userId),
              Query.equal('receiverId', friendId),
            ]),
            Query.and([
              Query.equal('senderId', friendId),
              Query.equal('receiverId', userId),
            ]),
          ]),
        ],
      );

      for (final doc in dmResults.documents) {
        await _db.deleteDocument(
          databaseId: _databaseId,
          collectionId: _messagesCollection,
          documentId: doc.$id,
        );
      }

      await _db.deleteDocument(
        databaseId: _databaseId,
        collectionId: _friendshipCollection,
        documentId: friendshipId,
      );
      await _ref.read(userProvider.notifier).syncNumFriends(user1Id);
      await _ref.read(userProvider.notifier).syncNumFriends(user2Id);

      await fetchFriendships(userId);
      // Was fire-and-forget — the chats tab could render the old message
      // list (still showing DMs with the just-removed friend) for a frame.
      await fetchMessages(userId);
      debugPrint('Friendship list refreshed');
    } catch (e) {
      debugPrint('removeFriend error: $e');
    }
  }

  Future<void> respondToFriendRequest(String requestId, String action) async {
    try {
      final doc = await _db.getDocument(
        databaseId: _databaseId,
        collectionId: _requestCollection,
        documentId: requestId,
      );

      final senderId = doc.data['senderId'];
      final receiverId = doc.data['receiverId'];

      if (action == 'accepted') {
        await _db.updateDocument(
          databaseId: _databaseId,
          collectionId: _requestCollection,
          documentId: requestId,
          data: {'status': 'accepted'},
        );

        await _db.createDocument(
          databaseId: _databaseId,
          collectionId: _friendshipCollection,
          documentId: ID.unique(),
          data: {
            'user1Id': senderId,
            'user2Id': receiverId,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          },
        );

        await _ref.read(userProvider.notifier).syncNumFriends(senderId);
        await _ref.read(userProvider.notifier).syncNumFriends(receiverId);
      } else if (action == 'declined') {
        await _db.updateDocument(
          databaseId: _databaseId,
          collectionId: _requestCollection,
          documentId: requestId,
          data: {'status': 'declined'},
        );
      }
    } catch (e) {
      debugPrint('respondToFriendRequest error: $e');
    }
  }

  Future<void> fetchMessages(String userId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _messagesCollection,
        queries: [
          Query.or([
            Query.equal('senderId', userId),
            Query.equal('receiverId', userId),
          ]),
          Query.orderDesc('sentAt'),
        ],
      );

      final messages =
          res.documents.map((doc) {
            return Message(
              messageId: doc.$id,
              senderId: doc.data['senderId'],
              receiverId: doc.data['receiverId'],
              message: doc.data['message'],
              sentAt: DateTime.parse(doc.data['sentAt']).toLocal(),
              read: doc.data['read'] ?? false,
            );
          }).toList();

      state = state.copyWith(messages: messages);
    } catch (e) {
      debugPrint('fetchMessages error: $e');
    }
  }

  Future<void> fetchAllFriendData() async {
    final userId = _ref.read(userProvider).userId;

    await Future.wait([
      fetchFriendships(userId),
      fetchIncomingRequests(userId),
      fetchOutgoingRequests(userId),
      fetchMessages(userId),
    ]);
    // Friendships and incoming-request senders are now known — preload both
    // profile maps in parallel so the friends and requests tabs render
    // synchronously from cache (no per-tile futures).
    await Future.wait([
      fetchFriendProfiles(),
      fetchIncomingRequestProfiles(),
    ]);
  }

  /// Resolve every friend's `UserProfile` in parallel and cache the result on
  /// state. The friends list reads from this map synchronously instead of
  /// firing two `getUserProfileById` calls per row (one for the profile,
  /// one for the quit date) that resolved to the same Appwrite document.
  Future<void> fetchFriendProfiles() async {
    final currentUserId = _ref.read(userProvider).userId;
    if (currentUserId.isEmpty || state.friends.isEmpty) {
      state = state.copyWith(friendProfiles: const {});
      return;
    }
    // List instead of Set so the zip with `results` is O(N) — `Set.elementAt`
    // is O(i), making the previous loop O(N²). `.toSet().toList()` still
    // dedupes self-friendships if any sneak in.
    final otherIds = state.friends
        .map((f) => f.user1Id == currentUserId ? f.user2Id : f.user1Id)
        .toSet()
        .toList();
    final userNotifier = _ref.read(userProvider.notifier);
    final results =
        await Future.wait(otherIds.map(userNotifier.getUserProfileById));
    final profiles = <String, UserProfile>{};
    for (var i = 0; i < otherIds.length; i++) {
      final profile = results[i];
      if (profile != null) profiles[otherIds[i]] = profile;
    }
    state = state.copyWith(friendProfiles: profiles);
  }

  /// Resolve each incoming-request sender's `UserProfile` (which already
  /// contains `quitDate`) in parallel and cache on state. The friend-
  /// requests tab reads from this map synchronously instead of firing two
  /// `getUserProfileById` calls per row (one for the profile, one for the
  /// quit date) — both hit the same user document, so it was two
  /// listDocuments per row per rebuild.
  Future<void> fetchIncomingRequestProfiles() async {
    if (state.incomingRequests.isEmpty) {
      state = state.copyWith(incomingRequestProfiles: const {});
      return;
    }
    final senderIds = state.incomingRequests
        .map((r) => r.senderId)
        .toSet()
        .toList();
    final userNotifier = _ref.read(userProvider.notifier);
    final results =
        await Future.wait(senderIds.map(userNotifier.getUserProfileById));
    final profiles = <String, UserProfile>{};
    for (var i = 0; i < senderIds.length; i++) {
      final profile = results[i];
      if (profile != null) profiles[senderIds[i]] = profile;
    }
    state = state.copyWith(incomingRequestProfiles: profiles);
  }

  Future<void> respondToRequest(String requestId, bool accepted) async {
    final userId = _ref.read(userProvider).userId;
    await respondToFriendRequest(requestId, accepted ? 'accepted' : 'declined');
    await fetchIncomingRequests(userId);
    await fetchFriendships(userId);
  }

  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    try {
      await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _requestCollection,
        documentId: ID.unique(),
        data: {
          'senderId': senderId,
          'receiverId': receiverId,
          'status': 'pending',
          'sentAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      await fetchOutgoingRequests(senderId);
    } catch (e) {
      debugPrint('sendFriendRequest error: $e');
    }
  }

  /// Returns `true` if the DM was created (Appwrite confirmed) and `false`
  /// on any failure. Callers should preserve the user's input on `false`
  /// and surface a snackbar rather than silently clearing the message.
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      final created = await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _messagesCollection,
        documentId: ID.unique(),
        data: {
          'senderId': senderId,
          'receiverId': receiverId,
          'message': message,
          'sentAt': DateTime.now().toUtc().toIso8601String(),
          'read': false,
        },
      );
      // Optimistic prepend from the created doc — `fetchMessages` already
      // orders desc by `sentAt`, so insertion at the head matches the
      // existing convention. Previously called `fetchMessages(senderId)`
      // here, which re-fetched every DM the user is sender/receiver on just
      // to surface the one row that was just created.
      if (mounted) {
        state = state.copyWith(
          messages: [
            Message(
              messageId: created.$id,
              senderId: created.data['senderId'] as String,
              receiverId: created.data['receiverId'] as String,
              message: created.data['message'] as String,
              sentAt:
                  DateTime.parse(created.data['sentAt'] as String).toLocal(),
              read: created.data['read'] as bool? ?? false,
            ),
            ...state.messages,
          ],
        );
      }
      return true;
    } catch (e) {
      debugPrint('sendMessage error: $e');
      return false;
    }
  }

  Future<bool> isAlreadyFriend(String userId1, String userId2) async {
    try {
      final res = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _friendshipCollection,
        queries: [
          Query.or([
            Query.and([
              Query.equal('user1Id', userId1),
              Query.equal('user2Id', userId2),
            ]),
            Query.and([
              Query.equal('user1Id', userId2),
              Query.equal('user2Id', userId1),
            ]),
          ]),
        ],
      );
      return res.documents.isNotEmpty;
    } catch (e) {
      debugPrint('isAlreadyFriend error: $e');
      return false;
    }
  }

  Future<bool> hasPendingRequest(String senderId, String receiverId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _requestCollection,
        queries: [
          Query.equal('senderId', senderId),
          Query.equal('receiverId', receiverId),
          Query.equal('status', 'pending'),
        ],
      );
      return res.documents.isNotEmpty;
    } catch (e) {
      debugPrint('hasPendingRequest error: $e');
      return false;
    }
  }

  void clearSearchResult() {
    state = state.copyWith(searchResult: null);
  }
}

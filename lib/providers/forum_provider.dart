import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:smoking/models/forum_state.dart';
import 'package:smoking/models/user_state.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/services/appwrite_query.dart';
import 'package:smoking/services/user_document_repository.dart';

final forumPostProvider =
    StateNotifierProvider<ForumPostNotifier, ForumPostState>((ref) {
      // Narrowed so theme flips and counter ticks don't recreate the notifier
      // (and discard its `_lastLoadedAt` / `_hasMore` paging state).
      final userId = ref.watch(userProvider.select((u) => u.userId));
      return ForumPostNotifier(
        db: ref.watch(databasesProvider),
        userRepo: ref.watch(userDocRepositoryProvider),
        userId: userId,
        ref: ref,
      );
    });

class ForumPostNotifier extends StateNotifier<ForumPostState> {
  final Databases _db;
  final UserDocumentRepository _userRepo;
  final Ref _ref;
  final String _userId;
  final String _databaseId = AppwriteConfig.databaseId;
  final String _forumCollection = AppwriteCollections.forum;

  static const int _pageSize = 20;
  bool _hasMore = true;

  // Skip re-fetching the first page if the cache is still warm. Mutations
  // (`addForumPost`) pass `force: true` to invalidate.
  DateTime? _lastLoadedAt;
  static const _cacheTtl = Duration(minutes: 2);

  bool get hasMore => _hasMore;

  ForumPostNotifier({
    required Databases db,
    required UserDocumentRepository userRepo,
    required String userId,
    required Ref ref,
  })  : _db = db,
        _userRepo = userRepo,
        _userId = userId,
        _ref = ref,
        super(ForumPostState.initial()) {
    loadForumPosts();
  }

  ForumPost _docToPost(dynamic doc) => ForumPost(
        id: doc.$id,
        userId: doc.data['userId'],
        username: doc.data['username'],
        message: doc.data['message'],
        createdAt: DateTime.parse(doc.data['createdAt']).toLocal(),
        userAvatar: doc.data['userAvatar'],
      );

  Future<void> loadForumPosts({bool force = false}) async {
    if (!mounted) return;
    // In-flight guard so two concurrent callers don't double-fetch the first
    // page. `loadMore` has its own `_isLoadingMore` flag for the pagination
    // path; this is the equivalent for the initial / refresh load.
    if (state.isLoading) return;
    if (!force &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _cacheTtl &&
        state.posts.isNotEmpty) {
      return;
    }
    state = state.copyWith(isLoading: true);
    _hasMore = true;
    try {
      final posts = await listAndMap(
        _db,
        _forumCollection,
        _docToPost,
        queries: [Query.orderDesc('createdAt'), Query.limit(_pageSize)],
      );
      if (!mounted) return;
      _lastLoadedAt = DateTime.now();
      state = state.copyWith(posts: posts, isLoading: false);
      _hasMore = posts.length >= _pageSize;
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(hasError: true, isLoading: false);
    }
  }

  /// Append the next page of posts. Call this when the user scrolls near the
  /// bottom of the list. No-op if already loading, already at the end, or the
  /// list is empty (in which case `loadForumPosts` should be called instead).
  Future<void> loadMore() async {
    if (!mounted || state.isLoadingMore || !_hasMore) return;
    if (state.posts.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final newPosts = await listAndMap(
        _db,
        _forumCollection,
        _docToPost,
        queries: [
          Query.orderDesc('createdAt'),
          Query.limit(_pageSize),
          Query.cursorAfter(state.posts.last.id),
        ],
      );
      if (!mounted) return;
      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMore: false,
      );
      _hasMore = newPosts.length >= _pageSize;
    } catch (e) {
      debugPrint('forum loadMore error: $e');
      if (mounted) state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<UserState?> fetchUserProfileSnapshot(String userId) async {
    // Route through `UserDocumentRepository.getUserDoc` rather than
    // `getDocument(documentId: userId)`: the users collection is created
    // with `documentId: ID.unique()` (see `user_provider.createNewUser` and
    // `_createNewUserDocument`), so `userId` is a denormalised field, not
    // the doc id. The repo does the `listDocuments → cache → getDocument`
    // hop in one place, and second + subsequent reads of the same user are
    // single-doc fetches.
    try {
      final doc = await _userRepo.getUserDoc(userId);
      if (doc == null) return null;
      return UserState.fromAppwriteDocument(doc);
    } catch (e) {
      return null;
    }
  }

  /// Returns `true` if the post was created (Appwrite confirmed) and `false`
  /// on any failure. Callers should preserve the user's input on `false` and
  /// surface a snackbar rather than silently clearing the message.
  Future<bool> addForumPost(String message) async {
    if (message.trim().isEmpty) return false;
    try {
      // Read the current user's name + avatar off local `userProvider` state
      // instead of round-tripping to Appwrite for the same data. The user
      // doc is the source of truth, but `userState` is always populated from
      // it via `UserState.fromAppwriteDocument` and kept in sync by the
      // various notifier setters, so the local snapshot matches what a
      // listDocuments call would have returned.
      final user = _ref.read(userProvider);

      final created = await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _forumCollection,
        documentId: ID.unique(),
        data: {
          'userId': _userId,
          'username': user.name,
          'message': message,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'userAvatar': user.avatarPath,
        },
      );

      if (!mounted) return true;
      // Optimistic prepend so the new post shows up immediately. The previous
      // `loadForumPosts(force: true)` was short-circuited by the
      // `state.isLoading` in-flight guard whenever a refresh was already
      // running, leaving the user staring at a list that didn't include the
      // post they just wrote.
      state = state.copyWith(
        posts: [_docToPost(created), ...state.posts],
      );
      await updateForumPostCountInAppwrite();
      return true;
    } catch (e) {
      debugPrint('Error posting message: $e');
      if (mounted) state = state.copyWith(hasError: true);
      return false;
    }
  }

  Future<void> updateForumPostCountInAppwrite() async {
    try {
      final forumResponse = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _forumCollection,
        queries: [Query.equal('userId', _userId)],
      );

      await _userRepo.updateUserField(
        _userId,
        'numForumPosts',
        forumResponse.total,
      );
    } catch (e) {
      debugPrint('Error updating forum post count: $e');
    }
  }
}

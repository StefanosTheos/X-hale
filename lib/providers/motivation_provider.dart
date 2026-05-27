import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:smoking/models/motivation_state.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';

final motivationProvider =
    StateNotifierProvider<MotivationNotifier, MotivationsListState>((ref) {
      final userId = ref.watch(userProvider.select((u) => u.userId));
      return MotivationNotifier(
        db: ref.watch(databasesProvider),
        userId: userId,
      );
    });

class MotivationNotifier extends StateNotifier<MotivationsListState> {
  final Databases _db;
  final String _userId;
  final String _databaseId = AppwriteConfig.databaseId;
  final String _motivationCollection = AppwriteCollections.motivations;

  MotivationNotifier({required Databases db, required String userId})
    : _db = db,
      _userId = userId,
      super(MotivationsListState.initial()) {
    // Guard mirrors `challenge_provider.dart` — when the notifier is built
    // before the user document hydrates (cold start, logout flicker), the
    // userId is empty and the resulting `Query.equal('userId', '')` is
    // wasted work that also flips `state.isLoading` off without entries.
    // The factory re-creates this notifier when userId becomes non-empty.
    if (_userId.isNotEmpty) loadMotivations();
  }

  Future<void> loadMotivations() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _motivationCollection,
        queries: [Query.equal('userId', _userId)],
      );
      final motivations =
          response.documents
              .map((doc) => MotivationState.fromAppwriteDocument(doc))
              .toList();
      if (!mounted) return;
      state = state.copyWith(motivations: motivations, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        hasError: true,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Returns `true` on Appwrite success, `false` on any failure. Callers
  /// should surface a snackbar on `false` rather than silently dropping the
  /// user's input. Same contract as `forumPostProvider.addForumPost` and
  /// `friendProvider.sendMessage`.
  ///
  /// Appends to local state from the created document instead of re-fetching
  /// the full list. Previously called `loadMotivations()` on success —
  /// double the latency and a network round-trip for data we already have.
  Future<bool> addMotivation(
    String motivationText, {
    required String icon,
    required String color,
  }) async {
    if (motivationText.trim().isEmpty) return false;
    try {
      final created = await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _motivationCollection,
        documentId: ID.unique(),
        data: {
          'userId': _userId,
          'motivationText': motivationText,
          'createdAt': DateTime.now().toIso8601String(),
          'isPinned': false,
          'color': color,
          'icon': icon,
        },
      );
      if (!mounted) return true;
      // Prepend so the newest sits at the top of the unpinned section —
      // matches the forum-post insertion pattern.
      state = state.copyWith(
        motivations: [
          MotivationState.fromAppwriteDocument(created),
          ...state.motivations,
        ],
        hasError: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(hasError: true, errorMessage: e.toString());
      }
      return false;
    }
  }

  /// Returns `true` on success, `false` on failure. See [addMotivation].
  ///
  /// Optimistic flip + revert-on-failure: state mutates immediately so the
  /// pushpin icon flips without waiting for Appwrite. If the write errors,
  /// the original list is restored.
  Future<bool> togglePin(String docId, bool currentValue) async {
    final previous = state.motivations;
    state = state.copyWith(
      motivations: [
        for (final m in previous)
          if (m.id == docId) m.copyWith(isPinned: !currentValue) else m,
      ],
    );
    try {
      await _db.updateDocument(
        databaseId: _databaseId,
        collectionId: _motivationCollection,
        documentId: docId,
        data: {'isPinned': !currentValue},
      );
      return true;
    } catch (e) {
      if (mounted) {
        // Revert the optimistic flip so the UI stays in sync with Appwrite.
        state = state.copyWith(
          motivations: previous,
          hasError: true,
          errorMessage: e.toString(),
        );
      }
      return false;
    }
  }

  /// Returns `true` on success, `false` on failure. See [addMotivation].
  ///
  /// Optimistic remove + revert-on-failure. The card vanishes immediately
  /// (the Dismissible has already animated it out anyway) and only restores
  /// if the Appwrite delete fails.
  Future<bool> deleteMotivation(String docId) async {
    final previous = state.motivations;
    state = state.copyWith(
      motivations: [for (final m in previous) if (m.id != docId) m],
    );
    try {
      await _db.deleteDocument(
        databaseId: _databaseId,
        collectionId: _motivationCollection,
        documentId: docId,
      );
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          motivations: previous,
          hasError: true,
          errorMessage: e.toString(),
        );
      }
      return false;
    }
  }
}

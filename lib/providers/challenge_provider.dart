import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:smoking/models/challenge_state.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/services/user_document_repository.dart';

final challengeProvider =
    StateNotifierProvider<ChallengeNotifier, ChallengeState>((ref) {
      // Rebuild on login/logout; auto-load is handled in the notifier
      // constructor so callers can use `ref.invalidate(challengeProvider)` to
      // refresh after navigation instead of calling fetchChallenges manually.
      final userId = ref.watch(userProvider.select((u) => u.userId));
      return ChallengeNotifier(
        ref.watch(databasesProvider),
        ref.watch(userDocRepositoryProvider),
        userId,
      );
    });

/// Persists the active filter ("Ongoing" / "Completed" / "Forfeited") for the
/// `ChallengesPage` chip-row across navigation. Used to be local state on the
/// page, which snapped back to "Ongoing" every time the user opened a
/// challenge detail and returned.
final challengesFilterProvider = StateProvider<String>((ref) => 'Ongoing');

/// Memoized filtered challenge list for the `ChallengesPage` body. Watches
/// both inputs so Riverpod recomputes only when either the challenge list
/// or the filter actually changes — previously the page computed this
/// inside its `build`/`itemBuilder`, walking `state.challenges` on every
/// rebuild (progress tick, theme flip, etc.).
final filteredChallengesProvider = Provider<List<Challenge>>((ref) {
  final challenges = ref.watch(challengeProvider.select((s) => s.challenges));
  final filter = ref.watch(challengesFilterProvider);
  return challenges.where((c) {
    final status = c.status.toLowerCase();
    switch (filter) {
      case 'Completed':
        return status == 'completed';
      case 'Forfeited':
        return status == 'forfeited';
      default:
        return status == 'active' || status == 'ongoing';
    }
  }).toList();
});

class ChallengeNotifier extends StateNotifier<ChallengeState> {
  final Databases _db;
  final UserDocumentRepository _userRepo;
  final String _databaseId = AppwriteConfig.databaseId;
  final String _challengesCollection = AppwriteCollections.challenges;
  final String _entriesCollection = AppwriteCollections.challengeEntries;

  ChallengeNotifier(this._db, this._userRepo, String userId)
      : super(ChallengeState.initial()) {
    if (userId.isNotEmpty) fetchChallenges(userId);
  }

  Future<void> fetchChallenges(String userId) async {
    try {
      state = state.copyWith(isLoading: true);

      final response = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _challengesCollection,
        queries: [Query.equal('userId', userId)],
      );

      // Single batched fetch of every physical-challenge entry instead of
      // one round-trip per physical challenge. Appwrite's `Query.equal` accepts
      // a list of values, behaving as an OR filter — so M physical challenges
      // collapse to 1 entries request total. Grouped client-side by id below.
      final physicalIds = response.documents
          .where((d) => d.data['type'] == 'physical')
          .map((d) => d.$id)
          .toList();

      final entriesByChallenge = <String, List<ChallengeEntry>>{};
      if (physicalIds.isNotEmpty) {
        final entriesResponse = await _db.listDocuments(
          databaseId: _databaseId,
          collectionId: _entriesCollection,
          queries: [Query.equal('challengeId', physicalIds)],
        );
        for (final e in entriesResponse.documents) {
          final cid = e.data['challengeId'] as String;
          entriesByChallenge.putIfAbsent(cid, () => []).add(
                ChallengeEntry(
                  id: e.$id,
                  challengeId: cid,
                  userId: e.data['userId'],
                  message: e.data['message'],
                  createdAt: DateTime.parse(e.data['createdAt']),
                ),
              );
        }
      }

      final challenges = response.documents.map((doc) {
        final data = doc.data;
        final type = data['type'] as String;
        return Challenge(
          id: doc.$id,
          userId: data['userId'],
          title: data['title'],
          type: type,
          iconPath: data['icon'],
          status: data['status'],
          createdAt: DateTime.parse(data['createdAt']),
          goalBudget: (data['goalBudget'] as num?)?.toDouble(),
          progress: (data['progress'] as num?)?.toDouble(),
          lastEntry: data['lastEntry'] != null
              ? DateTime.parse(data['lastEntry'])
              : null,
          entries: type == 'physical'
              ? (entriesByChallenge[doc.$id] ?? const <ChallengeEntry>[])
              : const <ChallengeEntry>[],
          collected: (data['collected'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      state = state.copyWith(
        challenges: challenges,
        isLoading: false,
        hasError: false,
      );
    } catch (e) {
      debugPrint('Failed to fetch challenges: $e');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  /// Returns `true` on Appwrite success, `false` on any failure. Callers
  /// should surface a snackbar / dialog on `false` and preserve the user's
  /// form input rather than popping the page.
  Future<bool> addChallenge(String userId, Challenge challenge) async {
    try {
      final doc = await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _challengesCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'title': challenge.title,
          'type': challenge.type,
          'icon': challenge.iconPath,
          'status': challenge.status,
          'createdAt': DateTime.now().toIso8601String(),
          if (challenge.isFinancial) 'goalBudget': challenge.goalBudget,
          if (challenge.isFinancial) 'progress': challenge.progress ?? 0.0,
          if (challenge.isFinancial) 'collected': challenge.collected ?? 0.0,
          if (challenge.isPhysical)
            'lastEntry': challenge.lastEntry?.toIso8601String(),
        },
      );

      final newChallenge = challenge.copyWith(id: doc.$id);
      state = state.copyWith(challenges: [...state.challenges, newChallenge]);
      return true;
    } catch (e) {
      debugPrint('Failed to add challenge: $e');
      return false;
    }
  }

  Future<void> addEntryToChallenge(
    String userId,
    Challenge challenge,
    String message,
  ) async {
    try {
      final now = DateTime.now();

      final doc = await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _entriesCollection,
        documentId: ID.unique(),
        data: {
          'challengeId': challenge.id,
          'userId': userId,
          'message': message,
          'createdAt': now.toUtc().toIso8601String(),
        },
      );

      final newEntry = ChallengeEntry(
        id: doc.$id,
        challengeId: challenge.id,
        userId: userId,
        message: message,
        createdAt: now,
      );

      final updatedChallenge = challenge.copyWith(
        lastEntry: newEntry.createdAt,
        entries: [...challenge.entries, newEntry],
      );

      await _db.updateDocument(
        databaseId: _databaseId,
        collectionId: _challengesCollection,
        documentId: challenge.id,
        data: {'lastEntry': newEntry.createdAt.toIso8601String()},
      );

      _updateChallengeInState(updatedChallenge);
    } catch (e) {
      debugPrint('Failed to add entry: $e');
    }
  }

  /// Returns `true` on success, `false` on failure. See [addChallenge].
  Future<bool> updateChallenge(Challenge updated) async {
    try {
      final data = {
        'title': updated.title,
        'type': updated.type,
        'icon': updated.iconPath,
        'status': updated.status,
        if (updated.isFinancial) 'goalBudget': updated.goalBudget,
        if (updated.isFinancial) 'progress': updated.progress,
        if (updated.isFinancial) 'collected': updated.collected,
        if (updated.isPhysical)
          'lastEntry': updated.lastEntry?.toIso8601String(),
      };

      await _db.updateDocument(
        databaseId: _databaseId,
        collectionId: _challengesCollection,
        documentId: updated.id,
        data: data,
      );

      _updateChallengeInState(updated);
      return true;
    } catch (e) {
      debugPrint('Failed to update challenge: $e');
      return false;
    }
  }

  Future<void> updateChallengeStatus(String challengeId, String status) async {
    try {
      // Bail if the challenge has been deleted out from under us — e.g. the
      // financial completion listener can fire on a stale id between local
      // state updates. Previously this threw a StateError and silently
      // swallowed the rest of the method.
      final challenge =
          state.challenges.firstWhereOrNull((c) => c.id == challengeId);
      if (challenge == null) {
        debugPrint('updateChallengeStatus: challenge $challengeId not found');
        return;
      }
      final updatedChallenge = challenge.copyWith(status: status);

      await _db.updateDocument(
        databaseId: _databaseId,
        collectionId: _challengesCollection,
        documentId: challengeId,
        data: {'status': status},
      );

      _updateChallengeInState(updatedChallenge);
      if (status == 'completed') {
        if (challenge.type == 'physical') {
          await updatePhysicalChallengeCount(challenge.userId);
        } else if (challenge.type == 'financial') {
          await updateFinancialChallengeCount(challenge.userId);
        }
      }
    } catch (e) {
      debugPrint('Failed to update status: $e');
    }
  }

  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _db.deleteDocument(
        databaseId: _databaseId,
        collectionId: _challengesCollection,
        documentId: challengeId,
      );

      final updatedList =
          state.challenges.where((c) => c.id != challengeId).toList();

      state = state.copyWith(challenges: updatedList);
    } catch (e) {
      debugPrint('Failed to delete challenge: $e');
    }
  }

  Future<void> updateFinancialProgressAndStatus({
    required String userId,
    required DateTime quitDate,
    required double dailyCigaretteCost,
  }) async {
    try {
      for (final challenge in state.active) {
        if (challenge.type.toLowerCase() == 'financial') {
          final durationInDays = challenge.createdAt
              .difference(quitDate)
              .inDays
              .clamp(0, 365);
          final collected = durationInDays * dailyCigaretteCost;

          final newStatus =
              (challenge.goalBudget != null &&
                      collected >= challenge.goalBudget!)
                  ? 'completed'
                  : challenge.status;

          final needsUpdate =
              challenge.collected != collected || challenge.status != newStatus;

          if (needsUpdate) {
            // Write back to the canonical challenges collection — the legacy
            // collection it used to write to wasn't read anywhere, so the
            // dashboard never saw financial-progress updates after restart.
            // Also mirror the value into `progress` for schema consistency
            // with `addChallenge` (which seeds both fields).
            await _db.updateDocument(
              databaseId: _databaseId,
              collectionId: _challengesCollection,
              documentId: challenge.id,
              data: {
                'collected': collected,
                'progress': collected,
                'status': newStatus,
              },
            );

            final updatedChallenge = challenge.copyWith(
              collected: collected,
              status: newStatus,
            );

            _updateChallengeInState(updatedChallenge);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to update financial challenge progress: $e');
    }
  }

  void _updateChallengeInState(Challenge updated) {
    final updatedList = [
      for (final c in state.challenges)
        if (c.id == updated.id) updated else c,
    ];
    state = state.copyWith(challenges: updatedList);
  }

  Future<void> refresh(String userId) async {
    await fetchChallenges(userId);
  }

  Future<void> updatePhysicalChallengeCount(String userId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _challengesCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('type', 'physical'),
          Query.equal('status', 'completed'),
        ],
      );
      await _userRepo.updateUserField(userId, 'physicalCount', response.total);
    } catch (e) {
      debugPrint(
        'Error updating physical challenge count in challengeProvider: $e',
      );
    }
  }

  Future<void> updateFinancialChallengeCount(String userId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _challengesCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('type', 'financial'),
          Query.equal('status', 'completed'),
        ],
      );
      await _userRepo.updateUserField(userId, 'financialCount', response.total);
    } catch (e) {
      debugPrint(
        'Error updating financial challenge count in challengeProvider: $e',
      );
    }
  }
}

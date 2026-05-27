import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/models/milestone_state.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/services/user_document_repository.dart';

final milestoneProvider =
    StateNotifierProvider<MilestoneNotifier, MilestoneState>((ref) {
  // Watch userId so the notifier is torn down on logout / login-as-other-user.
  // Without this, the same `MilestoneNotifier` instance survives identity
  // changes and keeps the previous user's `completedTitles` / `allMilestones`
  // until the home page explicitly calls `initializeFromUser`. Any pre-home
  // consumer (e.g. `nextMilestoneProvider` watching `s.allMilestones`) would
  // otherwise observe the prior identity's data. Mirrors the
  // `achievementProvider`, `forumPostProvider`, `diaryProvider`,
  // `friendProvider` pattern.
  ref.watch(userProvider.select((u) => u.userId));
  return MilestoneNotifier(
    ref.watch(databasesProvider),
    ref.watch(userDocRepositoryProvider),
  );
});

/// "Next milestone" for a given tier ('Day' / 'Week' / 'Month' / 'Year'),
/// memoised by the milestone list reference. Re-runs only when the
/// underlying milestone list mutates (toggle, init, refresh) — not on every
/// 1 Hz progress-tick rebuild like the previous inline `where`/`sort` in
/// `QuitTimerSection`. Returns `null` when every milestone in that tier
/// has either been completed or become eligible.
final nextMilestoneProvider =
    Provider.family<Milestone?, String>((ref, tier) {
  final allMilestones =
      ref.watch(milestoneProvider.select((s) => s.allMilestones));
  final keyword = switch (tier) {
    'Day' => 'Day',
    'Week' => 'Week',
    'Month' => 'Month',
    'Year' => 'Year',
    _ => null,
  };
  if (keyword == null) return null;
  final unreached = allMilestones
      .where((m) => m.title.contains(keyword) && !m.completed && !m.isEligible)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return unreached.isEmpty ? null : unreached.first;
});

class MilestoneNotifier extends StateNotifier<MilestoneState> {
  final Databases _db;
  final UserDocumentRepository _userRepo;
  final String _databaseId = AppwriteConfig.databaseId;
  final String _milestoneCollection = AppwriteCollections.milestones;
  // Milestone titles whose toggle is currently in flight. A fast double-tap
  // would otherwise see `milestone.completed == false` twice (the UI hasn't
  // rebuilt between taps), and both invocations would call
  // `_addMilestoneCompletion`, creating two Appwrite docs with the same
  // label. `updateCompletedMilestoneCountInAppwrite` would then over-count.
  final Set<String> _inFlightToggles = {};

  MilestoneNotifier(this._db, this._userRepo)
    : super(MilestoneState.initial(startDate: DateTime.now(), userId: ''));

  Future<void> initializeFromUser(WidgetRef ref) async {
    final user = ref.read(userProvider);

    if (user.userId.isNotEmpty) {
      await initialize(user.quitDate, user.userId);
    } else {
      debugPrint('Cannot initialize milestones: missing userId or quitDate');
    }
  }

  Future<void> reinitializeWithNewStartDate(DateTime newStartDate) async {
    await deleteAllMilestones(state.userId);
    await initialize(newStartDate, state.userId);
  }

  Future<void> initialize(DateTime startDate, String userId) async {
    // Defense in depth: every UI picker caps the quit date at "today", but a
    // future timestamp can still arrive here via a legacy Appwrite document
    // or an external edit. Clamp silently — `MilestoneState`'s generated list
    // is computed off `startDate`, so a future date produces an entirely
    // unreachable set of milestones and the page renders empty with no
    // explanation. Clamping makes the dashboard catch up once the real quit
    // date has passed.
    final now = DateTime.now();
    final clampedStart = startDate.isAfter(now) ? now : startDate;
    state = state.copyWith(
      startDate: clampedStart,
      userId: userId,
      isLoading: true,
    );
    await _loadCompletedMilestones(clampedStart);
  }

  Future<void> _loadCompletedMilestones([DateTime? startDate]) async {
    final effectiveStartDate = startDate ?? state.startDate;

    if (state.userId.isEmpty) {
      state = state.copyWith(isLoading: false);
      debugPrint(
        'Milestones: _loadCompletedMilestones called with empty userId.',
      );
      return;
    }

    try {
      final response = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _milestoneCollection,
        queries: [Query.equal('userId', state.userId)],
      );

      final completedTitles =
          response.documents
              .map((doc) => (doc.data['label'] as String?) ?? '')
              .where((label) => label.isNotEmpty)
              .toSet();

      final generatedMilestones =
          MilestoneState(
            startDate: effectiveStartDate,
            userId: state.userId,
            completedTitles: completedTitles,
          ).generateMilestones();

      state = state.copyWith(
        startDate: effectiveStartDate,
        completedTitles: completedTitles,
        allMilestones: generatedMilestones,
        isLoading: false,
        hasError: false,
        errorMessage: null,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load milestones: ${e.toString()}',
      );
      debugPrint('Error loading milestones: $e\n$st');
    }
  }

  Future<void> toggleCompletion(Milestone milestone) async {
    if (!_inFlightToggles.add(milestone.title)) return;
    try {
      final updatedTitles = {...state.completedTitles};

      if (milestone.completed) {
        await _removeMilestoneCompletion(milestone.title);
        updatedTitles.remove(milestone.title);
      } else {
        await _addMilestoneCompletion(milestone);
        updatedTitles.add(milestone.title);
      }

      // Patch just the toggled entry instead of regenerating all 54 Milestones
      // (which would re-run all the date math and string concatenations).
      final updatedMilestones = state.allMilestones
          .map(
            (m) => m.title == milestone.title
                ? m.copyWith(completed: updatedTitles.contains(m.title))
                : m,
          )
          .toList();
      state = state.copyWith(
        completedTitles: updatedTitles,
        allMilestones: updatedMilestones,
      );
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to toggle milestone: ${e.toString()}',
      );
      debugPrint('Error toggling milestone: $e');
    } finally {
      _inFlightToggles.remove(milestone.title);
    }
  }

  Future<void> _addMilestoneCompletion(Milestone milestone) async {
    await _db.createDocument(
      databaseId: _databaseId,
      collectionId: _milestoneCollection,
      documentId: ID.unique(),
      data: {
        'userId': state.userId,
        'label': milestone.title,
        'dateReached': DateTime.now().toIso8601String(),
        'color': '#4CAF50',
      },
    );
    await updateCompletedMilestoneCountInAppwrite();
  }

  Future<void> _removeMilestoneCompletion(String title) async {
    final response = await _db.listDocuments(
      databaseId: _databaseId,
      collectionId: _milestoneCollection,
      queries: [
        Query.equal('userId', state.userId),
        Query.equal('label', title),
      ],
    );

    if (response.documents.isNotEmpty) {
      await _db.deleteDocument(
        databaseId: _databaseId,
        collectionId: _milestoneCollection,
        documentId: response.documents.first.$id,
      );
    }
    await updateCompletedMilestoneCountInAppwrite();
  }

  Future<void> deleteAllMilestones(String userId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _milestoneCollection,
        queries: [Query.equal('userId', userId)],
      );

      for (final doc in response.documents) {
        await _db.deleteDocument(
          databaseId: _databaseId,
          collectionId: _milestoneCollection,
          documentId: doc.$id,
        );
      }

      state = state.copyWith(
        completedTitles: {},
        allMilestones: state.generateMilestones(),
      );
      await updateCompletedMilestoneCountInAppwrite();
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to delete milestones: ${e.toString()}',
      );
      debugPrint('Error deleting milestones: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadCompletedMilestones();
  }

  Future<void> updateCompletedMilestoneCountInAppwrite() async {
    try {
      // Rows in the milestones collection only exist when a milestone is
      // marked completed, so the userId filter alone counts completions.
      // Previously this also filtered by `color == '#4CAF50'` — the write
      // side at `_addMilestoneCompletion` hardcodes that exact value, so the
      // filter was redundant *and* a fragile contract: any future change to
      // the write color (theming, dark-mode variant) would have silently
      // zeroed the count.
      final milestoneResponse = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _milestoneCollection,
        queries: [Query.equal('userId', state.userId)],
      );

      await _userRepo.updateUserField(
        state.userId,
        'numMilestonesCompleted',
        milestoneResponse.documents.length,
      );
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Error updating milestone count: $e',
      );
      debugPrint('Error updating milestone count: $e');
    }
  }
}

import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/constants/achievements.dart';
import 'package:smoking/models/achievement_state.dart';
import 'package:smoking/models/user_state.dart';
import 'package:smoking/providers/global_keys.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/services/user_document_repository.dart';

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, List<AchievementState>>((ref) {
      // Rebuild only on user identity change (login/logout). Counter changes
      // are handled by a ref.listen inside the notifier so we don't recreate
      // the notifier — and reset its first-eval flag — every time a stat
      // moves.
      final userId = ref.watch(userProvider.select((u) => u.userId));
      return AchievementNotifier(
        db: ref.watch(databasesProvider),
        userRepo: ref.watch(userDocRepositoryProvider),
        ref: ref,
        userId: userId,
      );
    });

class AchievementNotifier extends StateNotifier<List<AchievementState>> {
  final Databases _db;
  final UserDocumentRepository _userRepo;
  final String _dbId = AppwriteConfig.databaseId;
  final String _achievementCollectionId = AppwriteCollections.achievements;
  // Point lookup by achievement id — built once so the batched reconciliation
  // can sum points without re-walking `allAchievements` on every toggle.
  static final Map<String, int> _pointsById = {
    for (final a in allAchievements) a.id: a.points,
  };

  final Ref ref;
  final String userId;
  bool _isDisposed = false;
  bool isEvaluated = false;
  Timer? _evalDebounce;
  // Achievement ids whose Appwrite write/delete is currently in flight.
  // Closes the TOCTOU window between `state.any(...)` and the post-await
  // `state = [...]` mutation — without it, two concurrent evaluation passes
  // (or the same pass twice on a duplicate-id row) can both pass the guard
  // and both call `createDocument`/`deleteDocument`.
  final Set<String> _inFlight = {};

  AchievementNotifier({
    required Databases db,
    required UserDocumentRepository userRepo,
    required this.ref,
    required this.userId,
  }) : _db = db,
       _userRepo = userRepo,
       super([]) {
    debugPrint('AchievementNotifier started for userId: $userId');
    _init();
    // Re-evaluate whenever any counter that maps to an achievement category
    // moves. Riverpod tears the listener down with the notifier.
    ref.listen<UserState>(userProvider, (prev, next) {
      if (_isDisposed) return;
      if (!next.isInitialized) return;
      if (!_countersChanged(prev, next)) return;
      // Coalesce bursts of counter updates (e.g. a single user action that
      // bumps multiple counters) into one evaluation.
      _evalDebounce?.cancel();
      _evalDebounce = Timer(const Duration(milliseconds: 500), () {
        if (_isDisposed) return;
        evaluateAchievements(ref.read(userProvider));
      });
    });
  }

  @override
  void dispose() {
    _evalDebounce?.cancel();
    _isDisposed = true;
    super.dispose();
  }

  /// Returns true if any of the integer counters that drive achievement
  /// thresholds (see [_getUserFieldValue]) changed between [prev] and [next].
  bool _countersChanged(UserState? prev, UserState next) {
    if (prev == null) return true;
    return prev.diaryCount != next.diaryCount ||
        prev.numMilestonesCompleted != next.numMilestonesCompleted ||
        prev.numForumPosts != next.numForumPosts ||
        prev.numChatMessages != next.numChatMessages ||
        prev.numFriends != next.numFriends ||
        prev.snakeHighScore != next.snakeHighScore ||
        prev.flappyHighScore != next.flappyHighScore ||
        prev.high2048Score != next.high2048Score ||
        prev.totalWheelSpins != next.totalWheelSpins ||
        prev.physicalCount != next.physicalCount ||
        prev.financialCount != next.financialCount ||
        prev.numHealthBenefit != next.numHealthBenefit;
  }

  Future<void> _init() async {
    await loadAchievements();
    if (!_isDisposed) {
      final user = ref.read(userProvider);
      if (user.isInitialized) {
        await evaluateAchievements(user);
        isEvaluated = true;
      }
    }
  }

  Future<void> loadAchievements() async {
    try {
      final result = await _db.listDocuments(
        databaseId: _dbId,
        collectionId: _achievementCollectionId,
        queries: [Query.equal('userId', userId)],
      );

      final loaded =
          result.documents
              .map((doc) => AchievementState.fromAppwriteDocument(doc))
              .toList();

      if (!_isDisposed) state = loaded;
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  /// Write a single achievement doc and update local state. Does NOT touch
  /// the user-doc counters — call [_reconcileUserDoc] once after a batch of
  /// these (see [evaluateAchievements]).
  Future<bool> _writeAchievement(AchievementState achievement) async {
    if (state.any((a) => a.id == achievement.id)) return false;
    if (!_inFlight.add(achievement.id)) return false;
    try {
      await _db.createDocument(
        databaseId: _dbId,
        collectionId: _achievementCollectionId,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'title': achievement.title,
          'description': achievement.description,
          'achievedAt': achievement.achievedAt.toIso8601String(),
          'icon': 'default',
          'level': achievement.level,
          'targetValue': achievement.targetValue,
          'category': achievement.category,
          'achievementId': achievement.id,
        },
      );

      if (_isDisposed) return false;
      state = [...state, achievement];
      // Only surface a snackbar for unlocks that happen *after* the first
      // evaluation — the initial load shouldn't toast every historical
      // achievement.
      if (isEvaluated) {
        _showUnlockSnackBar(achievement);
      }
      return true;
    } catch (e) {
      debugPrint('Error adding achievement: $e');
      return false;
    } finally {
      _inFlight.remove(achievement.id);
    }
  }

  /// Delete a single achievement doc and update local state. Does NOT touch
  /// the user-doc counters — see [_reconcileUserDoc].
  Future<bool> _eraseAchievement(String id) async {
    if (!state.any((a) => a.id == id)) return false;
    if (!_inFlight.add(id)) return false;
    try {
      final result = await _db.listDocuments(
        databaseId: _dbId,
        collectionId: _achievementCollectionId,
        queries: [Query.equal('achievementId', id)],
      );

      if (result.documents.isEmpty) {
        debugPrint('No achievement found with achievementId: $id');
        return false;
      }

      await _db.deleteDocument(
        databaseId: _dbId,
        collectionId: _achievementCollectionId,
        documentId: result.documents.first.$id,
      );

      if (_isDisposed) return false;
      state = state.where((a) => a.id != id).toList();
      return true;
    } catch (e) {
      debugPrint('Error deleting achievement: $e');
      return false;
    } finally {
      _inFlight.remove(id);
    }
  }

  /// Push `achievementsCount` + `achievementPoints` to the user doc in one
  /// `updateDocument` call, then mirror locally. Replaces the per-add/delete
  /// fan-out of `_updateAchievementPoints` + `syncAchievementsCount` +
  /// `getUserDoc` (which was 4–5 round-trips per toggle).
  Future<void> _reconcileUserDoc() async {
    try {
      final newCount = state.length;
      var newPoints = 0;
      for (final a in state) {
        newPoints += _pointsById[a.id] ?? 0;
      }
      await _userRepo.updateUserFields(userId, {
        'achievementsCount': newCount,
        'achievementPoints': newPoints,
      });
      if (_isDisposed) return;
      ref
          .read(userProvider.notifier)
          .setAchievementMetrics(count: newCount, points: newPoints);
    } catch (e) {
      debugPrint('Error reconciling user doc after achievement evaluation: $e');
    }
  }

  void _showUnlockSnackBar(AchievementState achievement) {
    final messenger = ref.read(scaffoldMessengerKeyProvider).currentState;
    if (messenger == null) return;
    final iconAsset = switch (achievement.level) {
      'gold' => 'assets/icons/gold_trophy.png',
      'silver' => 'assets/icons/silver_trophy.png',
      _ => 'assets/icons/bronze_trophy.png',
    };
    // `ScaffoldMessenger` has a built-in snackbar queue: each call to
    // `showSnackBar` waits for the previous one's `duration` to elapse
    // before being displayed. The previous version cascaded
    // `..hideCurrentSnackBar()..showSnackBar(...)` here, which dismissed
    // both the currently-displayed achievement *and* anything still queued
    // before this one — so when several achievements unlocked together
    // (typical right after registration), only the last one in the
    // evaluation order remained visible. Letting the queue do its job
    // means every unlocked achievement gets its full 3-second window
    // before the next slides in.
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Image.asset(iconAsset, width: 28, height: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Achievement unlocked',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> evaluateAchievements(UserState user) async {
    try {
      final currentAchievementIds = state.map((a) => a.id).toSet();
      var changed = false;

      for (final achievement in allAchievements) {
        final userValue = _getUserFieldValue(user, achievement.category);
        final hasAchievement = currentAchievementIds.contains(achievement.id);
        final meetsGoal = userValue >= achievement.goal;
        if (_isDisposed) return;

        if (meetsGoal && !hasAchievement) {
          final wrote = await _writeAchievement(
            AchievementState(
              id: achievement.id,
              userId: user.userId,
              title: achievement.title,
              description: achievement.description,
              achievedAt: DateTime.now(),
              icon: 'default_achievement',
              level: achievement.level,
              targetValue: achievement.goal,
              category: achievement.category,
            ),
          );
          if (wrote) changed = true;
        } else if (!meetsGoal && hasAchievement) {
          final erased = await _eraseAchievement(achievement.id);
          if (erased) changed = true;
        }
      }

      if (changed && !_isDisposed) {
        await _reconcileUserDoc();
      }
    } catch (e) {
      debugPrint('Error evaluating achievements: $e');
    }
  }

  int _getUserFieldValue(UserState user, String category) {
    switch (category) {
      case 'Diary':
        return user.diaryCount;
      case 'Milestones':
        return user.numMilestonesCompleted;
      case 'Community':
        return user.numForumPosts;
      case 'Support':
        return user.numChatMessages;
      case 'Social':
        return user.numFriends;
      case 'SnakeGame':
        return user.snakeHighScore;
      case 'FlappyBirdGame':
        return user.flappyHighScore;
      case '2048Game':
        return user.high2048Score;
      case 'Engagement':
        return user.totalWheelSpins;
      case 'Physical':
        return user.physicalCount;
      case 'Financial':
        return user.financialCount;
      case 'Health':
        return user.numHealthBenefit;
      default:
        return 0;
    }
  }
}

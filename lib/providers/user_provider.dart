import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:smoking/models/user_state.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/services/user_document_repository.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:smoking/models/userprofile_state.dart';

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(
    ref.watch(databasesProvider),
    ref.watch(storageProvider),
    ref.watch(userDocRepositoryProvider),
  );
});

class UserNotifier extends StateNotifier<UserState> {
  final Databases _db;
  final Storage _storage;
  final UserDocumentRepository _userRepo;
  final String _databaseId = AppwriteConfig.databaseId;
  final String _userCollection = AppwriteCollections.users;
  final String _friendshipCollection = AppwriteCollections.friendships;
  final String _forumCollection = AppwriteCollections.forum;

  UserNotifier(this._db, this._storage, this._userRepo)
      : super(UserState.initial());

  Future<void> initializeUser({
    required String userId,
    required String email,
    required String name,
    String? phoneNumber,
    required String formOfConsumption,
    required String currency,
    required int cigsPerDay,
    required int cigsPerPack,
    required double pricePerPack,
    required double minutesPerCig,
    required DateTime quitDate,
    required int yearsSmoking,
  }) async {
    try {
      state = state.copyWith(
        userId: userId,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        formOfConsumption: formOfConsumption,
        selectedCurrency: currency,
        cigsPerDay: cigsPerDay,
        cigsPerPack: cigsPerPack,
        pricePerPack: pricePerPack,
        minutesPerCig: minutesPerCig,
        quitDate: quitDate,
        yearsSmoking: yearsSmoking,
        isInitialized: true,
        isLoading: true,
      );

      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal('userId', userId)],
      );

      if (result.documents.isEmpty) {
        throw Exception('User document not found');
      }

      final docId = result.documents.first.$id;

      await _db.updateDocument(
        databaseId: _databaseId,
        collectionId: _userCollection,
        documentId: docId,
        data: {
          'userId': userId,
          'email': email,
          'name': name,
          'phoneNumber': phoneNumber,
          'formOfConsumption': formOfConsumption,
          'selectedCurrency': currency,
          'cigarettesPerDay': cigsPerDay,
          'cigarettesPerPack': cigsPerPack,
          'pricePerPack': pricePerPack,
          'timePerCigarette': minutesPerCig,
          'quitDate': quitDate.toIso8601String(),
          'yearsSmoking': yearsSmoking,
          'isInitialized': true,
        },
      );

      state = state.copyWith(isLoading: false);

      debugPrint('User initialized and saved to Appwrite successfully');
    } catch (e) {
      debugPrint('Error initializing user: $e');
      state = state.copyWith(isLoading: false, hasError: true);
      rethrow;
    }
  }

  Future<bool> checkIfUsernameExists(String username) async {
    try {
      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal('name', username)],
      );
      return result.documents.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if username exists: $e');
      return false;
    }
  }

  Future<bool> checkIfPhoneExists(String phone) async {
    try {
      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal('phoneNumber', phone)],
      );
      return result.documents.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if phone exists: $e');
      return false;
    }
  }

  Future<bool> checkIfUserExistsByEmail(String email) async {
    try {
      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal('email', email)],
      );
      return result.documents.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user exists by email: $e');
      return false;
    }
  }

  Future<void> fetchUserDataByEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal('email', email)],
      );

      if (result.documents.isEmpty) {
        throw Exception('User not found by email');
      }

      final doc = result.documents.first;
      final userId = doc.data['userId'] ?? '';

      state = UserState.fromAppwriteDocument(
        doc,
      ).copyWith(userId: userId, isInitialized: true, isLoading: false);
    } catch (e) {
      debugPrint('Fetch user by email error: $e');
      state = state.copyWith(isLoading: false, hasError: true);
      rethrow;
    }
  }

  Future<bool> checkIfUserExists(String userId) async {
    try {
      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal('userId', userId)],
      );
      return result.documents.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

  Future<void> createNewUser({
    required String userId,
    required String email,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _userCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'email': email,
          'name': name,
          'phoneNumber': phoneNumber,
          'formOfConsumption': 'cigarettes',
          'selectedCurrency': '€',
          'cigarettesPerDay': 10,
          'cigarettesPerPack': 20,
          'pricePerPack': 5.0,
          'timePerCigarette': 5.0,
          'quitDate': DateTime.now().toUtc().toIso8601String(),
          'yearsSmoking': 0,
          'isInitialized': false,
          'hasSamsungHealth': false,
        },
      );
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }

  Future<void> fetchUserData(String userId, {int retries = 0}) async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal('userId', userId)],
      );

      if (result.documents.isEmpty) {
        // Bound the recursion: if a document still isn't visible after one
        // create + refetch, give up rather than looping forever.
        if (retries >= 1) {
          debugPrint(
            'fetchUserData: user doc still missing after $retries retries',
          );
          state = state.copyWith(isLoading: false, hasError: true);
          return;
        }
        await _createNewUserDocument(userId);
        await fetchUserData(userId, retries: retries + 1);
        return;
      }

      final doc = result.documents.first;
      state = UserState.fromAppwriteDocument(
        doc,
      ).copyWith(userId: userId, isInitialized: true);
    } catch (e) {
      debugPrint('Fetch user error: $e');
      state = state.copyWith(isLoading: false, hasError: true);
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal('userId', userId)],
      );

      if (result.documents.isEmpty) {
        debugPrint('No user profile found for userId: $userId');
        return null;
      }

      final data = result.documents.first.data;
      return UserProfile.fromMap(data);
    } catch (e) {
      debugPrint('getUserProfileById error: $e');
      return null;
    }
  }

  Future<void> _updateDocument(Map<String, dynamic> data) async {
    if (state.userId.isEmpty) return;
    try {
      await _userRepo.updateUserFields(state.userId, data);
    } catch (e) {
      debugPrint('Update document failed: $e');
      rethrow;
    }
  }

  /// Optimistically apply [apply] to local state, then attempt the Appwrite
  /// write. On failure, revert local state to the pre-call snapshot and
  /// rethrow so the caller can react. Closes the silent-drift gap where a
  /// failed write would otherwise leave the UI showing a value that never
  /// landed in Appwrite — the next `reloadUser` would silently revert it.
  Future<void> _optimisticUpdate(
    UserState Function(UserState previous) apply,
    Map<String, dynamic> data,
  ) async {
    final previous = state;
    state = apply(state);
    try {
      await _updateDocument(data);
    } catch (_) {
      if (mounted) state = previous;
      rethrow;
    }
  }

  Future<void> updateWheelSpin() async {
    final now = DateTime.now().toUtc();
    final newTotal = (state.totalWheelSpins) + 1;
    await _optimisticUpdate(
      (s) => s.copyWith(lastWheelSpin: now, totalWheelSpins: newTotal),
      {
        'lastWheelSpin': now.toIso8601String(),
        'totalWheelSpins': newTotal,
      },
    );
  }

  Future<void> updateName(String newName) async {
    await _optimisticUpdate(
      (s) => s.copyWith(name: newName),
      {'name': newName},
    );
    // Forum-post bulk resync is fire-and-forget by design. Awaiting it
    // here means the caller (e.g. `editUsername` on the account page) is
    // blocked through `Future.wait` over every forum doc — that gave us a
    // window where the edit-username dialog was unmounting while the
    // wide-fan-out rebuild from the `userProvider` state change was still
    // in progress, tripping a `_dependents.isEmpty` framework assertion
    // during the dialog's deactivate-then-unmount sequence. With
    // `unawaited`, the immediate user-facing path is just the local state
    // update; historical forum posts catch up in the background.
    unawaited(_resyncForumAuthorFields(username: newName));
  }

  Future<void> updateAvatar(String newAvatarPath) async {
    await _optimisticUpdate(
      (s) => s.copyWith(avatarPath: newAvatarPath),
      {'profileIcon': newAvatarPath},
    );
    unawaited(_resyncForumAuthorFields(userAvatar: newAvatarPath));
  }

  /// Upload a picked-from-gallery image to Appwrite Storage and persist the
  /// resulting public URL on the user document. Replaces the old code path
  /// that saved `XFile.path` directly — those device-local paths broke when
  /// the user signed in on another device.
  Future<void> updateAvatarFromFile(String filePath) async {
    final file = await _storage.createFile(
      bucketId: AppwriteConfig.userAvatarsBucketId,
      fileId: ID.unique(),
      file: InputFile.fromPath(path: filePath),
    );
    final url = AppwriteConfig.fileViewUrl(
      AppwriteConfig.userAvatarsBucketId,
      file.$id,
    );
    await _optimisticUpdate(
      (s) => s.copyWith(avatarPath: url),
      {'profileIcon': url},
    );
    unawaited(_resyncForumAuthorFields(userAvatar: url));
  }

  /// Forum posts denormalise `username` and `userAvatar` at write time (see
  /// `forum_provider.addForumPost`), so changing the user's profile leaves
  /// historical posts displaying stale values until they're rewritten.
  /// Bulk-update every post by this user with the new field(s). Pass only
  /// the fields that changed; nothing is sent for null parameters.
  Future<void> _resyncForumAuthorFields({
    String? username,
    String? userAvatar,
  }) async {
    if (username == null && userAvatar == null) return;
    final userId = state.userId;
    if (userId.isEmpty) return;
    try {
      final res = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _forumCollection,
        queries: [Query.equal('userId', userId)],
      );
      final patch = <String, dynamic>{
        if (username != null) 'username': username,
        if (userAvatar != null) 'userAvatar': userAvatar,
      };
      // Fire updates in parallel — the user might have many historical
      // posts and serial awaits would feel laggy on the settings page.
      await Future.wait(
        res.documents.map(
          (d) => _db.updateDocument(
            databaseId: _databaseId,
            collectionId: _forumCollection,
            documentId: d.$id,
            data: patch,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Forum author resync failed: $e');
    }
  }

  Future<void> updatequitDate(DateTime newquitDate) async {
    // Defense in depth: every UI date picker caps `lastDate` to today, but a
    // future date sneaking in through some other path (legacy data, manual
    // Appwrite edit) would produce a permanently-zeroed dashboard via
    // `ProgressState.calculateFromUser`. Clamp to "now" so the UI catches up
    // the instant the quit date has passed.
    final now = DateTime.now().toUtc();
    final utcDate = newquitDate.toUtc();
    final clamped = utcDate.isAfter(now) ? now : utcDate;
    await _optimisticUpdate(
      (s) => s.copyWith(quitDate: clamped),
      {'quitDate': clamped.toIso8601String()},
    );
  }

  Future<void> updateMail(String newMail) async {
    await _optimisticUpdate(
      (s) => s.copyWith(email: newMail),
      {'email': newMail},
    );
  }

  Future<void> updatePhone(String phone) async {
    await _optimisticUpdate(
      (s) => s.copyWith(phoneNumber: phone),
      {'phoneNumber': phone},
    );
  }

  Future<bool> toggleNotifications(bool enabled) async {
    if (enabled) {
      final status = await perm.Permission.notification.request();
      if (!status.isGranted) return false;
    }
    try {
      await _optimisticUpdate(
        (s) => s.copyWith(notifications: enabled),
        {'notifications': enabled},
      );
      return true;
    } catch (_) {
      // _optimisticUpdate already reverted local state.
      return false;
    }
  }

  Future<void> updateTheme(String newtheme) async {
    await _optimisticUpdate(
      (s) => s.copyWith(theme: newtheme),
      {'theme': newtheme},
    );
  }

  Future<void> updateSettings({
    int? cigsPerDay,
    int? cigsPerPack,
    double? pricePerPack,
    int? yearsSmoking,
    double? minutesPerCig,
    String? formOfConsumption,
    String? selectedCurrency,
  }) async {
    final previous = state;
    state = state.copyWith(
      cigsPerDay: cigsPerDay ?? state.cigsPerDay,
      cigsPerPack: cigsPerPack ?? state.cigsPerPack,
      pricePerPack: pricePerPack ?? state.pricePerPack,
      yearsSmoking: yearsSmoking ?? state.yearsSmoking,
      minutesPerCig: minutesPerCig ?? state.minutesPerCig,
      formOfConsumption: formOfConsumption ?? state.formOfConsumption,
      selectedCurrency: selectedCurrency ?? state.selectedCurrency,
    );
    // Was fire-and-forget — a crash before the network call resolved silently
    // dropped the user's setting change. Await so the caller can surface a
    // failure (and so the success snackbar can't fire before the write lands).
    try {
      await _syncWithAppwrite();
    } catch (_) {
      if (mounted) state = previous;
      rethrow;
    }
  }

  Future<void> _createNewUserDocument(String userId) async {
    try {
      await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _userCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'email': '',
          'name': 'New User',
          'formOfConsumption': 'cigarettes',
          'selectedCurrency': '€',
          'cigarettesPerDay': 10,
          'cigarettesPerPack': 20,
          'pricePerPack': 5.0,
          'timePerCigarette': 5.0,
          'quitDate': DateTime.now().toUtc().toIso8601String(),
          'isInitialized': false,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'hasSamsungHealth': false,
        },
      );
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }

  Future<void> _syncWithAppwrite() async {
    if (state.userId.isEmpty) return;
    try {
      await _userRepo.updateUserFields(state.userId, {
        'cigarettesPerDay': state.cigsPerDay,
        'cigarettesPerPack': state.cigsPerPack,
        'pricePerPack': state.pricePerPack,
        'timePerCigarette': state.minutesPerCig,
        'formOfConsumption': state.formOfConsumption,
        'selectedCurrency': state.selectedCurrency,
        'name': state.name,
        'email': state.email,
        'theme': state.theme,
        // `language` is intentionally omitted. The Appwrite `users`
        // collection validates `language` as a strict-enum attribute whose
        // allowed values don't include the local default `'en'`, and there
        // is no language picker UI anywhere in the app — `state.language`
        // is `'en'` for every user. Including it here was making every
        // smoking-prefs save fail with
        // `Attribute language has invalid format`. The field stays on
        // `UserState` for future i18n work; it just isn't persisted.
        'notifications': state.notifications,
        'profileIcon': state.avatarPath,
        'isInitialized': state.isInitialized,
        'quitDate': state.quitDate.toUtc().toIso8601String(),
        'hasSamsungHealth': state.hasSamsungHealth,
      });
    } catch (e) {
      // Rethrow so callers (e.g. `updateSettings`) can surface the failure to
      // the user and revert optimistic local state. Swallowing here previously
      // let the success snackbar fire even when the write never landed.
      debugPrint('Sync failed: $e');
      rethrow;
    }
  }

  Future<void> updateSnakeHighScore(int newScore) async {
    await _optimisticUpdate(
      (s) => s.copyWith(snakeHighScore: newScore),
      {'snakeHighScore': newScore},
    );
  }

  Future<void> updateFlappyHighScore(int newScore) async {
    await _optimisticUpdate(
      (s) => s.copyWith(flappyHighScore: newScore),
      {'flappyHighScore': newScore},
    );
  }

  Future<void> update2048HighScore(int newScore) async {
    await _optimisticUpdate(
      (s) => s.copyWith(high2048Score: newScore),
      {'high2048Score': newScore},
    );
  }

  Future<void> updateNumFriends(String userId, int change) async {
    try {
      final newCount = state.numFriends + change;
      await _userRepo.updateUserField(userId, 'numFriends', newCount);

      if (userId == state.userId) {
        state = state.copyWith(numFriends: newCount);
      }

      debugPrint(
        'Successfully updated numFriends to $newCount for user $userId',
      );
    } catch (e) {
      debugPrint('Error updating numFriends: $e');
      rethrow;
    }
  }

  Future<void> syncNumFriends(String userId) async {
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
      final realCount = res.documents.length;
      await _userRepo.updateUserField(userId, 'numFriends', realCount);

      if (userId == state.userId) {
        state = state.copyWith(numFriends: realCount);
      }

      debugPrint("Synced numFriends = $realCount for user $userId");
    } catch (e) {
      debugPrint("Error syncing numFriends: $e");
    }
  }

  /// Reconcile every cached count on the user document against the actual
  /// per-collection counts in one batched round-trip. Issues the 5
  /// `listDocuments` queries in parallel via [Future.wait] and writes the
  /// results in a single `updateUserFields` call instead of 5 sequential
  /// write trips.
  ///
  /// Use this when something might have drifted (e.g. app startup after a
  /// long suspend) — the per-event syncs ([syncNumFriends],
  /// [syncAchievementsCount], etc.) are still the right tool for narrow
  /// updates after a single user action.
  Future<void> syncAllUserCounts(String userId) async {
    if (userId.isEmpty) return;
    try {
      // Wrap each query in `_safeList` so a single failure (e.g. one
      // collection 401s under stale permissions) doesn't abort the whole
      // batch and silently leave the other four counters un-synced.
      // Successful results update their field; failures fall through.
      final results = await Future.wait([
        _safeList(
          () => _db.listDocuments(
            databaseId: _databaseId,
            collectionId: _friendshipCollection,
            queries: [
              Query.or([
                Query.equal('user1Id', userId),
                Query.equal('user2Id', userId),
              ]),
            ],
          ),
          'friendships',
        ),
        _safeList(
          () => _db.listDocuments(
            databaseId: _databaseId,
            collectionId: AppwriteCollections.achievements,
            queries: [Query.equal('userId', userId)],
          ),
          'achievements',
        ),
        _safeList(
          () => _db.listDocuments(
            databaseId: _databaseId,
            collectionId: AppwriteCollections.challenges,
            queries: [
              Query.equal('userId', userId),
              Query.equal('type', 'physical'),
              Query.equal('status', 'completed'),
            ],
          ),
          'physical-challenges',
        ),
        _safeList(
          () => _db.listDocuments(
            databaseId: _databaseId,
            collectionId: AppwriteCollections.challenges,
            queries: [
              Query.equal('userId', userId),
              Query.equal('type', 'financial'),
              Query.equal('status', 'completed'),
            ],
          ),
          'financial-challenges',
        ),
        _safeList(
          () => _db.listDocuments(
            databaseId: _databaseId,
            collectionId: AppwriteCollections.healthBenefits,
            queries: [Query.equal('userId', userId)],
          ),
          'health-benefits',
        ),
      ]);

      final fieldsToWrite = <String, dynamic>{};
      final stateUpdates = <String, dynamic>{};

      final friendsRes = results[0];
      if (friendsRes != null) {
        final n = friendsRes.documents.length;
        fieldsToWrite['numFriends'] = n;
        stateUpdates['numFriends'] = n;
      }

      final achRes = results[1];
      if (achRes != null) {
        fieldsToWrite['achievementsCount'] = achRes.total;
        stateUpdates['achievementsCount'] = achRes.total;
      }

      final physRes = results[2];
      if (physRes != null) {
        fieldsToWrite['physicalCount'] = physRes.total;
        stateUpdates['physicalCount'] = physRes.total;
      }

      final finRes = results[3];
      if (finRes != null) {
        fieldsToWrite['financialCount'] = finRes.total;
        stateUpdates['financialCount'] = finRes.total;
      }

      final hbRes = results[4];
      if (hbRes != null) {
        int numHealthBenefit = 0;
        if (hbRes.documents.isNotEmpty) {
          final achievedList = hbRes.documents.first.data['achievedBenefits']
                  as List<dynamic>? ??
              const [];
          numHealthBenefit = achievedList.length;
        }
        fieldsToWrite['numHealthBenefit'] = numHealthBenefit;
        stateUpdates['numHealthBenefit'] = numHealthBenefit;
      }

      if (fieldsToWrite.isEmpty) return;
      await _userRepo.updateUserFields(userId, fieldsToWrite);

      if (userId == state.userId) {
        state = state.copyWith(
          numFriends:
              stateUpdates['numFriends'] as int? ?? state.numFriends,
          achievementsCount: stateUpdates['achievementsCount'] as int? ??
              state.achievementsCount,
          physicalCount:
              stateUpdates['physicalCount'] as int? ?? state.physicalCount,
          financialCount: stateUpdates['financialCount'] as int? ??
              state.financialCount,
          numHealthBenefit: stateUpdates['numHealthBenefit'] as int? ??
              state.numHealthBenefit,
        );
      }

      debugPrint('Synced user counts for $userId: $fieldsToWrite');
    } catch (e) {
      debugPrint('Error syncing all user counts: $e');
    }
  }

  /// Wrap an Appwrite `listDocuments` future so a failure logs and returns
  /// null instead of bubbling out of the `Future.wait` in
  /// [syncAllUserCounts]. Lets partial successes still update their fields.
  Future<models.DocumentList?> _safeList(
    Future<models.DocumentList> Function() run,
    String label,
  ) async {
    try {
      return await run();
    } catch (e) {
      debugPrint('syncAllUserCounts: $label failed: $e');
      return null;
    }
  }

  Future<void> syncAchievementsCount(String userId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: AppwriteCollections.achievements,
        queries: [Query.equal('userId', userId)],
      );
      final realCount = res.documents.length;
      await _userRepo.updateUserField(userId, 'achievementsCount', realCount);

      if (userId == state.userId) {
        state = state.copyWith(achievementsCount: realCount);
      }

      debugPrint("Synced achievementsCount = $realCount for user $userId");
    } catch (e) {
      debugPrint("Error syncing achievementsCount: $e");
    }
  }

  Future<void> addAchievementPoints(int points) async {
    final updatedPoints = (state.achievementPoints) + points;

    state = state.copyWith(achievementPoints: updatedPoints);

    await _updateDocument({'achievementPoints': updatedPoints});
  }

  /// Sync the cached achievement-point total against an already-written value
  /// (typically read straight from the user document after the achievement
  /// notifier mutated it on the server). Local-only — no Appwrite write —
  /// because the caller is reconciling, not committing a new total.
  void setAchievementPoints(int points) {
    state = state.copyWith(achievementPoints: points);
  }

  /// Local-only setter that mirrors a single user-doc write that already
  /// committed both fields. Used by the achievement notifier's batched
  /// reconciliation so it doesn't have to call [syncAchievementsCount]
  /// (which would do its own list+write trip) followed by [setAchievementPoints].
  void setAchievementMetrics({required int count, required int points}) {
    state = state.copyWith(
      achievementsCount: count,
      achievementPoints: points,
    );
  }

  Future<void> reloadUser() async {
    try {
      if (state.userId.isEmpty) return;

      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal('userId', state.userId)],
      );

      if (result.documents.isEmpty) {
        debugPrint('No user document found for reloadUser');
        return;
      }

      final doc = result.documents.first;

      state = UserState.fromAppwriteDocument(
        doc,
      ).copyWith(userId: state.userId, isInitialized: true);
    } catch (e) {
      debugPrint('Error in reloadUser: $e');
    }
  }

  Future<void> logout() async {
    // Drop the device's FCM token so any pushes addressed to it after the
    // user signs out have nowhere to go. A fresh token is minted on next
    // login by the auth flow's `registerPushTarget`.
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('logout: FCM deleteToken failed (non-fatal): $e');
    }
    state = UserState.initial();
  }

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  Future<void> updateSamsungHealthStatus(bool hasSamsungHealth) async {
    try {
      state = state.copyWith(hasSamsungHealth: hasSamsungHealth);

      await _updateDocument({'hasSamsungHealth': hasSamsungHealth});

      debugPrint('Samsung Health status updated to: $hasSamsungHealth');
    } catch (e) {
      debugPrint('Error updating Samsung Health status: $e');
      rethrow;
    }
  }
}

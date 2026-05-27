import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/constants/health_benefits.dart';
import 'package:smoking/models/healthbenefits_state.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/services/user_document_repository.dart';

final healthBenefitsProvider =
    StateNotifierProvider<HealthBenefitsNotifier, HealthBenefitsState>((ref) {
      // Only rebuild on identity / quit-date changes. Records compare by
      // value, so unrelated user-state edits (theme, counters) don't
      // recreate the notifier.
      final identity =
          ref.watch(userProvider.select((u) => (u.userId, u.quitDate)));
      return HealthBenefitsNotifier(
        db: ref.watch(databasesProvider),
        userRepo: ref.watch(userDocRepositoryProvider),
        quitDate: identity.$2,
        userId: identity.$1,
        ref: ref,
      );
    });

class HealthBenefitsNotifier extends StateNotifier<HealthBenefitsState> {
  final Databases _db;
  final UserDocumentRepository _userRepo;
  final String _databaseId = AppwriteConfig.databaseId;
  final String _collectionId = AppwriteCollections.healthBenefits;
  final Ref ref;

  HealthBenefitsNotifier({
    required Databases db,
    required UserDocumentRepository userRepo,
    required DateTime quitDate,
    required String userId,
    required this.ref,
  }) : _db = db,
       _userRepo = userRepo,
       super(HealthBenefitsState(userId: userId, quitDate: quitDate)) {
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final userId = ref.read(userProvider).userId;
      if (userId.isEmpty) return;

      final result = await _db.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: userId,
      );

      if (mounted) {
        state = HealthBenefitsState.fromAppwrite(result.data);
      }
      await updateHealthBenefitsCountInAppwrite(userId);
    } catch (e) {
      debugPrint('Unexpected error loading achievements: $e');
    }
  }

  Future<void> _saveToAppwrite() async {
    try {
      final userId = state.userId;

      if (userId.isEmpty) return;

      final data = state.toAppwrite();

      await _db.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: userId,
        data: data,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        final data = state.toAppwrite();

        await _db.createDocument(
          databaseId: _databaseId,
          collectionId: _collectionId,
          documentId: state.userId,
          data: data,
        );
      } else {
        debugPrint('Error saving achievements: ${e.message}');
      }
    } catch (e) {
      debugPrint('Unexpected error saving achievements: $e');
    }
  }

  Future<void> checkAchievements() async {
    final userId = ref.read(userProvider).userId;
    final newAchievements = <String>[];
    final currentTime = DateTime.now();

    for (final benefit in HealthBenefits.allBenefits) {
      final benefitId = benefit['id'];
      if (!state.hasAchieved(benefitId)) {
        if (currentTime.isAfter(state.completionDateFor(benefitId))) {
          newAchievements.add(benefitId);
        }
      }
    }

    if (newAchievements.isNotEmpty) {
      state = state.copyWith(
        achievedBenefits: [...state.achievedBenefits, ...newAchievements],
      );
      await _saveToAppwrite();
      await updateHealthBenefitsCountInAppwrite(userId);
    }
  }

  Future<void> updateHealthBenefitsCountInAppwrite(String userId) async {
    // The health-benefits collection is keyed by `userId` (see
    // `_saveToAppwrite` + the 404-fallback path above, both of which write
    // / create with `documentId: userId`), so this is a point lookup, not a
    // scan. Previously this used `listDocuments(Query.equal('userId', …))`
    // — table scan instead of get-by-id, and the not-found branch could
    // fire even when the doc existed if the `userId` field ever fell out
    // of sync with the document ID.
    //
    // 404 on `getDocument` propagates as an `AppwriteException` with the
    // original cause intact (network, permission, etc. all surface
    // unchanged) — same behaviour as before, just without the wasted scan.
    final doc = await _db.getDocument(
      databaseId: _databaseId,
      collectionId: _collectionId,
      documentId: userId,
    );

    final achievedList = doc.data['achievedBenefits'] as List<dynamic>;
    await _userRepo.updateUserField(
      userId,
      'numHealthBenefit',
      achievedList.length,
    );
  }

  Future<void> resetBenefits(DateTime newQuitDate) async {
    final userId = ref.read(userProvider).userId;
    state = state.copyWith(quitDate: newQuitDate, achievedBenefits: []);
    await _saveToAppwrite();
    await updateHealthBenefitsCountInAppwrite(userId);
  }
}

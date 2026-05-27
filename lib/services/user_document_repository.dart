import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:smoking/services/appwrite_config.dart';

/// Helper around the user collection that hides the repeated
/// `listDocuments → first.$id → updateDocument` dance from every notifier.
///
/// One instance per notifier (cheap — just a Map + a `Databases` reference);
/// the userId-to-docId cache is per-instance so logged-in user is hit once
/// and then cached for the lifetime of the notifier.
class UserDocumentRepository {
  final Databases _db;
  final Map<String, String> _docIdCache = {};

  UserDocumentRepository(this._db);

  Future<String?> getUserDocId(String userId) async {
    if (userId.isEmpty) return null;
    final cached = _docIdCache[userId];
    if (cached != null) return cached;

    final result = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteCollections.users,
      queries: [Query.equal('userId', userId)],
    );
    if (result.documents.isEmpty) return null;

    final docId = result.documents.first.$id;
    _docIdCache[userId] = docId;
    return docId;
  }

  Future<models.Document?> getUserDoc(String userId) async {
    // Reuse `getUserDocId` so both lookups share one cache-then-list path
    // (was previously duplicated here as `listDocuments → first.$id → cache
    // write`). With the docId resolved we issue a single-doc `getDocument`
    // — cheaper than `listDocuments` once the cache is warm.
    final docId = await getUserDocId(userId);
    if (docId == null) return null;
    try {
      return await _db.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteCollections.users,
        documentId: docId,
      );
    } on AppwriteException catch (e) {
      // Cached id no longer points to a live doc (deleted / recreated).
      // Drop the stale entry; the next call resolves from scratch.
      if (e.code == 404) {
        _docIdCache.remove(userId);
        return null;
      }
      rethrow;
    }
  }

  Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final docId = await getUserDocId(userId);
    if (docId == null) {
      debugPrint('UserDocumentRepository: no document for userId=$userId');
      return;
    }
    await _db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteCollections.users,
      documentId: docId,
      data: data,
    );
  }

  Future<void> updateUserField(
    String userId,
    String field,
    dynamic value,
  ) {
    return updateUserFields(userId, {field: value});
  }
}

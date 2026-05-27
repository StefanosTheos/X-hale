import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:smoking/services/appwrite_config.dart';

/// One-shot `listDocuments → map(parse) → toList` for the canonical
/// X-hale database. Replaces the same three-line incantation that every
/// notifier had to write per fetch.
///
/// ```dart
/// final entries = await listAndMap(
///   _db,
///   AppwriteCollections.diary,
///   DiaryEntry.fromAppwriteDocument,
///   queries: [Query.equal('userId', userId)],
/// );
/// ```
///
/// The `queries` parameter accepts whatever the Appwrite SDK expects — pass
/// `null` (the default) for an unfiltered list.
Future<List<T>> listAndMap<T>(
  Databases db,
  String collectionId,
  T Function(models.Document doc) parse, {
  List<String>? queries,
}) async {
  final response = await db.listDocuments(
    databaseId: AppwriteConfig.databaseId,
    collectionId: collectionId,
    queries: queries,
  );
  return response.documents.map(parse).toList();
}

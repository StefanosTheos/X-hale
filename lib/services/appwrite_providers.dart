import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/user_document_repository.dart';

/// Single shared Appwrite [Client] for the whole app. Notifiers used to each
/// instantiate their own (11 duplicate clients) — now there is exactly one.
final appwriteClientProvider = Provider<Client>((ref) {
  return Client()
    ..setEndpoint(AppwriteConfig.endpoint)
    ..setProject(AppwriteConfig.projectId);
});

final databasesProvider = Provider<Databases>((ref) {
  return Databases(ref.watch(appwriteClientProvider));
});

final accountProvider = Provider<Account>((ref) {
  return Account(ref.watch(appwriteClientProvider));
});

final storageProvider = Provider<Storage>((ref) {
  return Storage(ref.watch(appwriteClientProvider));
});

/// Shared [UserDocumentRepository] so the per-user doc-id cache is hit once
/// per session, not once per notifier. Seven notifiers used to instantiate
/// their own repo (and pay seven `listDocuments` round-trips for the same
/// user on cold start); now they all share this one.
final userDocRepositoryProvider = Provider<UserDocumentRepository>((ref) {
  return UserDocumentRepository(ref.watch(databasesProvider));
});

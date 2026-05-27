import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';

final messageRepositoryProvider = Provider((ref) {
  return MessageRepository(ref.watch(databasesProvider));
});

class MessageRepository {
  final Databases _databases;

  MessageRepository(this._databases);

  Future<void> sendMessage({
    required String userId,
    required String message,
  }) async {
    try {
      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteCollections.messagesMisc,
        documentId: ID.unique(),
        data: {'userId': userId, 'message': message},
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}

final messageControllerProvider =
    StateNotifierProvider<MessageController, void>((ref) {
      final repository = ref.read(messageRepositoryProvider);
      return MessageController(repository);
    });

class MessageController extends StateNotifier<void> {
  final MessageRepository _repository;
  MessageController(this._repository) : super(null);

  Future<void> sendMessage({
    required String userId,
    required String message,
  }) async {
    await _repository.sendMessage(userId: userId, message: message);
  }
}

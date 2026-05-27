import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smoking/models/chat_message.dart';

class ChatService {
  static const String baseUrl = 'https://a1dc-31-217-173-116.ngrok-free.app';

  static Future<String> sendMessage({
    required String text,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'input': text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final res = data['response'];
      return res is String ? res : res.toString();
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  static Future<List<ChatMessage>> loadMessages(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/history/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> history = data['history'];

      final messages =
          history.map((msg) {
            return ChatMessage(
              content: msg['content'],
              isUser: msg['role'] == 'user',
              timestamp: DateTime.parse(msg['timestamp']).toLocal(),
            );
          }).toList();

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    } else {
      throw Exception('Failed to load messages');
    }
  }

  static Future<void> clearHistory({required String userId}) async {
    final response = await http.delete(Uri.parse('$baseUrl/history/$userId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to clear history');
    }
  }

  static Future<void> saveMessage({
    required String userId,
    required ChatMessage message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/save/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'content': message.content,
        'role': message.isUser ? 'user' : 'ai',
        'timestamp': message.timestamp.toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save message');
    }
  }
}

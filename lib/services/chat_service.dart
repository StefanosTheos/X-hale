import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smoking/models/chat_message.dart';

// ---------------------------------------------------------------------------
// SSE event types from the Hailey backend
// ---------------------------------------------------------------------------

sealed class HaileyEvent {}

class HaileyStatusEvent extends HaileyEvent {
  /// One of: triaging | loading_context | searching_kb | composing | saving
  final String state;
  HaileyStatusEvent(this.state);
}

class HaileyTokenEvent extends HaileyEvent {
  final String token;
  HaileyTokenEvent(this.token);
}

class HaileyDoneEvent extends HaileyEvent {
  final String turnId;
  final List<Map<String, dynamic>> citations;
  final List<Map<String, dynamic>> deeplinks;
  HaileyDoneEvent({
    required this.turnId,
    required this.citations,
    required this.deeplinks,
  });
}

class HaileyErrorEvent extends HaileyEvent {
  final String code;
  final String message;
  HaileyErrorEvent(this.code, this.message);
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class ChatService {
  /// Set at build time via --dart-define=HAILEY_API_URL=https://...
  /// Defaults to Android emulator localhost for local dev.
  static const String _baseUrl = String.fromEnvironment(
    'HAILEY_API_URL',
    defaultValue: 'http://10.0.2.2:7860',
  );

  static Map<String, String> _headers(String jwt) => {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $jwt',
        'Cache-Control': 'no-cache',
      };

  // -------------------------------------------------------------------------
  // Chat — SSE streaming
  // -------------------------------------------------------------------------

  /// Sends [message] to the backend and yields [HaileyEvent]s as they arrive.
  /// The caller must hold an Appwrite JWT in [jwt].
  static Stream<HaileyEvent> sendMessageStream({
    required String message,
    required String jwt,
    String locale = 'en',
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/'));
      request.headers.addAll(_headers(jwt));
      request.body = jsonEncode({'message': message, 'locale': locale});

      final response = await client.send(request);

      if (response.statusCode == 401) {
        yield HaileyErrorEvent('unauthorized', 'Session expired. Please sign in again.');
        return;
      }
      if (response.statusCode != 200) {
        yield HaileyErrorEvent(
          'http_${response.statusCode}',
          'Server returned ${response.statusCode}',
        );
        return;
      }

      String currentEvent = '';
      final lineBuffer = StringBuffer();

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        lineBuffer.write(chunk);
        final raw = lineBuffer.toString();
        lineBuffer.clear();

        // Split into lines; hold the last (potentially incomplete) line
        final lines = raw.split('\n');
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();

          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            final dataStr = line.substring(5).trim();
            try {
              final json = jsonDecode(dataStr) as Map<String, dynamic>;
              switch (currentEvent) {
                case 'status':
                  yield HaileyStatusEvent(json['state'] as String? ?? '');
                case 'token':
                  yield HaileyTokenEvent(json['token'] as String? ?? '');
                case 'done':
                  yield HaileyDoneEvent(
                    turnId: json['turn_id'] as String? ?? '',
                    citations: (json['citations'] as List?)
                            ?.map((e) => e as Map<String, dynamic>)
                            .toList() ??
                        [],
                    deeplinks: (json['deeplinks'] as List?)
                            ?.map((e) => e as Map<String, dynamic>)
                            .toList() ??
                        [],
                  );
                case 'error':
                  yield HaileyErrorEvent(
                    json['code'] as String? ?? 'error',
                    json['message'] as String? ?? 'Something went wrong',
                  );
              }
            } catch (_) {
              // skip malformed data lines
            }
          } else if (line.isEmpty) {
            currentEvent = ''; // blank line resets the current event name
          }
        }
        // Keep the incomplete last fragment in the buffer
        lineBuffer.write(lines.last);
      }
    } finally {
      client.close();
    }
  }

  // -------------------------------------------------------------------------
  // History
  // -------------------------------------------------------------------------

  /// GET /history/ — returns conversation turns for the authenticated user.
  static Future<List<ChatMessage>> loadHistory({required String jwt}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/history/'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final turns = (data['turns'] as List?) ?? [];
      final messages = turns.map((t) {
        return ChatMessage(
          content: t['content'] as String,
          isUser: (t['role'] as String?) == 'user',
          timestamp: DateTime.parse(t['timestamp'] as String).toLocal(),
        );
      }).toList();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please sign in again.');
    } else {
      throw Exception('Failed to load history: ${response.statusCode}');
    }
  }

  /// DELETE /history/ — wipes all conversation history for the authenticated user.
  static Future<void> clearHistory({required String jwt}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/history/'),
      headers: {'Authorization': 'Bearer $jwt'},
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to clear history: ${response.statusCode}');
    }
  }

  // -------------------------------------------------------------------------
  // Memory (user facts)
  // -------------------------------------------------------------------------

  /// GET /memory/ — returns all structured facts Hailey has recorded.
  static Future<List<Map<String, dynamic>>> loadMemory({
    required String jwt,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/memory/'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['facts'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please sign in again.');
    } else {
      throw Exception('Failed to load memory: ${response.statusCode}');
    }
  }

  /// DELETE /memory/{factId} — lets the user remove a specific fact.
  static Future<void> deleteFact({
    required String factId,
    required String jwt,
  }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/memory/$factId'),
      headers: {'Authorization': 'Bearer $jwt'},
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete fact: ${response.statusCode}');
    }
  }
}

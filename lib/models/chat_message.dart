class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<Map<String, dynamic>> citations;
  final List<Map<String, dynamic>> deeplinks;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.citations = const [],
    this.deeplinks = const [],
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    content: json['content'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']).toLocal(),
  );
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/mixins/scroll_controller_mixin.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/services/chat_service.dart';
import 'package:smoking/models/chat_message.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';

class ChatbotPage extends ConsumerStatefulWidget {
  final String userId;
  final String? initialPrompt;

  const ChatbotPage({super.key, required this.userId, this.initialPrompt});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage>
    with AutoDisposeScrollController {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  // Streaming state
  bool _isStreaming = false;
  String _streamingContent = '';
  String _statusText = 'Hailey is thinking';
  StreamSubscription<HaileyEvent>? _streamSub;

  // History loading state
  bool _isLoadingHistory = true;

  // Cached JWT (refreshed on 401)
  String? _jwt;

  @override
  void initState() {
    super.initState();
    _initJwtAndHistory();
  }

  /// Fetch a fresh Appwrite JWT, then load history.
  Future<void> _initJwtAndHistory() async {
    await _refreshJwt();
    await _loadHistory();
    if (widget.initialPrompt?.isNotEmpty == true) {
      _controller.text = widget.initialPrompt!;
      _sendMessage();
    }
  }

  Future<void> _refreshJwt() async {
    try {
      final account = ref.read(accountProvider);
      final jwtObj = await account.createJWT();
      _jwt = jwtObj.jwt;
    } catch (e) {
      debugPrint('Failed to create JWT: $e');
    }
  }

  Future<void> _loadHistory() async {
    final jwt = _jwt;
    if (jwt == null) {
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }
    try {
      final history = await ChatService.loadHistory(jwt: jwt);
      if (!mounted) return;
      setState(() {
        _messages.add(_welcomeMessage()); // always first (oldest = top of chat)
        _messages.addAll(history);
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('Failed to load history: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // With reverse: true on the ListView, "bottom" = pixels 0.
  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      if (jump) {
        scrollController.jumpTo(0);
      } else {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isStreaming) return;

    // Ensure we have a valid JWT
    if (_jwt == null) await _refreshJwt();
    final jwt = _jwt;
    if (jwt == null) {
      _showSnack('Could not authenticate. Please restart the app.');
      return;
    }

    // Add the user message immediately
    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          content: text,
          isUser: true,
          timestamp: DateTime.now().toLocal(),
        ),
      );
      _isStreaming = true;
      _streamingContent = '';
      _statusText = 'Hailey is thinking';
    });
    _controller.clear();
    _scrollToBottom();

    _streamSub = ChatService.sendMessageStream(message: text, jwt: jwt).listen(
      (event) {
        if (!mounted) return;
        switch (event) {
          case HaileyStatusEvent(:final state):
            setState(() => _statusText = _labelForState(state));
          case HaileyTokenEvent(:final token):
            setState(() {
              _streamingContent += token;
              _statusText = ''; // clear status once tokens flow
            });
            _scrollToBottom();
          case HaileyDoneEvent():
            // Finalise the streamed message
            final content =
                _streamingContent.isNotEmpty ? _streamingContent : '...';
            setState(() {
              _messages.add(
                ChatMessage(
                  content: content,
                  isUser: false,
                  timestamp: DateTime.now().toLocal(),
                ),
              );
              _isStreaming = false;
              _streamingContent = '';
            });
            _scrollToBottom();
          case HaileyErrorEvent(:final message):
            setState(() {
              _messages.add(
                ChatMessage(
                  content: '❌ $message',
                  isUser: false,
                  timestamp: DateTime.now().toLocal(),
                ),
              );
              _isStreaming = false;
              _streamingContent = '';
            });
            _scrollToBottom();
        }
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _messages.add(
            ChatMessage(
              content: '❌ Connection error: $e',
              isUser: false,
              timestamp: DateTime.now().toLocal(),
            ),
          );
          _isStreaming = false;
          _streamingContent = '';
        });
        _scrollToBottom();
      },
      onDone: () {
        // Stream closed before a done event (e.g. server dropped connection)
        if (!mounted || !_isStreaming) return;
        final content =
            _streamingContent.isNotEmpty
                ? _streamingContent
                : '❌ Connection closed unexpectedly.';
        setState(() {
          _messages.add(
            ChatMessage(
              content: content,
              isUser: false,
              timestamp: DateTime.now().toLocal(),
            ),
          );
          _isStreaming = false;
          _streamingContent = '';
        });
        _scrollToBottom();
      },
    );
  }

  String _labelForState(String state) => switch (state) {
    'triaging' => 'Hailey is thinking',
    'loading_context' => 'Loading context',
    'searching_kb' => 'Searching knowledge base',
    'composing' => 'Hailey is composing',
    'saving' => 'Saving…',
    _ => 'Hailey is thinking',
  };

  ChatMessage _welcomeMessage() => ChatMessage(
    content:
        "Hi! I'm Hailey, your personal quit-smoking companion 💙\n\n"
        "I'm here to support you every step of the way — whether you're "
        "fighting a craving, celebrating a milestone, or just need someone "
        "to talk to. How are you feeling today?",
    isUser: false,
    timestamp: DateTime.now().toLocal(),
  );

  void _clearHistory() {
    final jwt = _jwt;
    if (jwt == null) return;

    // Grab messenger before popping so we can show on the parent page.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    ChatService.clearHistory(jwt: jwt).then((_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('History cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((e) {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ Failed to clear history: $e')),
      );
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;

    // Total item count: messages + optional streaming bubble
    final itemCount = _messages.length + (_isStreaming ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/chatbot.png', height: 24),
            const SizedBox(width: 8),
            Text(
              'Hailey',
              style: TextStyle(
                color:
                    isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Color.fromARGB(255, 242, 75, 73),
            ),
            tooltip: 'Clear History',
            onPressed: () => _showClearHistoryDialog(isDark),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient:
                isDark
                    ? AppThemes.darkMotivationGradient
                    : AppThemes.lightMotivationGradient,
          ),
          child: Column(
            children: [
              Expanded(
                child:
                    _isLoadingHistory
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color:
                                    isDark
                                        ? AppThemes.darkDiaryTextColor
                                        : const Color(0xFF0077B6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Loading history…',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppThemes.darkSubtitleColor
                                          : Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            // With reverse: true, index 0 = newest (visible at bottom).
                            if (_isStreaming && index == 0) {
                              return _StreamingBubble(
                                isDark: isDark,
                                content: _streamingContent,
                                statusText: _statusText,
                              );
                            }
                            final offset = _isStreaming ? 1 : 0;
                            final msg =
                                _messages[_messages.length -
                                    1 -
                                    (index - offset)];
                            return _MessageBubble(msg: msg, isDark: isDark);
                          },
                        ),
              ), // closes Expanded
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isStreaming,
                        style: TextStyle(
                          color:
                              isDark
                                  ? AppThemes.darkTextColor
                                  : AppThemes.lightTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              _isStreaming
                                  ? 'Hailey is replying…'
                                  : 'Type your message...',
                          filled: true,
                          fillColor:
                              isDark ? AppThemes.darkCardColor : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintStyle: AppThemes.inputHintStyle(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color:
                            _isStreaming
                                ? Colors.grey
                                : isDark
                                ? AppThemes.darkDiaryTextColor
                                : const Color(0xFF0077B6),
                      ),
                      onPressed: _isStreaming ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearHistoryDialog(bool isDark) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient:
                    isDark
                        ? AppThemes.darkDeleteDialogGradient
                        : AppThemes.lightDeleteDialogGradient,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color:
                        isDark
                            ? AppThemes.darkDeleteButtonColor
                            : AppThemes.lightDeleteButtonColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to clear your history?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? AppThemes.darkTextColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark ? AppThemes.darkSubtitleColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.elevatedButtonBackground(
                            isDark,
                          ),
                          foregroundColor:
                              isDark ? AppThemes.darkTextColor : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearHistory();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark
                                  ? AppThemes.darkDeleteButtonColor
                                  : AppThemes.lightDeleteButtonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.isDark});

  final ChatMessage msg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              msg.isUser
                  ? (isDark ? AppThemes.activeColor : const Color(0xFF0077B6))
                  : (isDark
                      ? AppThemes.darkCardColor
                      : const Color(0xFF90E0EF)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color:
                    msg.isUser
                        ? Colors.white
                        : (isDark ? AppThemes.darkTextColor : Colors.black87),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm • MMM d, yyyy').format(msg.timestamp.toLocal()),
              style: TextStyle(
                fontSize: 11,
                color:
                    msg.isUser
                        ? Colors.white70
                        : (isDark
                            ? AppThemes.darkSubtitleColor
                            : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the backend is streaming. Displays tokens as they arrive;
/// falls back to the animated typing dots while waiting for the first token.
class _StreamingBubble extends StatefulWidget {
  const _StreamingBubble({
    required this.isDark,
    required this.content,
    required this.statusText,
  });

  final bool isDark;
  final String content;
  final String statusText;

  @override
  State<_StreamingBubble> createState() => _StreamingBubbleState();
}

class _StreamingBubbleState extends State<_StreamingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bubbleColor =
        isDark ? AppThemes.darkCardColor : const Color(0xFF90E0EF);
    final textColor = isDark ? AppThemes.darkTextColor : Colors.black87;
    final labelColor = isDark ? AppThemes.darkSubtitleColor : Colors.black54;
    final dotColor = isDark ? AppThemes.darkTextColor : Colors.black87;

    final hasTokens = widget.content.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            hasTokens
                // Tokens are flowing — show the accumulated text
                ? Text(
                  widget.content,
                  style: TextStyle(color: textColor, fontSize: 15),
                )
                // Waiting for first token — show status label + animated dots
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.statusText,
                      style: TextStyle(color: labelColor, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, _) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            final t = (_controller.value - i / 3) % 1.0;
                            final opacity =
                                0.2 + 0.8 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
      ),
    );
  }
}

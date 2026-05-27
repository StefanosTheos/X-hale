import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/mixins/scroll_controller_mixin.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _loadHistory().then((_) {
      if (widget.initialPrompt?.isNotEmpty == true) {
        _controller.text = widget.initialPrompt!;
        _sendMessage();
      }
    });
  }

  Future<void> _loadHistory() async {
    try {
      // The server seeds the welcome message inside GET /history/{user_id}
      // when no rows exist, so the response is never empty for a first-time
      // user. That eliminates the old race where the client had to inject a
      // welcome after the load resolved.
      final history = await ChatService.loadMessages(widget.userId);
      if (!mounted) return;
      setState(() {
        _messages.addAll(history);
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      content: text,
      isUser: true,
      timestamp: DateTime.now().toLocal(),
    );

    if (!mounted) return;
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await ChatService.sendMessage(
        text: text,
        userId: widget.userId,
      );

      final botMessage = ChatMessage(
        content: response,
        isUser: false,
        timestamp: DateTime.now().toLocal(),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(botMessage);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            content: '❌ Error: ${e.toString()}',
            isUser: false,
            timestamp: DateTime.now().toLocal(),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _clearHistory() async {
    setState(() => _messages.clear());

    try {
      await ChatService.clearHistory(userId: widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('History cleared')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chatbot',
          style: TextStyle(
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete,
              color:
                  isDark
                      ? const Color.fromARGB(255, 242, 75, 73)
                      : const Color.fromARGB(255, 242, 75, 73),
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
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == _messages.length) {
                      return _TypingBubble(isDark: isDark);
                    }
                    final msg = _messages[index];
                    return Align(
                      alignment:
                          msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              msg.isUser
                                  ? (isDark
                                      ? AppThemes.activeColor
                                      : const Color(0xFF0077B6))
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
                                        : (isDark
                                            ? AppThemes.darkTextColor
                                            : Colors.black87),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'HH:mm • MMM d, yyyy',
                              ).format(msg.timestamp.toLocal()),
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
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Type your message...",
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
                            isDark
                                ? AppThemes.darkDiaryTextColor
                                : const Color(0xFF0077B6),
                      ),
                      onPressed: _sendMessage,
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
                        onPressed: () async {
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.isDark});

  final bool isDark;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
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
    final dotColor =
        isDark ? AppThemes.darkTextColor : Colors.black87;
    final labelColor =
        isDark ? AppThemes.darkSubtitleColor : Colors.black54;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hailey is typing',
              style: TextStyle(color: labelColor, fontSize: 13),
            ),
            const SizedBox(width: 6),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    // Stagger each dot by 1/3 of the cycle.
                    final t = (_controller.value - i / 3) % 1.0;
                    // Triangle wave: opacity goes 0.2 → 1.0 → 0.2 over the cycle.
                    final opacity =
                        0.2 + 0.8 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/mixins/scroll_controller_mixin.dart';
import 'package:smoking/providers/friends_provider.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/empty_state.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';
class ChatPage extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverIcon;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverIcon,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with AutoDisposeScrollController {
  final TextEditingController _controller = TextEditingController();
  // Gates `_sendMessage` while the Appwrite write is in flight — without
  // it, a double-tap during the round-trip would call `sendMessage` again
  // and create a duplicate DM.
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _refreshMessages();
  }

  /// Pull the latest messages from Appwrite. The list itself is rendered
  /// directly from `friendProvider.messages` via `ref.watch` in `build`, so
  /// new messages arriving via any other path (e.g. the other user sending a
  /// DM while this page is open and the provider getting refreshed elsewhere)
  /// show up reactively — no local snapshot field.
  Future<void> _refreshMessages() async {
    final userId = ref.read(userProvider).userId;
    await ref.read(friendProvider.notifier).fetchMessages(userId);
    if (!mounted) return;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        // The ListView is `reverse: true`, so offset 0 is the visual bottom
        // (newest message) and `maxScrollExtent` is the visual top (oldest
        // messages). Animating to `maxScrollExtent` therefore scrolled the
        // user *up to the top* after every send — the opposite of what
        // this method is named for.
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final userId = ref.read(userProvider).userId;
      final ok = await ref
          .read(friendProvider.notifier)
          .sendMessage(
            senderId: userId,
            receiverId: widget.receiverId,
            message: text,
          );
      if (!mounted) return;
      if (!ok) {
        // Preserve the user's input so they can retry; surface the failure.
        // Previously the catch only `debugPrint`ed and the UI gave no signal.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send. Check your connection and try again.')),
        );
        return;
      }
      _controller.clear();
      await _refreshMessages();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userProvider.select((u) => u.userId));
    final isDark = ref.isDark;
    // Filter the live messages list from `friendProvider` rather than a
    // local snapshot so inbound DMs from the other user appear without
    // needing this page to reload.
    final messages = ref
        .watch(friendProvider.select((s) => s.messages))
        .where(
          (m) =>
              (m.senderId == userId && m.receiverId == widget.receiverId) ||
              (m.senderId == widget.receiverId && m.receiverId == userId),
        )
        .toList();

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
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(widget.receiverIcon),
              backgroundColor: isDark ? AppThemes.darkCardColor : Colors.white,
              child:
                  widget.receiverIcon.isEmpty
                      ? Icon(
                        Icons.person,
                        size: 20,
                        color:
                            isDark ? AppThemes.darkTextColor : Colors.black87,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: TextStyle(
                    color:
                        isDark
                            ? AppThemes.darkTextColor
                            : AppThemes.lightTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Tap anywhere outside the input row to dismiss the keyboard.
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
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
                child: messages.isEmpty
                    ? EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'No messages yet',
                        subtitle: 'Say hi to ${widget.receiverName}.',
                        isDark: isDark,
                      )
                    : ListView.builder(
                          reverse: true,
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == userId;

                            return Align(
                              alignment:
                                  isMe
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
                                      isMe
                                          ? (isDark
                                              ? AppThemes.activeColor
                                              : AppThemes.primaryBlue)
                                          : (isDark
                                              ? AppThemes.darkCardColor
                                              : const Color(0xFF90E0EF)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.message,
                                      style: TextStyle(
                                        color:
                                            isMe
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
                                      ).format(message.sentAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            isMe
                                                ? Colors.white70
                                                : (isDark
                                                    ? AppThemes
                                                        .darkSubtitleColor
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
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.send,
                              color: isDark
                                  ? AppThemes.darkDiaryTextColor
                                  : AppThemes.primaryBlue,
                            ),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
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

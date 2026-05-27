import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/models/user_state.dart';
import 'package:smoking/mixins/scroll_controller_mixin.dart';
import 'package:smoking/providers/forum_provider.dart';
import 'package:smoking/providers/friends_provider.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/empty_state.dart';
import 'package:smoking/pages/utils/load_more_footer.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/datetime.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
class ForumPage extends ConsumerStatefulWidget {
  const ForumPage({super.key});

  @override
  ConsumerState<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends ConsumerState<ForumPage>
    with AutoDisposeScrollController {
  final TextEditingController _messageController = TextEditingController();
  // Gates `_sendMessage` while the Appwrite write is in flight. The
  // optimistic-prepend pattern from #228 still has a round-trip window
  // before the snackbar / clear fires, so without this flag a second tap
  // would call `addForumPost` again and create a duplicate post.
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Load the next page when the user scrolls within ~300px of the end.
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;
      final pos = scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        ref.read(forumPostProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showUserProfileDialog(UserState user) {
    final colors = ref.themeColors;
    final isDark = colors.isDark;
    final activeColor = colors.active;
    final currentUserId = ref.read(userProvider).userId;
    final isCurrentUser = currentUserId == user.userId;

    showModalBottomSheet(
      enableDrag: false,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark ? Colors.black54 : Colors.black38,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return FutureBuilder<List<bool>>(
          // Keyed by the viewed user so a stale future from a previously-tapped
          // profile can't overwrite the snapshot for the current one. Forces a
          // fresh FutureBuilder element when `user.userId` changes.
          key: ValueKey('profile-${user.userId}'),
          future: Future.wait([
            ref
                .read(friendProvider.notifier)
                .isAlreadyFriend(currentUserId, user.userId),
            ref
                .read(friendProvider.notifier)
                .hasPendingRequest(currentUserId, user.userId),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final alreadyFriend = snapshot.data![0];
            bool requestSent = snapshot.data![1];

            return StatefulBuilder(
              builder: (context, setState) {
                Future<void> handleAddFriend() async {
                  await ref
                      .read(friendProvider.notifier)
                      .sendFriendRequest(currentUserId, user.userId);

                  if (context.mounted) {
                    setState(() => requestSent = true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Friend request sent to ${user.name}'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    gradient:
                        isDark
                            ? AppThemes.darkMotivationGradient
                            : AppThemes.lightMotivationGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage:
                                user.avatarPath.startsWith('http')
                                    ? NetworkImage(user.avatarPath)
                                    : AssetImage(user.avatarPath)
                                        as ImageProvider,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppThemes.darkTextColor : AppThemes.lightSubtitleColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${user.achievementsCount} achievements',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.smoking_rooms_outlined,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Smoke-free for: ${user.quitDate.formatSmokeFreeDuration()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                label: const Text('Close'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark
                                          ? AppThemes.darkCardColor
                                          : const Color.fromARGB(
                                            255,
                                            98,
                                            212,
                                            232,
                                          ),
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              if (!isCurrentUser) ...[
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed:
                                      (alreadyFriend || requestSent)
                                          ? null
                                          : handleAddFriend,
                                  icon:
                                      requestSent
                                          ? Image.asset(
                                            'assets/icons/request_sent_check.png',
                                            width: 20,
                                            height: 20,
                                          )
                                          : alreadyFriend
                                          ? Image.asset(
                                            'assets/icons/friends_already.png',
                                            width: 20,
                                            height: 20,
                                          )
                                          : Icon(
                                            Icons.person_add_alt_1,
                                            color: Colors.white,
                                          ),
                                  label: Text(
                                    alreadyFriend
                                        ? 'Friends'
                                        : (requestSent
                                            ? 'Request Sent'
                                            : 'Add Friend'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        alreadyFriend || requestSent
                                            ? activeColor.withAlpha(
                                              (0.4 * 255).round(),
                                            )
                                            : activeColor,
                                    foregroundColor:
                                        alreadyFriend || requestSent
                                            ? (isDark
                                                ? Colors.white
                                                : Colors.white)
                                            : Colors.white,
                                    disabledForegroundColor:
                                        isDark ? Colors.white : Colors.white,
                                    disabledBackgroundColor: activeColor
                                        .withAlpha((0.4 * 255).round()),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final forumNotifier = ref.read(forumPostProvider.notifier);
      final ok = await forumNotifier.addForumPost(text);
      if (!mounted) return;
      if (!ok) {
        // Preserve the user's input so they can retry; tell them why nothing
        // happened. Previously the input was cleared regardless of success
        // and a network failure silently swallowed the message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send. Check your connection and try again.')),
        );
        return;
      }
      _messageController.clear();
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumPostProvider);
    final forumNotifier = ref.read(forumPostProvider.notifier);
    final userId = ref.watch(userProvider.select((u) => u.userId));
    // Override the denormalised `userAvatar` / `username` on the current
    // user's own posts with the live values from `userProvider`. Without
    // this, changing your avatar would only affect *new* posts going
    // forward — historical bubbles would keep rendering the old image
    // because each forum post stores its author's avatar/name at write
    // time. `user_provider.updateAvatar*` also kicks off an Appwrite-side
    // resync so other users eventually see the new values too, but this
    // override makes it instant for the local user.
    final currentName = ref.watch(userProvider.select((u) => u.name));
    final currentAvatar =
        ref.watch(userProvider.select((u) => u.avatarPath));
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
          'Forum',
          style: TextStyle(
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Tap anywhere outside the input to dismiss the keyboard — matches
        // the create_challenge / edit_challenge convention.
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppThemes.darkMotivationGradient
                  : AppThemes.lightMotivationGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child:
                    forumState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : forumState.hasError
                        ? const Center(
                          child: Text(
                            'Something went wrong. Please try again.',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                        : forumState.posts.isEmpty
                        ? EmptyState(
                          icon: Icons.forum_outlined,
                          title: 'No posts yet',
                          subtitle: 'Be the first to share.',
                          isDark: isDark,
                        )
                        : RefreshIndicator(
                          onRefresh: () =>
                              forumNotifier.loadForumPosts(force: true),
                          child: ListView.builder(
                          reverse: true,
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          // +1 slot when paginating — the extra index renders
                          // a small spinner at the top of the (reversed) list
                          // so the user knows older posts are on the way.
                          itemCount: forumState.posts.length +
                              (forumState.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == forumState.posts.length) {
                              return const LoadMoreFooter();
                            }
                            final post = forumState.sorted[index];
                            final isMe = post.userId == userId;
                            final displayAvatar =
                                isMe ? currentAvatar : post.userAvatar;
                            final displayName =
                                isMe ? currentName : post.username;

                            // The post payload already carries `username`
                            // and `userAvatar`, so we don't need the
                            // snapshot until the user actually taps to open
                            // the profile dialog. Previously a
                            // `FutureBuilder` here re-created the snapshot
                            // future on every rebuild — scrolling fired N
                            // parallel Appwrite reads.
                            return GestureDetector(
                              onTap: () async {
                                final user = await forumNotifier
                                    .fetchUserProfileSnapshot(post.userId);
                                if (!context.mounted) return;
                                if (user != null) {
                                  _showUserProfileDialog(user);
                                }
                              },
                              child: Align(
                                    alignment:
                                        isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.8,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundImage:
                                                    displayAvatar.startsWith(
                                                          'http',
                                                        )
                                                        ? NetworkImage(
                                                          displayAvatar,
                                                        )
                                                        : AssetImage(
                                                              displayAvatar,
                                                            )
                                                            as ImageProvider,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                displayName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isMe
                                                          ? Colors.white
                                                          : (isDark
                                                              ? AppThemes
                                                                  .darkTextColor
                                                              : Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            post.message,
                                            style: TextStyle(
                                              fontSize: 15,
                                              color:
                                                  isMe
                                                      ? Colors.white
                                                      : (isDark
                                                          ? AppThemes
                                                              .darkTextColor
                                                          : Colors.black87),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat(
                                              'HH:mm • MMM d, yyyy',
                                            ).format(post.createdAt),
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
                                  ),
                                );
                          },
                        ),
                        ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Write your message...",
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
}


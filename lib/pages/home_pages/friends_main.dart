import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/models/friends_state.dart';
import 'package:smoking/models/userprofile_state.dart';
import 'package:smoking/pages/home_pages/dm.dart';
import 'package:smoking/providers/friends_provider.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:smoking/pages/utils/empty_state.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/datetime.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  // Holding our own FocusNode keeps the keyboard up across the rebuilds that
  // the search status block triggers when it flips between spinner / result /
  // empty-state.
  final FocusNode _searchFocusNode = FocusNode();
  // `true` once at least one search has resolved against a non-empty query.
  // Distinguishes "haven't searched yet" (show nothing) from "searched and
  // found nothing" (show EmptyState). Flipped *after* the first search
  // resolves so subsequent searches don't briefly flash the EmptyState while
  // a result is in flight.
  bool _searchSubmitted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Clear search result when changing tabs
        ref.read(friendProvider.notifier).clearSearchResult();
        if (mounted) {
          setState(() => _searchSubmitted = false);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // fetchAllFriendData already pulls incoming requests; no need to redo it.
      await ref.read(friendProvider.notifier).fetchAllFriendData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Only fires meaningful work when the field becomes empty — clearing via
  /// the suffix X or backspacing the last character resets the prior
  /// result + EmptyState. Typing keystrokes do NOT trigger a search; the
  /// user must press Done / the keyboard's search action key, which routes
  /// through `_handleSearchSubmit` below.
  void _handleSearchChange(String value) {
    if (value.trim().isEmpty) {
      ref.read(friendProvider.notifier).clearSearchResult();
      if (mounted && _searchSubmitted) {
        setState(() => _searchSubmitted = false);
      }
    }
  }

  /// Fires on keyboard submit (TextInputAction.search / Done). This is the
  /// only path that actually hits Appwrite — the previous typing-debounce
  /// behavior fired a search every time the user paused, which felt
  /// premature on pages where the username is typed slowly.
  Future<void> _handleSearchSubmit(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    await ref.read(friendProvider.notifier).searchUserByName(query);
    if (!mounted) return;
    if (!_searchSubmitted) setState(() => _searchSubmitted = true);
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color:
            ref.isDark ? AppThemes.darkDiaryTextColor : AppThemes.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendProvider);
    final colors = ref.themeColors;
    final isDark = colors.isDark;
    final cardColor = colors.card;
    final textColor = colors.text;
    final subtitleColor = colors.subtitle;
    final backgroundGradient =
        isDark ? AppThemes.darkGradient : AppThemes.lightGradient;
    // Friends-page actives use pure white on dark, not the global activeColor
    // (which is the blue used in dialog buttons). Kept inline for that reason.
    final activeColor =
        isDark
            ? const Color.fromARGB(255, 255, 255, 255)
            : AppThemes.primaryBlue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Friends',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isDark ? const Color(0xFF0A84FF) : const Color(0xff48CAE4),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: activeColor,
          labelColor: activeColor,
          unselectedLabelColor: subtitleColor,
          tabs: const [
            Tab(text: 'Friends List'),
            Tab(text: 'Chats'),
            Tab(text: 'Add Friend'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: TabBarView(
            controller: _tabController,
            children: [
              state.isLoading
                  ? _buildLoadingState()
                  : _buildFriendsList(
                    state,
                    isDark,
                    cardColor,
                    textColor,
                    subtitleColor!,
                    activeColor,
                  ),
              state.isLoading
                  ? _buildLoadingState()
                  : _buildChatsList(
                    state,
                    isDark,
                    cardColor,
                    textColor,
                    subtitleColor!,
                  ),
              state.isLoading
                  ? _buildLoadingState()
                  : _buildAddFriend(
                    state,
                    isDark,
                    cardColor,
                    textColor,
                    subtitleColor!,
                  ),
              state.isLoading
                  ? _buildLoadingState()
                  : _buildFriendRequests(
                    state,
                    isDark,
                    cardColor,
                    textColor,
                    subtitleColor!,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    FriendPageState state,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color activeColor,
  ) {
    if (state.friends.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No friends yet',
        subtitle: 'Search for a friend by username\n in the Add Friend tab.',
        isDark: isDark,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'Friends: ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                state.friends.length.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh:
                () => ref.read(friendProvider.notifier).fetchAllFriendData(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: state.friends.length,
              itemBuilder: (context, index) {
                final friend = state.friends[index];
                final currentUserId = ref.read(userProvider).userId;
                final otherUserId =
                    friend.user1Id == currentUserId
                        ? friend.user2Id
                        : friend.user1Id;

                // Read from the preloaded profile map instead of spawning a
                // per-tile FutureBuilder — 50 friends used to mean 100 parallel
                // Appwrite calls (profile + quitDate × 50). Now one batched
                // fetch in `fetchFriendProfiles` covers all of them.
                final user = state.friendProfiles[otherUserId];
                if (user == null) return const SizedBox.shrink();
                final quitDate = user.quitDate;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: cardColor,
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(user.avatarPath),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '${user.achievementsCount}',
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                        const SizedBox(width: 3),
                        Image.asset(
                          'assets/icons/trophies.png',
                          width: 16,
                          height: 16,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      quitDate.formatSmokeFreeDuration(),
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Remove friend',
                          icon: Image.asset(
                            'assets/icons/remove_friend.png',
                            width: 26,
                            height: 26,
                          ),
                          onPressed: () async {
                            final ok = await showDeleteConfirmDialog(
                              context: context,
                              isDark: isDark,
                              title: 'Remove this friend?',
                              message:
                                  'This will also delete all your messages with them.',
                              deleteLabel: 'Remove',
                            );
                            if (ok != true) return;
                            await ref
                                .read(friendProvider.notifier)
                                .removeFriend(friend.friendshipId);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Friend removed successfully.'),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Open chat',
                          icon: Image.asset(
                            'assets/icons/chat.png',
                            width: 28,
                            height: 28,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ChatPage(
                                      receiverId: otherUserId,
                                      receiverName: user.name,
                                      receiverIcon: user.avatarPath,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 2. CHATS
  Widget _buildChatsList(
    FriendPageState state,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final messages = state.messages;
    if (messages.isEmpty) {
      return EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        subtitle: 'Start a conversation from your Friends List.',
        isDark: isDark,
      );
    }

    // Group messages per user
    final Map<String, Message> lastMessages = {};
    final currentUserId = ref.read(userProvider).userId;

    for (final message in messages) {
      final otherId =
          message.senderId == currentUserId
              ? message.receiverId
              : message.senderId;

      if (!lastMessages.containsKey(otherId) ||
          message.sentAt.isAfter(lastMessages[otherId]!.sentAt)) {
        lastMessages[otherId] = message;
      }
    }

    // Sort by date
    final sortedMessages =
        lastMessages.entries.toList()
          ..sort((a, b) => b.value.sentAt.compareTo(a.value.sentAt));

    return RefreshIndicator(
      onRefresh: () => ref.read(friendProvider.notifier).fetchAllFriendData(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sortedMessages.length,
        itemBuilder: (context, index) {
          final entry = sortedMessages[index];
          final message = entry.value;
          final otherId = entry.key;

          // Read from the preloaded profile map — same pattern as the Friends
          // tab. Chat senders are necessarily friends, so `friendProfiles` is
          // guaranteed to contain them once `fetchAllFriendData` resolves.
          final user = state.friendProfiles[otherId];
          if (user == null) return const SizedBox.shrink();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: cardColor,
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(user.avatarPath),
              ),
              title: Text(
                user.name,
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              subtitle: Text(
                '${message.senderId == currentUserId ? "You" : user.name}: ${message.message}',
                style: TextStyle(color: subtitleColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.sentAt.formatChatTimestamp(),
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                  if (!message.sentAt.isToday)
                    Text(
                      message.sentAt.formatChatDate(),
                      style: TextStyle(
                        color: subtitleColor.withAlpha((0.7 * 255).round()),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChatPage(
                          receiverId: otherId,
                          receiverName: user.name,
                          receiverIcon: user.avatarPath,
                        ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Chat date helpers moved to `lib/extensions/datetime.dart` as
  // `formatChatTimestamp` / `formatChatDate` / `isToday` — see callers
  // at the message row in `_buildChatsTab` above.

  Widget _buildAddFriend(
    FriendPageState state,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final activeColor = isDark ? AppThemes.activeColor : AppThemes.primaryBlue;
    final dialogGradient =
        isDark ? AppThemes.darkDialogGradient : AppThemes.lightDialogGradient;

    void showErrorDialog(String message) {
      showGradientDialog<void>(
        context: context,
        gradient: dialogGradient,
        children: [
          Icon(
            Icons.error_outline,
            color:
                isDark
                    ? AppThemes.darkDeleteButtonColor
                    : AppThemes.lightDeleteButtonColor,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      );
    }

    Future<void> handleAddFriend(UserProfile user) async {
      final senderId = ref.read(userProvider).userId;

      // Check if already friends
      final alreadyFriends = await ref
          .read(friendProvider.notifier)
          .isAlreadyFriend(senderId, user.userId);
      if (alreadyFriends) {
        showErrorDialog('You are already friends with ${user.name}');
        return;
      }

      // Check for an existing pending request
      final hasPending = await ref
          .read(friendProvider.notifier)
          .hasPendingRequest(senderId, user.userId);
      if (hasPending) {
        showErrorDialog(
          'You already have a pending friend request to ${user.name}',
        );
        return;
      }

      // All checks passed — send the request
      await ref
          .read(friendProvider.notifier)
          .sendFriendRequest(senderId, user.userId);

      if (mounted) {
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListenableBuilder(
            listenable: _searchController,
            builder: (context, _) {
              return TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(color: textColor),
                textInputAction: TextInputAction.search,
                onChanged: _handleSearchChange,
                onSubmitted: _handleSearchSubmit,
                decoration: InputDecoration(
                  labelText: 'Search by username',
                  labelStyle: TextStyle(color: subtitleColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.search, color: activeColor),
                  suffixIcon:
                      _searchController.text.isEmpty
                          ? null
                          : IconButton(
                            icon: Icon(Icons.close, color: subtitleColor),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearchChange('');
                            },
                          ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // `state.searchResult` is already in scope (passed from the parent's
          // single `ref.watch(friendProvider)`) — the two separate
          // `ref.watch(friendProvider.select((s) => s.searchResult))` calls
          // this code used to make briefly resolved out-of-step on weak
          // networks and, combined with the non-postFrame `requestFocus`
          // below, could blur the search field mid-typing.
          if (_searchSubmitted && state.searchResult == null)
            EmptyState(
              icon: Icons.person_search,
              title: 'No user found',
              subtitle: 'Try a different username.',
              isDark: isDark,
            )
          else if (state.searchResult case final user?)
            Builder(
              builder: (context) {
                // All three previously per-build futures are now derived
                // from already-loaded state. `user.quitDate` rides along on
                // the search result's `UserProfile`; `state.friends` /
                // `state.outgoingRequests` are populated by
                // `fetchAllFriendData()` on tab mount. Net effect: 3 Appwrite
                // round-trips per rebuild → 0.
                final quitDate = user.quitDate;
                final alreadyFriend = state.friends.any(
                  (f) => f.user1Id == user.userId || f.user2Id == user.userId,
                );
                final pendingRequest = state.outgoingRequests.any(
                  (r) => r.receiverId == user.userId && r.status == 'pending',
                );
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: cardColor,
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(user.avatarPath),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${user.achievementsCount}',
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                        const SizedBox(width: 3),
                        Image.asset(
                          'assets/icons/trophies.png',
                          width: 16,
                          height: 16,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      quitDate.formatSmokeFreeDuration(),
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                    trailing: IconButton(
                      tooltip:
                          alreadyFriend
                              ? 'Already friends'
                              : pendingRequest
                              ? 'Friend request already sent'
                              : 'Send friend request',
                      icon: Image.asset(
                        pendingRequest
                            ? 'assets/icons/request_sent_check.png'
                            : 'assets/icons/add_friend.png',
                        width: 30,
                        height: 30,
                      ),
                      onPressed:
                          (alreadyFriend || pendingRequest)
                              ? null
                              : () => handleAddFriend(user),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFriendRequests(
    FriendPageState state,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final activeColor = isDark ? AppThemes.activeColor : AppThemes.primaryBlue;
    final errorColor =
        isDark
            ? AppThemes.darkDeleteButtonColor
            : AppThemes.lightDeleteButtonColor;

    if (state.incomingRequests.isEmpty) {
      return EmptyState(
        icon: Icons.person_add_disabled,
        title: 'No incoming requests',
        subtitle: 'When someone adds you, their request will appear here.',
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(friendProvider.notifier).fetchAllFriendData(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.incomingRequests.length,
        itemBuilder: (context, index) {
          final request = state.incomingRequests[index];
          // Read from the preloaded `incomingRequestProfiles` map populated
          // once by `fetchAllFriendData` instead of firing two per-row
          // `getUserProfileById` calls (one for the profile, one for the
          // quit date) on every rebuild that resolved to the same document.
          final user = state.incomingRequestProfiles[request.senderId];
          if (user == null) return const SizedBox.shrink();
          final quitDate = user.quitDate;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: cardColor,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(user.avatarPath),
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 12),
                                Text(
                                  '${user.achievementsCount}',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Image.asset(
                                  'assets/icons/trophies.png',
                                  width: 16,
                                  height: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          quitDate.formatSmokeFreeDuration(),
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Accept friend request',
                        icon: Icon(Icons.check, color: activeColor),
                        style: IconButton.styleFrom(
                          backgroundColor: activeColor.withAlpha(
                            (0.2 * 255).round(),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(friendProvider.notifier)
                              .respondToRequest(request.requestId, true);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Decline friend request',
                        icon: Icon(Icons.close, color: errorColor),
                        style: IconButton.styleFrom(
                          backgroundColor: errorColor.withAlpha(
                            (0.25 * 255).round(),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(friendProvider.notifier)
                              .respondToRequest(request.requestId, false);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/home_pages/forum.dart';
import 'package:smoking/pages/home_pages/widgets/framed_section.dart';
import 'package:smoking/pages/home_pages/widgets/home_button.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/forum_provider.dart';

/// "Forum" card on the home dashboard — shows the latest forum post (or a
/// "Something went wrong" / "No messages yet" fallback) and a "Forum" button.
class ForumMessageSection extends ConsumerWidget {
  const ForumMessageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDark;
    // Read straight from `forumPostProvider` instead of the deleted
    // `latestForumPostProvider`. The notifier already pages the forum on
    // creation and prepends new posts optimistically (#228), so its first
    // post IS the latest — no need for a separate Appwrite read.
    final isLoading =
        ref.watch(forumPostProvider.select((s) => s.isLoading));
    final hasError = ref.watch(forumPostProvider.select((s) => s.hasError));
    final latestPost = ref.watch(
      forumPostProvider.select(
        (s) => s.posts.isEmpty ? null : s.posts.first,
      ),
    );
    final textColor =
        isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor;

    Widget body;
    if (hasError) {
      body = Text(
        'Something went wrong...',
        style: TextStyle(color: textColor),
      );
    } else if (isLoading && latestPost == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (latestPost == null) {
      body = Text('No messages yet.', style: TextStyle(color: textColor));
    } else {
      final formattedDate =
          DateFormat('dd MMM yyyy – HH:mm').format(latestPost.createdAt);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: latestPost.userAvatar.startsWith('http')
                    ? NetworkImage(latestPost.userAvatar)
                    : AssetImage(latestPost.userAvatar) as ImageProvider,
              ),
              const SizedBox(width: 10),
              Text(
                latestPost.username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            latestPost.message,
            style: TextStyle(fontSize: 15, color: textColor),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FramedSection(
          title: 'Forum',
          addTopSpacing: false,
          child: body,
        ),
        const SizedBox(height: 12),
        Center(
          child: HomeButton(
            text: 'Forum',
            iconPath: 'assets/icons/forum.png',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForumPage()),
              );
              // Force-refresh after returning so any posts added on another
              // device while the user was on the forum page show up.
              ref
                  .read(forumPostProvider.notifier)
                  .loadForumPosts(force: true);
            },
          ),
        ),
      ],
    );
  }
}

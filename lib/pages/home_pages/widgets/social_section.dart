import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/home_pages/friends_main.dart';
import 'package:smoking/pages/home_pages/widgets/framed_section.dart';
import 'package:smoking/pages/home_pages/widgets/home_button.dart';
import 'package:smoking/pages/utils/themes.dart';

/// "Connect with people" card with a "Friends" button at the bottom of the
/// home dashboard.
class SocialSection extends ConsumerWidget {
  const SocialSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDark;
    final subtitleColor =
        isDark ? AppThemes.darkSubtitleColor : Colors.grey.shade600;

    return Column(
      children: [
        const SizedBox(height: 0),
        FramedSection(
          title: '',
          transparent: true,
          addTopSpacing: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/icons/social.png', width: 80, height: 80),
                const SizedBox(height: 12),
                Text(
                  'Connect with people',
                  style: TextStyle(fontSize: 16, color: subtitleColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: HomeButton(
                    text: 'Friends',
                    iconPath: 'assets/icons/friends.png',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FriendsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

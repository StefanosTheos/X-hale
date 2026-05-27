import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/back_app_bar.dart';
import 'package:smoking/pages/utils/themes.dart';

class AboutUsPage extends ConsumerWidget {
  const AboutUsPage({super.key});

  Widget _buildCard({
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    final cardColor =
        isDarkMode ? AppThemes.darkCardColor : AppThemes.lightCardColor;
    final titleColor =
        isDarkMode ? AppThemes.darkTextColor : const Color(0xff023E8A);
    final contentColor =
        isDarkMode ? AppThemes.darkSubtitleColor : AppThemes.lightSubtitleColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      child: Card(
        elevation: 3,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.isDark;

    final gradient =
        isDarkMode ? AppThemes.darkGradient : AppThemes.lightGradient;

    return Scaffold(
      appBar: const BackAppBar(title: 'About Us'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: BoxDecoration(gradient: gradient)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildCard(
                    title: 'Our Mission',
                    content:
                        'We aim to empower individuals to quit smoking through motivation, tracking, and positive reinforcement. '
                        'This app was created with care to support your journey every step of the way. '
                        'We believe that small, consistent steps lead to lasting change, and our mission is to make this process as smooth and encouraging as possible. '
                        'With intuitive tools, gentle reminders, and inspiring milestones, our goal is to help you reclaim your health and well-being.',
                    isDarkMode: isDarkMode,
                  ),
                  _buildCard(
                    title: 'The Team',
                    content:
                        'We are a small group of developers and designers passionate about public health and clean user experiences. '
                        'Our goal is to make quitting easier and more rewarding. '
                        'With backgrounds in psychology, health tech, and mobile development, we came together to build something that truly supports users through habit change. '
                        'We continuously listen to feedback and improve the app so it evolves alongside your journey.',
                    isDarkMode: isDarkMode,
                  ),
                  _buildCard(
                    title: 'Contact Us',
                    content:
                        'Have feedback or suggestions?\n\nReach out to us at:\n\nsupport@xhale.com',
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

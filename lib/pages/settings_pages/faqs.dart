import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/back_app_bar.dart';
import 'package:smoking/pages/utils/themes.dart';

class FAQsPage extends ConsumerWidget {
  const FAQsPage({super.key});

  Widget _buildCard({
    required String question,
    required String answer,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      child: Card(
        elevation: 3,
        color: isDarkMode ? AppThemes.darkCardColor : AppThemes.lightCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode
                          ? AppThemes.darkTextColor
                          : const Color(0xff023E8A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                answer,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color:
                      isDarkMode
                          ? AppThemes.darkSubtitleColor
                          : AppThemes.lightSubtitleColor,
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
      appBar: const BackAppBar(title: 'FAQs'),
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
                    question: 'How does this app help me quit smoking?',
                    answer:
                        'Our app combines habit tracking, motivational messages, achievement milestones, and progress visualization to help you stay committed and celebrate your journey.',
                    isDarkMode: isDarkMode,
                  ),
                  _buildCard(
                    question: 'Is my personal data secure?',
                    answer:
                        'Absolutely. We value your privacy and ensure that all your data is stored securely. We do not share your information with any third parties.',
                    isDarkMode: isDarkMode,
                  ),
                  _buildCard(
                    question: 'Can I reset my progress?',
                    answer:
                        'Yes, you can reset your progress in the account settings if you wish to start fresh. Be mindful that all your previous data will be lost.',
                    isDarkMode: isDarkMode,
                  ),
                  _buildCard(
                    question: 'What happens if I relapse?',
                    answer:
                        'Relapses are part of the process for many people. The app allows you to log relapses without judgment and encourages you to keep moving forward. You\'ll just have to work hard to reach your milestones again. We believe in you.',
                    isDarkMode: isDarkMode,
                  ),
                  _buildCard(
                    question: 'Is the app free?',
                    answer:
                        'Yes, the app is completely free to use. Optional features may be added in the future, but the core experience will always remain free.',
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

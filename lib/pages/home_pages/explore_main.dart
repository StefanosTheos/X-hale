import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/pages/explore_pages/break_habits.dart';
import 'package:smoking/pages/explore_pages/distractions_main.dart';
import 'package:smoking/pages/explore_pages/exercise_is_key.dart';
import 'package:smoking/pages/explore_pages/mental_prep.dart';
import 'package:smoking/pages/explore_pages/mini_games.dart';
import 'package:smoking/pages/explore_pages/non_smoker_mindset.dart';
import 'package:smoking/pages/explore_pages/nutritional_tips.dart';
import 'package:smoking/pages/explore_pages/sleep_matters.dart';
import 'package:smoking/pages/explore_pages/withdrawal_tips.dart';
import 'package:smoking/pages/explore_pages/breathing.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';
class ExplorePage extends ConsumerWidget {
  ExplorePage({super.key});

  final List<Map<String, dynamic>> sections = [
    const {
      'title': 'Tips & Preparation',
      'items': [
        {
          'title': 'Withdrawal Tips',
          'icon': 'assets/icons/withdrawal.png',
          'page': WithdrawalTipsPage(),
        },
        {
          'title': 'Mental Prep',
          'icon': 'assets/icons/mental-prep.png',
          'page': MentalPrepPage(),
        },
        {
          'title': 'Break Habits',
          'icon': 'assets/icons/habits.png',
          'page': BreakHabitsPage(),
        },
      ],
    },
    const {
      'title': 'Wellness & Support',
      'items': [
        {
          'title': 'Non-Smoker Mindset',
          'icon': 'assets/icons/mindset.png',
          'page': NonSmokerMindsetPage(),
        },
        {
          'title': 'Nutrition Tips',
          'icon': 'assets/icons/nutrition.png',
          'page': NutritionalTipsPage(),
        },
        {
          'title': 'Sleep Matters',
          'icon': 'assets/icons/sleep.png',
          'page': SleepMattersPage(),
        },
        {
          'title': 'Exercise is Key',
          'icon': 'assets/icons/exercise.png',
          'page': ExerciseIsKeyPage(),
        },
      ],
    },
    {
      'title': 'Interactive Tools',
      'items': [
        const {
          'title': 'Breathing Techniques',
          'icon': 'assets/icons/breathing.png',
          'page': BreathingExercisePage(),
        },
        {
          'title': 'Mini Games',
          'icon': 'assets/icons/mini-games.png',
          'page': MiniGamesPage(),
        },
        const {
          'title': 'Distractions',
          'icon': 'assets/icons/distractions.png',
          'page': DistractionsPage(),
        },
      ],
    },
  ];

  final List<Color> cardColors = const [
    Color(0xFFE3F2FD),
    Color(0xFFFFF3E0),
    Color(0xFFE8F5E9),
    Color(0xFFFFEBEE),
    Color(0xFFF3E5F5),
    Color(0xFFFFF9C4),
    Color(0xFFDCEDC8),
    Color(0xFFFFCDD2),
    Color(0xFFD1C4E9),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Explore',
          style: TextStyle(
            color: isDark ? Colors.white : AppThemes.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        elevation: 4,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white70 : AppThemes.lightIconColor,
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient:
                isDark
                    ? AppThemes.darkExploreGradient
                    : AppThemes.lightGradient,
          ),
          child: ListView(
            children:
                sections.map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? Color.fromRGBO(255, 255, 255, 0.9)
                                  : AppThemes.lightTitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: section['items'].length,
                          itemBuilder: (context, index) {
                            final item = section['items'][index];
                            final isBreathing =
                                item['title'] == 'Breathing Techniques';
                            final color =
                                isBreathing
                                    ? const Color.fromARGB(255, 119, 203, 196)
                                    : cardColors[(index +
                                            section['title'].hashCode) %
                                        cardColors.length];
                            return _buildExploreCard(
                              context,
                              item,
                              color,
                              isDark,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildExploreCard(
    BuildContext context,
    Map<String, dynamic> item,
    Color backgroundColor,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item['page']),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isDark
                  ? backgroundColor.withAlpha((0.9 * 255).round())
                  : backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(
                ((isDark ? 0.2 : 0.1) * 255).round(),
              ),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(item['icon'], width: 40, height: 40, color: null),
                const SizedBox(height: 12),
                Text(
                  item['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        isDark
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap to learn more',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? const Color.fromARGB(179, 0, 0, 0)
                            : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (isDark)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppThemes.darkCardOverlay,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

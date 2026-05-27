import 'package:flutter/material.dart';
import 'package:smoking/pages/explore_pages/widgets/tips_page.dart';
import 'package:smoking/pages/utils/themes.dart';

class ExerciseIsKeyPage extends StatelessWidget {
  const ExerciseIsKeyPage({super.key});

  static const List<Map<String, dynamic>> _exerciseTips = [
    {
      'title': 'Start Small',
      'description':
          'Begin with light activities like walking or stretching to build momentum.',
      'icon': Icons.directions_walk,
      'color': Color.fromARGB(255, 255, 186, 193),
    },
    {
      'title': 'Make it a Habit',
      'description':
          'Schedule workouts like appointments to stay consistent over time.',
      'icon': Icons.calendar_today,
      'color': Color(0xFFEF9A9A),
    },
    {
      'title': 'Find Activities You Enjoy',
      'description':
          'Dance, swim, bike — movement should feel rewarding, not like a chore.',
      'icon': Icons.sports_gymnastics,
      'color': Color(0xFFE57373),
    },
    {
      'title': 'Use Exercise for Cravings',
      'description':
          'Physical activity helps reduce nicotine withdrawal symptoms and anxiety.',
      'icon': Icons.fitness_center,
      'color': Color(0xFFEF5350),
    },
    {
      'title': 'Track Your Progress',
      'description':
          'Seeing your improvements boosts motivation and reinforces the habit.',
      'icon': Icons.show_chart,
      'color': Color(0xFFF44336),
    },
    {
      'title': 'Stretch & Recover',
      'description':
          'Proper recovery prevents injuries and keeps your body feeling good.',
      'icon': Icons.accessibility_new,
      'color': Color(0xFFE53935),
    },
    {
      'title': 'Work Out with Friends',
      'description':
          'Exercising with others adds fun and accountability to your routine.',
      'icon': Icons.group,
      'color': Color(0xFFD32F2F),
    },
    {
      'title': 'Celebrate Every Step',
      'description':
          'Whether it’s a 10-minute walk or full workout, every effort counts.',
      'icon': Icons.celebration,
      'color': Color(0xFFC62828),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return TipsPage(
      title: 'Exercise is Key',
      appBarColor: const Color(0xFFE57373),
      lightGradient: AppThemes.exerciseGradient,
      tips: _exerciseTips,
    );
  }
}

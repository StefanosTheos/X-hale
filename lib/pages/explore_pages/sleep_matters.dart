import 'package:flutter/material.dart';
import 'package:smoking/pages/explore_pages/widgets/tips_page.dart';
import 'package:smoking/pages/utils/themes.dart';

class SleepMattersPage extends StatelessWidget {
  const SleepMattersPage({super.key});

  static const List<Map<String, dynamic>> _sleepTips = [
    {
      'title': 'Stick to a Schedule',
      'description':
          'Go to bed and wake up at the same time every day—even on weekends.',
      'icon': Icons.schedule,
      'color': Color.fromARGB(255, 216, 231, 199),
    },
    {
      'title': 'Create a Wind-Down Routine',
      'description':
          'Establish calming habits before bed, like reading or deep breathing.',
      'icon': Icons.self_improvement,
      'color': Color.fromARGB(242, 220, 237, 200),
    },
    {
      'title': 'Limit Screen Time',
      'description':
          'Avoid phones and TVs 30–60 minutes before sleep to reduce blue light exposure.',
      'icon': Icons.phone_disabled,
      'color': Color.fromARGB(255, 211, 233, 186),
    },
    {
      'title': 'Keep Your Room Cool & Dark',
      'description':
          'Optimal sleep happens in a quiet, cool, and dark environment.',
      'icon': Icons.bedroom_parent,
      'color': Color(0xFFC5E1A5),
    },
    {
      'title': 'Avoid Caffeine Late',
      'description':
          'Skip coffee, energy drinks, or even chocolate after mid-afternoon.',
      'icon': Icons.no_meals,
      'color': Color(0xFFAED581),
    },
    {
      'title': 'Don’t Eat Right Before Bed',
      'description':
          'Heavy meals too close to bedtime can disrupt your sleep cycle.',
      'icon': Icons.dinner_dining,
      'color': Color(0xFF9CCC65),
    },
    {
      'title': 'Get Sunlight Exposure',
      'description':
          'Natural light during the day helps regulate your internal clock.',
      'icon': Icons.wb_sunny,
      'color': Color(0xFF8BC34A),
    },
    {
      'title': 'Use Bed Only for Sleep',
      'description':
          'Train your brain to associate bed with rest, not screens or work.',
      'icon': Icons.bed,
      'color': Color(0xFF7CB342),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return TipsPage(
      title: 'Sleep Matters',
      appBarColor: const Color(0xFFAED581),
      lightGradient: AppThemes.sleepGradient,
      tips: _sleepTips,
      iconColor: Colors.black54,
    );
  }
}

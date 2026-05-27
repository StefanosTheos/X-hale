import 'package:flutter/material.dart';
import 'package:smoking/pages/explore_pages/widgets/tips_page.dart';
import 'package:smoking/pages/utils/themes.dart';

class BreakHabitsPage extends StatelessWidget {
  const BreakHabitsPage({super.key});

  static const List<Map<String, dynamic>> _habitTips = [
    {
      'title': 'Identify Triggers',
      'description':
          'Become aware of the people, places, or emotions that lead to the bad habit.',
      'icon': Icons.search,
      'color': Color.fromARGB(255, 226, 199, 237),
    },
    {
      'title': 'Replace With Positive Habits',
      'description':
          'Substitute bad habits with healthy alternatives like exercising or journaling.',
      'icon': Icons.loop,
      'color': Color.fromARGB(255, 232, 187, 243),
    },
    {
      'title': 'Start Small',
      'description':
          'Break the habit into small, manageable steps for long-term change.',
      'icon': Icons.stairs,
      'color': Color.fromARGB(255, 227, 175, 237),
    },
    {
      'title': 'Visual Cues Help',
      'description':
          'Use sticky notes or reminders on your phone to stay mindful throughout the day.',
      'icon': Icons.notifications_active,
      'color': Color.fromARGB(255, 221, 164, 232),
    },
    {
      'title': 'Celebrate Progress',
      'description':
          'Acknowledge small victories to stay motivated and build momentum.',
      'icon': Icons.celebration,
      'color': Color(0xFFD794E3),
    },
    {
      'title': 'Practice Mindfulness',
      'description':
          'Stay present and notice urges without acting on them impulsively.',
      'icon': Icons.self_improvement,
      'color': Color(0xFFCF7DDD),
    },
    {
      'title': 'Build Accountability',
      'description':
          'Tell someone your goals or track progress in a habit app to stay consistent.',
      'icon': Icons.group,
      'color': Color(0xFFC766D7),
    },
    {
      'title': 'Be Patient & Kind',
      'description':
          'Change takes time. Don’t beat yourself up—self-compassion builds resilience.',
      'icon': Icons.volunteer_activism,
      'color': Color(0xFFBF4FD1),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return TipsPage(
      title: 'Break Bad Habits',
      appBarColor: const Color(0xFFCE93D8),
      lightGradient: AppThemes.breakhabitsGradient,
      tips: _habitTips,
    );
  }
}

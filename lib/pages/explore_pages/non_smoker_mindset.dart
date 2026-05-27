import 'package:flutter/material.dart';
import 'package:smoking/pages/explore_pages/widgets/tips_page.dart';
import 'package:smoking/pages/utils/themes.dart';

class NonSmokerMindsetPage extends StatelessWidget {
  const NonSmokerMindsetPage({super.key});

  static const List<Map<String, dynamic>> _mindsetTips = [
    {
      'title': 'I Am a Non-Smoker',
      'description':
          'Stop identifying as a smoker. Embrace your new identity as someone who values freedom and health.',
      'icon': Icons.person,
      'color': Color.fromARGB(255, 204, 181, 239),
    },
    {
      'title': 'Freedom Over Addiction',
      'description':
          'You are choosing freedom—freedom from cravings, dependency, and smoke.',
      'icon': Icons.flag,
      'color': Color.fromARGB(255, 203, 176, 247),
    },
    {
      'title': 'My Health Is Priority',
      'description':
          'Breathing fresh air, having clean lungs, and living longer is worth more than any cigarette.',
      'icon': Icons.health_and_safety,
      'color': Color.fromARGB(255, 183, 154, 228),
    },
    {
      'title': 'Each Craving Is a Victory',
      'description':
          'Every time you resist a craving, you build power and momentum.',
      'icon': Icons.military_tech,
      'color': Color.fromARGB(255, 179, 149, 227),
    },
    {
      'title': 'I Control My Choices',
      'description':
          'You are in control. Smoking does not define you—your actions do.',
      'icon': Icons.handyman,
      'color': Color(0xFFA986E0),
    },
    {
      'title': 'Visualize Your Smoke-Free Life',
      'description':
          'Picture yourself living with energy, confidence, and pride.',
      'icon': Icons.visibility,
      'color': Color(0xFF9B73DA),
    },
    {
      'title': 'Setbacks Don’t Define Me',
      'description':
          'If you slip, it’s okay. Get back up stronger. Growth is not linear.',
      'icon': Icons.restart_alt,
      'color': Color(0xFF8D5FD5),
    },
    {
      'title': 'This Is My Transformation',
      'description':
          'You’re not just quitting smoking. You’re becoming the best version of yourself.',
      'icon': Icons.upgrade,
      'color': Color(0xFF7F4BCF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return TipsPage(
      title: 'Non-Smoker Mindset',
      appBarColor: const Color(0xFFB39DDB),
      lightGradient: AppThemes.nonsmokerGradient,
      tips: _mindsetTips,
    );
  }
}

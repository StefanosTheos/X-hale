import 'package:flutter/material.dart';
import 'package:smoking/pages/explore_pages/widgets/tips_page.dart';
import 'package:smoking/pages/utils/themes.dart';

class MentalPrepPage extends StatelessWidget {
  const MentalPrepPage({super.key});

  static const List<Map<String, dynamic>> _mentalTips = [
    {
      'title': 'Define Your “Why”',
      'description':
          'Write down the reasons you want to quit—your health, family, freedom. Revisit them daily.',
      'icon': Icons.favorite,
      'color': Color.fromARGB(255, 255, 186, 193),
    },
    {
      'title': 'Visualize Success',
      'description':
          'Close your eyes and picture yourself free from smoking—healthy, proud, and in control.',
      'icon': Icons.visibility,
      'color': Color(0xFFEF9A9A),
    },
    {
      'title': 'Expect Cravings',
      'description':
          'Know that cravings will come—and they will pass. Mentally rehearsing this builds resilience.',
      'icon': Icons.hourglass_top,
      'color': Color(0xFFE57373),
    },
    {
      'title': 'Affirm Yourself Daily',
      'description':
          'Repeat empowering phrases like “I am stronger than this craving” or “I choose health.”',
      'icon': Icons.record_voice_over,
      'color': Color(0xFFEF5350),
    },
    {
      'title': 'Accept Setbacks',
      'description':
          'Slipping is part of the journey. Don’t be hard on yourself—reset and keep going.',
      'icon': Icons.refresh,
      'color': Color(0xFFF44336),
    },
    {
      'title': 'Own Your Identity',
      'description':
          'Stop thinking of yourself as “a smoker trying to quit.” You are a non-smoker reclaiming your life.',
      'icon': Icons.verified_user,
      'color': Color(0xFFE53935),
    },
    {
      'title': 'Plan for Triggers',
      'description':
          'Identify situations that tempt you and create a plan—walk away, breathe, or call someone.',
      'icon': Icons.lightbulb,
      'color': Color(0xFFD32F2F),
    },
    {
      'title': 'Celebrate Small Wins',
      'description':
          'Every hour, every day without smoking is a victory. Be proud of your strength.',
      'icon': Icons.emoji_events,
      'color': Color(0xFFC62828),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return TipsPage(
      title: 'Mental Preparation',
      appBarColor: const Color(0xFFE57373),
      lightGradient: AppThemes.mentalPrepGradient,
      tips: _mentalTips,
    );
  }
}

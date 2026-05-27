import 'package:flutter/material.dart';
import 'package:smoking/pages/explore_pages/widgets/tips_page.dart';
import 'package:smoking/pages/utils/themes.dart';

class WithdrawalTipsPage extends StatelessWidget {
  const WithdrawalTipsPage({super.key});

  static const List<Map<String, dynamic>> _tips = [
    {
      'title': 'Stay Hydrated',
      'description':
          'Drink water frequently. It helps flush nicotine out of your system and reduces cravings.',
      'icon': Icons.local_drink,
      'color': Color.fromARGB(255, 216, 231, 199),
    },
    {
      'title': 'Breathe Deeply',
      'description':
          'Practice slow, deep breathing for 2–3 minutes to calm anxiety and reduce cravings.',
      'icon': Icons.air,
      'color': Color.fromARGB(242, 220, 237, 200),
    },
    {
      'title': 'Move Your Body',
      'description':
          'Take a walk or stretch. Physical movement boosts mood and distracts from urges.',
      'icon': Icons.directions_walk,
      'color': Color.fromARGB(255, 211, 233, 186),
    },
    {
      'title': 'Snack Smart',
      'description':
          'Chew on healthy snacks like carrots, nuts, or gum to keep your hands and mouth busy.',
      'icon': Icons.fastfood,
      'color': Color(0xFFC5E1A5),
    },
    {
      'title': 'Talk to Someone',
      'description':
          'Reach out to a friend or support group when you feel overwhelmed.',
      'icon': Icons.support_agent,
      'color': Color(0xFFAED581),
    },
    {
      'title': 'Ride the Craving Wave',
      'description':
          'Each craving lasts only a few minutes. Remind yourself: "This will pass."',
      'icon': Icons.access_time,
      'color': Color(0xFF9CCC65),
    },
    {
      'title': 'Sleep Well',
      'description':
          'Prioritize good sleep. Fatigue makes cravings worse and weakens willpower.',
      'icon': Icons.nights_stay,
      'color': Color(0xFF8BC34A),
    },
    {
      'title': 'Write It Out',
      'description':
          'Journaling your emotions can reduce stress and help process what you feel.',
      'icon': Icons.edit_note,
      'color': Color(0xFF7CB342),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return TipsPage(
      title: 'Withdrawal Tips',
      appBarColor: const Color(0xFFAED581),
      lightGradient: AppThemes.withdrawalGradient,
      tips: _tips,
    );
  }
}

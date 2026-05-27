import 'package:flutter/material.dart';
import 'package:smoking/pages/explore_pages/widgets/tips_page.dart';
import 'package:smoking/pages/utils/themes.dart';

class NutritionalTipsPage extends StatelessWidget {
  const NutritionalTipsPage({super.key});

  static const List<Map<String, dynamic>> _nutritionTips = [
    {
      'title': 'Eat Whole Foods',
      'description':
          'Prioritize unprocessed, natural foods like fruits, vegetables, legumes, and whole grains.',
      'icon': Icons.eco,
      'color': Color.fromARGB(255, 255, 211, 145),
    },
    {
      'title': 'Stay Hydrated',
      'description':
          'Drink plenty of water throughout the day. It supports digestion and curbs unnecessary cravings.',
      'icon': Icons.local_drink,
      'color': Color.fromARGB(255, 255, 210, 142),
    },
    {
      'title': 'Don’t Skip Meals',
      'description':
          'Skipping meals can lead to energy crashes and unhealthy snacking. Stick to a consistent routine.',
      'icon': Icons.schedule,
      'color': Color(0xFFFFCC80),
    },
    {
      'title': 'Balance Your Plate',
      'description':
          'Aim for a mix of protein, healthy fats, and complex carbohydrates at each meal.',
      'icon': Icons.pie_chart,
      'color': Color(0xFFFFB74D),
    },
    {
      'title': 'Limit Added Sugar',
      'description':
          'Cut back on sugary drinks and snacks to reduce energy crashes and cravings.',
      'icon': Icons.no_food,
      'color': Color(0xFFFFA726),
    },
    {
      'title': 'Snack Smart',
      'description':
          'Choose nuts, yogurt, fruits, or veggies instead of chips or candy.',
      'icon': Icons.restaurant,
      'color': Color(0xFFFF9800),
    },
    {
      'title': 'Listen to Your Body',
      'description':
          'Eat when you’re hungry, stop when you’re full. Mindful eating prevents overeating.',
      'icon': Icons.hearing,
      'color': Color(0xFFFB8C00),
    },
    {
      'title': 'Plan Ahead',
      'description':
          'Meal prepping or keeping healthy snacks on hand helps you avoid impulse eating.',
      'icon': Icons.calendar_month,
      'color': Color(0xFFF57C00),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return TipsPage(
      title: 'Nutritional Tips',
      appBarColor: const Color(0xFFFFB74D),
      lightGradient: AppThemes.nutritionGradient,
      tips: _nutritionTips,
      iconColor: Colors.black54,
    );
  }
}

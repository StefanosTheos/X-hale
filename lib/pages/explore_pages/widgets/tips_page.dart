import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/explore_pages/widgets/tip_card.dart';
import 'package:smoking/pages/utils/themes.dart';

/// Shared scaffold for the seven explore-pages tip lists
/// (`non_smoker_mindset`, `mental_prep`, `withdrawal_tips`, etc.). Each
/// page used to inline its own ~150-line `Scaffold → AppBar → SafeArea →
/// Container → ListView.separated` with only the title / appbar color /
/// light gradient / tip list / (optionally) icon color varying.
///
/// The dark gradient is the same `AppThemes.darkExploreGradient` for all
/// seven pages, so it's not parameterised.
class TipsPage extends ConsumerWidget {
  final String title;
  final Color appBarColor;
  final Gradient lightGradient;
  final List<Map<String, dynamic>> tips;
  /// Two pages (`nutritional_tips`, `sleep_matters`) use the lighter
  /// `Colors.black54` for the card icon. The rest use the default
  /// `Colors.black87`.
  final Color iconColor;

  const TipsPage({
    super.key,
    required this.title,
    required this.appBarColor,
    required this.lightGradient,
    required this.tips,
    this.iconColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appBarColor,
        elevation: 4,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppThemes.darkExploreGradient : lightGradient,
          ),
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: tips.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final tip = tips[index];
              return TipCard(
                icon: tip['icon'] as IconData,
                title: tip['title'] as String,
                description: tip['description'] as String,
                color: tip['color'] as Color,
                iconColor: iconColor,
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:smoking/pages/utils/themes.dart';

/// Card shell used by the settings forms (`change_account_info`,
/// `change_smoking_preferences`) to group related rows. Previously declared
/// byte-identically as `_buildCard` in both pages.
class SettingsFormCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const SettingsFormCard({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      color: isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: child,
      ),
    );
  }
}

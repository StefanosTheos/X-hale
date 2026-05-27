import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/themes.dart';

/// Standard list-item-style card used for each row on the Account Settings
/// page ("Relapse", "Edit Quit Date", "Logout", etc.). Extracted verbatim from
/// the nested `buildSettingsCard` helper that lived in `account.dart`.
class SettingsCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDark;
    return Card(
      color: isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark
                ? AppThemes.darkSubtitleColor
                : AppThemes.lightSubtitleColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isDark ? AppThemes.darkIconColor : AppThemes.lightIconColor,
        ),
        onTap: onTap,
      ),
    );
  }
}

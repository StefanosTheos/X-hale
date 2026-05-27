import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/themes.dart';

/// Standard "pill" button used at the bottom of every home-dashboard section
/// ("See all milestones", "Forum", etc.). Extracted verbatim from `home.dart`'s
/// `_customButton` helper.
class HomeButton extends ConsumerWidget {
  final String text;
  final VoidCallback onPressed;
  final String iconPath;

  const HomeButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDark;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? AppThemes.darkCloseButtonColor
            : AppThemes.lightCloseButtonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onPressed,
      icon: Image.asset(iconPath, width: 24, height: 24),
      label: Text(text),
    );
  }
}

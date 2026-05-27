import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/user_provider.dart';

/// Snapshot of the half-dozen theme-derived colors that every page used to
/// re-compute from `isDark`. Pages do `final colors = ref.themeColors;` once,
/// then reference `colors.text`, `colors.subtitle`, etc. without the
/// ternary cascade. Only the `isDark` bool is watched (via `.select`), so the
/// page rebuilds only when the theme actually flips.
class ThemeColors {
  ThemeColors._(this.isDark)
      : text = isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
        subtitle = isDark
            ? AppThemes.darkSubtitleColor
            : AppThemes.lightSubtitleColor,
        icon = isDark ? AppThemes.darkIconColor : AppThemes.lightIconColor,
        card = isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
        appBar = isDark
            ? AppThemes.darkAppBarColor
            : AppThemes.lightAppBarColor,
        active = isDark ? AppThemes.activeColor : AppThemes.primaryBlue;

  final bool isDark;
  final Color text;
  final Color? subtitle;
  final Color icon;
  final Color card;
  final Color appBar;
  final Color active;
}

/// Shortcut for the dark-theme branching that's read in dozens of pages.
///
/// Use `ref.isDark` for a single boolean check, or `ref.themeColors` for the
/// full color bundle. Both go through one `.select` watch, so the widget only
/// rebuilds when the theme actually flips.
extension RefThemeX on WidgetRef {
  bool get isDark => watch(userProvider.select((u) => u.theme == 'dark'));

  ThemeColors get themeColors => ThemeColors._(isDark);
}

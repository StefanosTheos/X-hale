import 'package:flutter/material.dart';

/// Standard "back arrow + centered bold title" AppBar shared by every page
/// that doesn't need a custom AppBar shape. Background and foreground colors
/// come from `MaterialApp.appBarTheme` (wired in `main.dart`), so pages no
/// longer have to recompute the theme-aware overrides.
///
/// Use this everywhere a page just needs a title and a back button. For pages
/// with bottom tab bars, multiple custom actions, or non-standard styling,
/// stick with a hand-rolled `AppBar`.
class BackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BackAppBar({
    super.key,
    required this.title,
    this.actions,
    this.elevation = 0,
  });

  final String title;
  final List<Widget>? actions;
  final double elevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: elevation,
      centerTitle: true,
      actions: actions,
    );
  }
}

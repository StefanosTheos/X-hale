import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/themes.dart';

/// A titled card-style container used throughout the home dashboard. Extracted
/// verbatim from `home.dart`'s `_framedSection` helper so multiple section
/// widgets can use it without depending on the parent State.
class FramedSection extends ConsumerWidget {
  final String title;
  final Widget child;
  final bool transparent;
  final bool addTopSpacing;

  const FramedSection({
    super.key,
    required this.title,
    required this.child,
    this.transparent = false,
    this.addTopSpacing = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (addTopSpacing) const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: transparent
                ? Colors.transparent
                : isDark
                    ? AppThemes.darkCardColor
                    : AppThemes.lightCardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: transparent
                ? []
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withAlpha((0.3 * 255).round())
                          : Colors.grey.shade300,
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: child,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:smoking/pages/utils/themes.dart';

/// Centered icon + title + (optional) subtitle, used as the "nothing here yet"
/// placeholder for empty lists across the diary, forum, and friends tabs.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor;
    final subColor =
        isDark ? AppThemes.darkSubtitleColor : AppThemes.lightSubtitleColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: subColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: subColor, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

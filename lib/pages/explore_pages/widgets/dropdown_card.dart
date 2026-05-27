import 'package:flutter/material.dart';
import 'package:smoking/pages/utils/themes.dart';

/// Card wrapper around a Material `DropdownButton<T>` used by the breathing
/// and stretching pages for technique / duration selection. Previously
/// declared byte-similarly as `_buildDropdownCard<T>` in each. Only the
/// light-theme card / label colors differed between the two pages — those
/// are exposed as optional overrides.
class DropdownCard<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isDark;
  /// Card background color in light mode. Defaults to `AppThemes.lightCardColor`;
  /// `breathing.dart` overrides with `Color(0xffe0f7fa)` (light cyan).
  final Color? lightCardColor;
  /// Label text color in light mode. Defaults to `AppThemes.lightTitleColor`;
  /// `breathing.dart` overrides with `Color(0xff00796b)` (teal).
  final Color? lightLabelColor;

  const DropdownCard({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
    this.lightCardColor,
    this.lightLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppThemes.darkCardColor : (lightCardColor ?? AppThemes.lightCardColor);
    final labelColor = isDark
        ? AppThemes.darkTextColor
        : (lightLabelColor ?? AppThemes.lightTitleColor);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: labelColor,
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: items,
                onChanged: onChanged,
                style: TextStyle(
                  color: isDark ? AppThemes.darkTextColor : Colors.black87,
                ),
                dropdownColor:
                    isDark ? AppThemes.darkCardColor : Colors.white,
                iconEnabledColor:
                    isDark ? AppThemes.darkIconColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

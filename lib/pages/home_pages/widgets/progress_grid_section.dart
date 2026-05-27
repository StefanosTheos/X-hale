import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/progress_provider.dart';
import 'package:smoking/providers/user_provider.dart';

/// 2×2 "Progress" grid showing cigarettes avoided / money saved / life gained
/// / time saved. Each tile watches a single field via `select` so only the
/// changed value rebuilds its tile.
class ProgressGridSection extends ConsumerWidget {
  const ProgressGridSection({super.key});

  /// Compact human-readable duration. Switches from `Hh Mm` to `Dd Hh` once a
  /// full day has passed so the user sees "5d 3h" instead of "123h 47m".
  static String _formatDuration(Duration d) {
    if (d.inHours >= 24) {
      final days = d.inDays;
      final hours = d.inHours % 24;
      return '${days}d ${hours}h';
    }
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  Widget _tile(
    String title,
    String value,
    String iconPath,
    TextStyle titleStyle,
    TextStyle valueStyle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(iconPath, width: 24, height: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: Text(title, style: titleStyle)),
              const SizedBox(height: 2),
              Flexible(child: Text(value, style: valueStyle)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDark;
    final currency =
        ref.watch(userProvider.select((u) => u.selectedCurrency));
    // Hoisted once per build instead of allocated twice per tile per Consumer
    // rebuild. The tile styles only depend on `isDark`; the 4 tiles each
    // watch a different progress field, so without this the per-second
    // counter tick was building 2 fresh `TextStyle`s on whichever tile
    // changed.
    final textColor =
        isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor;
    final titleStyle = TextStyle(fontSize: 14, color: textColor);
    final valueStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Progress',
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
            color: isDark ? AppThemes.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha((0.3 * 255).round())
                    : Colors.grey.shade300,
                blurRadius: 10,
              ),
            ],
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3.8,
            children: [
              Consumer(builder: (context, ref, _) {
                final cigs =
                    ref.watch(progressProvider.select((p) => p.cigsAvoided));
                return _tile(
                  'Cigarettes avoided',
                  '$cigs',
                  'assets/icons/cigarette.png',
                  titleStyle,
                  valueStyle,
                );
              }),
              Consumer(builder: (context, ref, _) {
                final money =
                    ref.watch(progressProvider.select((p) => p.moneySaved));
                return _tile(
                  'Money saved',
                  '$currency${money.toStringAsFixed(2)}',
                  'assets/icons/money.png',
                  titleStyle,
                  valueStyle,
                );
              }),
              Consumer(builder: (context, ref, _) {
                final life =
                    ref.watch(progressProvider.select((p) => p.lifeGained));
                return _tile(
                  'Life gained',
                  _formatDuration(life),
                  'assets/icons/life.png',
                  titleStyle,
                  valueStyle,
                );
              }),
              Consumer(builder: (context, ref, _) {
                final time =
                    ref.watch(progressProvider.select((p) => p.timeSaved));
                return _tile(
                  'Time saved',
                  _formatDuration(time),
                  'assets/icons/time.png',
                  titleStyle,
                  valueStyle,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

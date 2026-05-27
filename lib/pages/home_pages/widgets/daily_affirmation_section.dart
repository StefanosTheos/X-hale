import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/constants/affirmations.dart';
import 'package:smoking/extensions/datetime.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/home_pages/widgets/framed_section.dart';
import 'package:smoking/pages/utils/themes.dart';

const _fallbackAffirmation = '"You are stronger than your cravings."';

/// "Daily Affirmation" card on the home dashboard. Picks an affirmation
/// deterministically from the local list using `dayOfYear % length`.
class DailyAffirmationSection extends ConsumerWidget {
  const DailyAffirmationSection({super.key});

  // Synchronous — there's no I/O involved. Previously wrapped in a Future +
  // FutureBuilder, which built a fresh Future on every rebuild. The home
  // dashboard's 1 Hz progress tick re-ran this section every second, so the
  // affirmation briefly flashed to the null-data fallback on each frame.
  String _affirmationForToday() {
    if (dailyAffirmations.isEmpty) return _fallbackAffirmation;
    final dayOfYear = DateTime.now().toLocal().dayOfYear;
    return '"${dailyAffirmations[dayOfYear % dailyAffirmations.length]}"';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDark;
    return FramedSection(
      title: 'Daily Affirmation',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Center(
          child: Text(
            _affirmationForToday(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

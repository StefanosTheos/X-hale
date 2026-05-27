import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/home_pages/challenges_main.dart';
import 'package:smoking/pages/home_pages/widgets/framed_section.dart';
import 'package:smoking/pages/home_pages/widgets/home_button.dart';
import 'package:smoking/pages/utils/animated_progress_bar.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/challenge_provider.dart';
import 'package:smoking/providers/progress_provider.dart';
import 'package:smoking/providers/user_provider.dart';

/// "Ongoing Challenges" home-dashboard section — list of active challenges
/// (or an empty-state card if there are none), plus a CTA into the full
/// challenges page. Extracted verbatim from `home.dart::_buildOngoingChallenges`.
class OngoingChallengesSection extends ConsumerWidget {
  const OngoingChallengesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the per-challenge progress bars care about `moneySaved`; narrowing
    // avoids a 1 Hz rebuild of this section's button + card layout.
    final moneySaved =
        ref.watch(progressProvider.select((s) => s.moneySaved));
    final challengeState = ref.watch(challengeProvider);
    final currency =
        ref.watch(userProvider.select((u) => u.selectedCurrency));
    final isDark = ref.isDark;
    final ongoingChallenges = challengeState.challenges
        .where((c) => c.status.toLowerCase().trim() == 'active')
        .toList();

    return FramedSection(
      title: 'Ongoing Challenges',
      transparent: true,
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ongoingChallenges.isNotEmpty) ...[
              ...ongoingChallenges.map((challenge) {
                return Padding(
                  // Stable identity per challenge so element reconciliation
                  // doesn't swap state (progress bars, animations) when the
                  // ordering shifts after a status update.
                  key: ValueKey('challenge-${challenge.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      color: isDark ? AppThemes.darkCardColor : Colors.white,
                      child: ListTile(
                        leading: Image.asset(
                          challenge.iconPath,
                          width: 40,
                          height: 40,
                        ),
                        title: Text(
                          challenge.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color:
                                isDark ? AppThemes.darkTextColor : Colors.black,
                          ),
                        ),
                        subtitle: challenge.type.trim().toLowerCase() ==
                                'physical'
                            ? Text(
                                challenge.lastEntry != null
                                    ? 'Last entry: ${DateFormat('dd MMM yyyy').format(challenge.lastEntry!)}'
                                    : 'No entries yet',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppThemes.darkSubtitleColor
                                      : Colors.grey.shade700,
                                ),
                              )
                            : Builder(
                                builder: (_) {
                                  final saved = moneySaved;
                                  final goal = challenge.goalBudget;
                                  final progressValue = (goal == 0)
                                      ? 0.0
                                      : (saved / goal!).clamp(0.0, 1.0);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      AnimatedProgressBar(
                                        targetProgress: progressValue,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$currency${saved.toStringAsFixed(2)} / $currency${goal?.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppThemes.darkSubtitleColor
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppThemes.darkCardColor
                          .withAlpha((0.7 * 255).round())
                      : Colors.white.withAlpha((0.7 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icons/no-challenges.png',
                      width: 60,
                      height: 60,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have no active challenges',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? AppThemes.darkSubtitleColor
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Center(
              child: HomeButton(
                text: ongoingChallenges.isNotEmpty
                    ? 'See all challenges'
                    : 'Create a challenge',
                iconPath: 'assets/icons/challenges.png',
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChallengesPage(),
                    ),
                  );
                  if (updated == true) ref.invalidate(challengeProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

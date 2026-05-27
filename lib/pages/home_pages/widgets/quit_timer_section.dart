import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/home_pages/milestones.dart';
import 'package:smoking/pages/home_pages/widgets/framed_section.dart';
import 'package:smoking/pages/home_pages/widgets/home_button.dart';
import 'package:smoking/pages/utils/animated_progress_bar.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/milestone_provider.dart';
import 'package:smoking/providers/progress_provider.dart';
import 'package:smoking/providers/user_provider.dart';

/// "Smoke-Free for" + "Milestones" sections on the home dashboard. Holds the
/// dropdown for milestone-type (Day/Week/Month/Year) and the per-second timer
/// readout. Pulled out of `home.dart` so the 1 Hz progress tick (driving the
/// timer) rebuilds only this subtree instead of the whole HomePage.
class QuitTimerSection extends ConsumerStatefulWidget {
  const QuitTimerSection({super.key});

  @override
  ConsumerState<QuitTimerSection> createState() => _QuitTimerSectionState();
}

class _QuitTimerSectionState extends ConsumerState<QuitTimerSection> {
  // Which tier (Day/Week/Month/Year) drives the "next milestone" countdown.
  // Local UI state — used to live on `HomePageState`.
  String _selectedMilestoneType = 'Month';

  Widget _buildTimeUnit(String value, String label, bool isDark) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? AppThemes.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha((0.3 * 255).round())
                    : Colors.grey.shade300,
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppThemes.darkTextColor : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppThemes.darkSubtitleColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isDark = ref.isDark;
    final progressState = ref.watch(progressProvider);

    final days = progressState.timeSinceQuit.inDays;
    final hours = progressState.timeSinceQuit.inHours % 24;
    final minutes = progressState.timeSinceQuit.inMinutes % 60;
    final seconds = progressState.timeSinceQuit.inSeconds % 60;

    final now =
        DateFormat('MMMM d, yyyy - HH:mm').format(DateTime.now().toLocal());

    // Memoised — the `nextMilestoneProvider` only re-runs its `where`/`sort`
    // when the milestone list reference changes (toggle, refresh, etc.),
    // not on every 1 Hz rebuild driven by the progress tick.
    final nextMilestone =
        ref.watch(nextMilestoneProvider(_selectedMilestoneType));
    final startDate =
        ref.watch(milestoneProvider.select((s) => s.startDate));
    // Distinguish "milestones haven't loaded yet" (cold-boot, fetch in
    // flight) from "every milestone in this tier is already done". Both
    // make `nextMilestone` null, but only the latter is a legitimate
    // progress = 1.0 state. Without this guard, on cold boot the bar
    // animated from 0 → 1 during the load window then dropped to the
    // real percentage once `milestoneProvider.initializeFromUser` finished
    // — the visible "milestone flash" on every app launch.
    final milestonesLoaded = ref.watch(
      milestoneProvider.select((s) => s.allMilestones.isNotEmpty),
    );

    final String milestoneLabel;
    final double progress;
    final DateTime targetDate;
    final nowTime = DateTime.now();
    if (nextMilestone == null) {
      if (!milestonesLoaded) {
        milestoneLabel = 'Loading…';
        progress = 0.0;
        targetDate = nowTime;
      } else {
        milestoneLabel = 'All milestones reached!';
        progress = 1.0;
        targetDate = nowTime;
      }
    } else {
      milestoneLabel = nextMilestone.title;
      targetDate = nextMilestone.date;
      final totalDuration =
          nextMilestone.date.difference(startDate).inSeconds.toDouble();
      final currentDuration =
          nowTime.difference(startDate).inSeconds.toDouble();
      progress = (currentDuration / totalDuration).clamp(0.0, 1.0);
    }
    final remaining = targetDate.difference(nowTime);
    final remainingText = () {
      // No countdown to display when there is no next milestone — either
      // we're still loading or every tier-milestone is done.
      if (nextMilestone == null) return '';
      if (_selectedMilestoneType == 'Day' && remaining.inHours < 1) {
        return 'Completed in: ${remaining.inMinutes} minutes';
      } else if (remaining.inHours < 24) {
        return 'Completed in: ${remaining.inHours} hours';
      } else {
        return 'Completed in: ${remaining.inDays} days';
      }
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FramedSection(
          title: 'Smoke-Free for',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimeUnit(days.toString().padLeft(2, '0'), 'DAYS', isDark),
                  _buildTimeUnit(hours.toString().padLeft(2, '0'), 'HOURS', isDark),
                  _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'MIN', isDark),
                  _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'SEC', isDark),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  now,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        FramedSection(
          title: 'Milestones',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            isDark ? AppThemes.darkCardColor : Colors.white,
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: isDark
                              ? AppThemes.darkCardColor
                              : Colors.white,
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedMilestoneType,
                          underline: const SizedBox(),
                          dropdownColor: isDark
                              ? AppThemes.darkCardColor
                              : Colors.white,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: isDark
                                ? AppThemes.darkIconColor
                                : AppThemes.lightIconColor,
                          ),
                          style: TextStyle(
                            color: isDark
                                ? AppThemes.darkTextColor
                                : AppThemes.lightTextColor,
                          ),
                          items: ['Day', 'Week', 'Month', 'Year']
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppThemes.darkTextColor
                                          : AppThemes.lightTextColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMilestoneType = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      milestoneLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AnimatedProgressBar(
                  targetProgress: progress,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppThemes.darkSubtitleColor
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    remainingText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppThemes.darkSubtitleColor
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: HomeButton(
            text: 'See all milestones',
            iconPath: 'assets/icons/milestone.png',
            onPressed: () {
              if (userState.userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please sign in to view milestones',
                      style: TextStyle(
                        color:
                            isDark ? AppThemes.darkTextColor : Colors.white,
                      ),
                    ),
                    backgroundColor: isDark
                        ? AppThemes.darkDeleteButtonColor
                        : AppThemes.lightDeleteButtonColor,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MilestonePage(
                    startDate: userState.quitDate.toLocal(),
                    userId: userState.userId,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/models/milestone_state.dart';
import 'package:smoking/pages/utils/back_app_bar.dart';
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:smoking/providers/milestone_provider.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/user_provider.dart';

class MilestonePage extends ConsumerStatefulWidget {
  final DateTime startDate;
  final String userId;

  const MilestonePage({
    super.key,
    required this.startDate,
    required this.userId,
  });

  @override
  ConsumerState<MilestonePage> createState() => _MilestonePageState();
}

class _MilestonePageState extends ConsumerState<MilestonePage> {
  @override
  void initState() {
    super.initState();
    // One-shot init after first frame. Doing this inside `build()` previously
    // queued an init for every rebuild, which on slow networks looped.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final milestoneState = ref.read(milestoneProvider);
      final user = ref.read(userProvider);
      final notifier = ref.read(milestoneProvider.notifier);
      if (milestoneState.userId.isEmpty) {
        await notifier.initialize(user.quitDate, widget.userId);
      } else if (milestoneState.startDate != user.quitDate) {
        await notifier.reinitializeWithNewStartDate(user.quitDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Subsequent quit-date changes (e.g. user edited it from Account page)
    // trigger a one-shot re-initialise instead of looping inside build().
    ref.listen<DateTime>(userProvider.select((u) => u.quitDate),
        (prev, next) {
      if (prev == null || prev == next) return;
      ref.read(milestoneProvider.notifier).reinitializeWithNewStartDate(next);
    });

    final milestoneState = ref.watch(milestoneProvider);
    final milestoneNotifier = ref.read(milestoneProvider.notifier);
    final isDark = ref.isDark;

    final days = milestoneState.daysMilestones;
    final weeks = milestoneState.weeksMilestones;
    final months = milestoneState.monthsMilestones;
    final years = milestoneState.yearsMilestones;

    return Scaffold(
      appBar: const BackAppBar(title: 'Milestones', elevation: 4),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient:
                isDark
                    ? AppThemes.darkMilestoneGradient
                    : AppThemes.lightMilestoneGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (milestoneState.isLoading)
                  LinearProgressIndicator(
                    color:
                        isDark
                            ? AppThemes.darkTitleColor
                            : AppThemes.lightTitleColor,
                  ),
                if (milestoneState.hasError)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      milestoneState.errorMessage ?? 'Error loading milestones',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: milestoneNotifier.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _buildCategorySection(
                          context,
                          "Days",
                          days,
                          Icons.calendar_today,
                          milestoneNotifier,
                          isDark,
                        ),
                        _buildCategorySection(
                          context,
                          "Weeks",
                          weeks,
                          Icons.date_range,
                          milestoneNotifier,
                          isDark,
                        ),
                        _buildCategorySection(
                          context,
                          "Months",
                          months,
                          Icons.calendar_month,
                          milestoneNotifier,
                          isDark,
                        ),
                        _buildCategorySection(
                          context,
                          "Years",
                          years,
                          Icons.star,
                          milestoneNotifier,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<Milestone> milestones,
    IconData icon,
    MilestoneNotifier notifier,
    bool isDark,
  ) {
    // Celebratory banner when every milestone in this category is done — used
    // to be silently absent: the grid still rendered the completed tiles but
    // the user got no "you finished this whole tier" acknowledgement.
    final allDone =
        milestones.isNotEmpty && milestones.every((m) => m.completed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isDark
                        ? AppThemes.darkTitleColor
                        : AppThemes.lightTitleColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark
                          ? AppThemes.darkTitleColor
                          : AppThemes.lightTitleColor,
                ),
              ),
            ],
          ),
        ),
        if (allDone)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark
                      ? AppThemes.darkCompletedIcon
                      : AppThemes.lightCompletedIcon)
                  .withAlpha((0.15 * 255).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark
                        ? AppThemes.darkCompletedIcon
                        : AppThemes.lightCompletedIcon)
                    .withAlpha((0.5 * 255).round()),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: isDark
                      ? AppThemes.darkCompletedIcon
                      : AppThemes.lightCompletedIcon,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All $title milestones reached — congratulations!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppThemes.darkTextColor
                          : AppThemes.lightTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: milestones.length,
          itemBuilder: (context, index) {
            final milestone = milestones[index];
            final isCompleted = milestone.completed;
            final isEligible = milestone.isEligible;

            return GestureDetector(
              onTap:
                  () => _showMilestoneDialog(
                    context,
                    milestone,
                    notifier,
                    isDark,
                  ),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isCompleted
                          ? isDark
                              ? AppThemes.darkMilestoneCard
                              : AppThemes.lightMilestoneCard
                          : isEligible
                          ? isDark
                              ? AppThemes.darkEligibleCard
                              : AppThemes.lightEligibleCard
                          : isDark
                          ? AppThemes.darkIneligibleCard
                          : AppThemes.lightIneligibleCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              isCompleted
                                  ? isDark
                                      ? AppThemes.darkCompletedIcon
                                      : AppThemes.lightCompletedIcon
                                  : isEligible
                                  ? isDark
                                      ? AppThemes.darkEligibleIcon
                                      : AppThemes.lightEligibleIcon
                                  : Colors.grey,
                          child: Image.asset(
                            'assets/icons/milestone-check.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                        ),
                        if (isCompleted)
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        milestone.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isEligible
                                  ? isDark
                                      ? AppThemes.darkTextColor
                                      : AppThemes.lightTextColor
                                  : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, y').format(milestone.date),
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isDark
                                ? AppThemes.darkSubtitleColor
                                : AppThemes.lightSubtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showMilestoneDialog(
    BuildContext context,
    Milestone milestone,
    MilestoneNotifier notifier,
    bool isDark,
  ) {
    showGradientDialog<void>(
      context: context,
      gradient: isDark
          ? AppThemes.darkDialogGradient
          : AppThemes.lightDialogGradient,
      children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            milestone.completed
                                ? isDark
                                    ? AppThemes.darkCompletedIcon
                                    : AppThemes.lightCompletedIcon
                                : milestone.isEligible
                                ? isDark
                                    ? AppThemes.darkEligibleIcon
                                    : AppThemes.lightEligibleIcon
                                : Colors.grey,
                        child: Image.asset(
                          'assets/icons/milestone-check.png',
                          width: 36,
                          height: 36,
                          color: Colors.white,
                        ),
                      ),
                      if (milestone.completed)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    milestone.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppThemes.darkDialogTitleColor
                              : AppThemes.lightDialogTitleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestone.description,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          isDark
                              ? AppThemes.darkTextColor
                              : AppThemes.lightTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Target Date: ${DateFormat.yMMMMd().format(milestone.date)}",
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppThemes.darkSubtitleColor
                              : AppThemes.lightSubtitleColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!milestone.isEligible && !milestone.completed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "This milestone will be available on\n${DateFormat.yMMMMd().format(milestone.date)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            milestone.completed
                                ? Colors.grey
                                : milestone.isEligible
                                ? isDark
                                    ? AppThemes.darkDialogButtonColor
                                    : AppThemes.lightDialogButtonColor
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed:
                          !milestone.completed && milestone.isEligible
                              ? () async {
                                Navigator.pop(context);
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );
                                await notifier.toggleCompletion(milestone);
                              }
                              : null,
                      child: Text(
                        milestone.completed
                            ? "COMPLETED"
                            : milestone.isEligible
                            ? "MARK AS COMPLETED"
                            : "NOT AVAILABLE YET",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CLOSE",
                      style: TextStyle(
                        color:
                            isDark
                                ? AppThemes.darkCloseButtonColor
                                : AppThemes.lightCloseButtonColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
      ],
    );
  }
}

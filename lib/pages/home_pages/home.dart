import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:smoking/constants/health_benefits.dart';
import 'package:smoking/pages/home_pages/achievement_main.dart';
import 'package:smoking/pages/home_pages/biometrics.dart';
import 'package:smoking/pages/home_pages/diary.dart';
import 'package:smoking/pages/home_pages/explore_main.dart';
import 'package:smoking/pages/home_pages/health_benefits.dart';
import 'package:smoking/pages/home_pages/chatbot_page.dart';
import 'package:smoking/pages/home_pages/widgets/challenge_completion_listener.dart';
import 'package:smoking/pages/home_pages/widgets/daily_affirmation_section.dart';
import 'package:smoking/pages/home_pages/widgets/forum_message_section.dart';
import 'package:smoking/pages/home_pages/widgets/framed_section.dart';
import 'package:smoking/pages/home_pages/widgets/home_button.dart';
import 'package:smoking/pages/home_pages/widgets/ongoing_challenges_section.dart';
import 'package:smoking/pages/home_pages/widgets/progress_grid_section.dart';
import 'package:smoking/pages/home_pages/widgets/quit_timer_section.dart';
import 'package:smoking/pages/home_pages/widgets/social_section.dart';
import 'package:smoking/pages/settings_pages/settings.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/models/achievement_state.dart';
import 'package:smoking/providers/achievement_provider.dart';
import 'package:smoking/providers/healthbenefits_provider.dart';
import 'package:smoking/providers/milestone_provider.dart';
import 'package:smoking/providers/progress_provider.dart';
import 'package:smoking/providers/user_provider.dart';
import '../account_pages/account.dart';
import '../account_pages/widgets/avatar_display.dart';
import 'package:smoking/pages/home_pages/motivations.dart';
import 'package:smoking/models/challenge_state.dart';
import 'package:smoking/pages/utils/animated_progress_bar.dart';
import 'package:smoking/pages/utils/skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/mixins/scroll_controller_mixin.dart';
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.account});
  final Account account;

  @override
  ConsumerState<HomePage> createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage>
    with AutoDisposeScrollController {
  List<Challenge> allchallenges = [];
  bool _achievementsLoaded = false;
  bool _healthBenefitsLoaded = false;
  bool _bootStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootHomeData());
  }

  /// Run the one-time-per-session home boot: kick off the four critical loads
  /// in parallel, fire-and-forget the silent counter reconciliation, then
  /// flip the skeleton flags. Guarded by `_bootStarted` so the `ref.listen`
  /// retrigger in [build] can re-run it the moment userId arrives without
  /// double-loading if `initState` already had a userId.
  Future<void> _bootHomeData() async {
    if (!mounted || _bootStarted) return;
    final user = ref.read(userProvider);
    if (user.userId.isEmpty) return;
    _bootStarted = true;

    // Per-task try/catch instead of a single Future.wait error-boundary.
    // - "critical" tasks back tiles the user is staring at right now
    //   (timer, milestones, achievements, health benefits). A failure
    //   here gets the snackbar.
    // - `syncAllUserCounts` is a silent reconciliation — the cached
    //   counts on `userProvider` already render fine. A transient failure
    //   shouldn't paint a doomy "something failed" snackbar over an
    //   otherwise-successful boot.
    Future<bool> runCritical(Future<void> Function() task, String label) async {
      try {
        await task();
        return true;
      } catch (e) {
        debugPrint('Home boot: $label failed: $e');
        return false;
      }
    }

    final outcomes = await Future.wait([
      runCritical(
        () => ref.read(milestoneProvider.notifier).initializeFromUser(ref),
        'milestones',
      ),
      runCritical(
        () => ref.read(progressProvider.notifier).forceRecalculate(),
        'progress',
      ),
      runCritical(
        () => ref.read(healthBenefitsProvider.notifier).checkAchievements(),
        'health-benefits',
      ),
      runCritical(
        () => ref.read(achievementProvider.notifier).loadAchievements(),
        'achievements',
      ),
    ]);

    // Fire-and-forget the reconciliation; its failure isn't user-visible.
    unawaited(
      ref
          .read(userProvider.notifier)
          .syncAllUserCounts(user.userId)
          .catchError((e) =>
              debugPrint('Home boot: syncAllUserCounts failed: $e')),
    );

    if (outcomes.contains(false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some data failed to load. Pull to refresh.'),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _achievementsLoaded = true;
      _healthBenefitsLoaded = true;
    });
  }

  // Removed `_customButton` and `_framedSection`. The byte-equivalent
  // `HomeButton` and `FramedSection` widgets (in `widgets/`) read theme via
  // `ref.isDark` so unrelated user-doc mutations don't rebuild this page's
  // helpers — see the imports up top.





  Widget _buildLatestAchievements(BuildContext context) {
    if (!_achievementsLoaded) {
      // The skeleton stays visible until `_bootHomeData` flips the flag.
      // The previous in-build setState fallback was an infinite-rebuild trap
      // on the userId-empty early-return path — it forced `_loaded` true on
      // the next frame and revealed empty data instead of a real load.
      return FramedSection(
        title: "Latest Achievement",
        transparent: true,
        child: Transform.translate(
          offset: const Offset(0, -10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: 64,
                  height: 64,
                  borderRadius: 12,
                  isDark: ref.isDark,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: 140,
                        height: 16,
                        isDark: ref.isDark,
                      ),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        width: double.infinity,
                        height: 12,
                        isDark: ref.isDark,
                      ),
                      const SizedBox(height: 12),
                      SkeletonBox(
                        width: 100,
                        height: 12,
                        isDark: ref.isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final achievements = ref.watch(achievementProvider);
    final isDark = ref.isDark;

    // Copy before sorting — the `..sort` cascade was reordering the same
    // `List<AchievementState>` instance that lives inside the provider's
    // state, silently mutating other consumers' view of the list on every
    // home-page rebuild.
    AchievementState? latestAchievement;
    if (achievements.isNotEmpty) {
      final sorted = [...achievements]
        ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
      latestAchievement = sorted.first;
    }

    return FramedSection(
      title: "Latest Achievement",
      transparent: true,
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Column(
          children: [
            if (latestAchievement == null)
              Text(
                "No achievements unlocked yet.",
                style: TextStyle(
                  color:
                      isDark
                          ? AppThemes.darkTextColor
                          : AppThemes.lightTextColor,
                ),
              )
            else
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color:
                    isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Image.asset(
                          latestAchievement.level == 'gold'
                              ? 'assets/icons/gold_trophy.png'
                              : latestAchievement.level == 'silver'
                              ? 'assets/icons/silver_trophy.png'
                              : 'assets/icons/bronze_trophy.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestAchievement.title,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? AppThemes.darkTextColor
                                        : AppThemes.lightTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestAchievement.description,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color:
                                    isDark
                                        ? AppThemes.darkSubtitleColor
                                        : AppThemes.lightSubtitleColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color:
                                      isDark
                                          ? AppThemes.darkIconColor
                                          : AppThemes.lightIconColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(latestAchievement.achievedAt),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        isDark
                                            ? AppThemes.darkSubtitleColor
                                            : AppThemes.lightSubtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: HomeButton(
                text: "See all achievements",
                onPressed: () {
                  ref.read(userProvider.notifier).reloadUser();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AchievementPage(),
                    ),
                  );
                },
                iconPath: 'assets/icons/trophies.png',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthPreview() {
    if (!_healthBenefitsLoaded) {
      // Same rationale as `_buildLatestAchievements` — let `_bootHomeData`
      // own the flag flip; no in-build setState fallback.
      return FramedSection(
        title: "Health Benefits",
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                width: 24,
                height: 24,
                borderRadius: 6,
                isDark: ref.isDark,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                      width: 160,
                      height: 16,
                      isDark: ref.isDark,
                    ),
                    const SizedBox(height: 8),
                    SkeletonBox(
                      width: 80,
                      height: 12,
                      isDark: ref.isDark,
                    ),
                    const SizedBox(height: 8),
                    SkeletonBox(
                      width: double.infinity,
                      height: 8,
                      borderRadius: 4,
                      isDark: ref.isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final healthState = ref.watch(healthBenefitsProvider);
    final isDark = ref.isDark;

    final nextBenefit = HealthBenefits.allBenefits.firstWhere(
      (benefit) => !healthState.hasAchieved(benefit['id']),
      orElse: () => HealthBenefits.allBenefits.last,
    );

    final progress = healthState.calculateProgress(nextBenefit['id']);
    final totalMinutes = nextBenefit['time_interval'];
    final remainingMinutes = totalMinutes * (1 - progress);

    // Compute remaining time with the most appropriate unit
    String remainingTimeText;
    if (remainingMinutes >= 1440) {
      // More than one day
      final days = (remainingMinutes / 1440).ceil();
      remainingTimeText = "~$days ${days == 1 ? 'day' : 'days'} remaining";
    } else if (remainingMinutes >= 60) {
      // More than one hour
      final hours = (remainingMinutes / 60).ceil();
      remainingTimeText = "~$hours ${hours == 1 ? 'hour' : 'hours'} remaining";
    } else {
      // Less than one hour
      final minutes = remainingMinutes.ceil();
      remainingTimeText =
          "~$minutes ${minutes == 1 ? 'minute' : 'minutes'} remaining";
    }

    return Column(
      children: [
        FramedSection(
          title: "Health Benefits",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Image.asset(
                  nextBenefit['icon'],
                  width: 24,
                  height: 24,
                ),
                title: Text(
                  nextBenefit['title'],
                  style: TextStyle(
                    color:
                        isDark
                            ? AppThemes.darkTextColor
                            : AppThemes.lightTextColor,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${(progress * 100).toStringAsFixed(0)}% complete",
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppThemes.darkSubtitleColor
                                : AppThemes.lightSubtitleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedProgressBar(targetProgress: progress),
                    if (progress < 1.0)
                      Text(
                        remainingTimeText,
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isDark
                                  ? AppThemes.darkSubtitleColor
                                  : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: HomeButton(
            text: "See all health benefits",
            onPressed: () {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HealthBenefitsPage(),
                ),
              );
            },
            iconPath: 'assets/icons/health.png',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;
    final userState = ref.watch(userProvider);
    // If `initState` ran before the userId was set (e.g. cold start with a
    // session still resolving), `_bootHomeData` will have bailed. Re-fire it
    // the moment userId becomes non-empty. `_bootStarted` makes the call
    // idempotent so this doesn't double-load when `initState` already had a
    // userId.
    ref.listen<String>(userProvider.select((u) => u.userId), (prev, next) {
      if (next.isNotEmpty) _bootHomeData();
    });
    // Note: we deliberately do NOT call `ref.watch(progressProvider)` here.
    // The 1 Hz timer ticks would otherwise rebuild the entire HomePage subtree
    // every second. The timer/milestone block watches progress inside a
    // `Consumer` (see `_buildTimer`) and the ongoing-challenges card narrows
    // to `moneySaved` via `.select`. The challenge-completion listener above
    // uses `ref.listen`, which fires callbacks without subscribing this widget
    // to rebuilds.

    if (userState.isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color:
                  isDark
                      ? AppThemes.activeColor
                      : AppThemes.lightCloseButtonColor,
            ),
          ),
        ),
      );
    }

    if (userState.hasError) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error loading user data',
            style: TextStyle(
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            ),
          ),
        ),
      );
    }

    return ChallengeCompletionListener(
      child: Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          // Routes through the shared `AvatarDisplay` (stateful, caches the
          // `File.existsSync()` per path-value — see #319 / #344). The
          // appbar's previous hand-rolled branch did the IO check on every
          // build, which the user-state mutations made frequent.
          child: AvatarDisplay(
            avatarPath: userState.avatarPath,
            radius: 16,
            fallback: Icon(
              Icons.person,
              color: isDark ? AppThemes.darkTextColor : Colors.black,
            ),
            onTap: () {
              // Re-read latest state at tap time so a stale build-time
              // snapshot can't push the account page with empty/loading
              // user data.
              final current = ref.read(userProvider);
              if (current.isLoading || current.userId.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AccountPage(account: widget.account),
                ),
              );
            },
          ),
        ),
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'X',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              TextSpan(
                text: '-hale',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppThemes.darkTextColor : Colors.black,
                ),
              ),
            ],
          ),
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        actions: [
          IconButton(
            tooltip: 'Diary',
            icon: Image.asset('assets/icons/diary.png', width: 20, height: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryPage(userId: userState.userId),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Motivations',
            icon: Image.asset('assets/icons/goals.png', width: 20, height: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MotivationsPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: Image.asset(
              'assets/icons/settings.png',
              width: 20,
              height: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppThemes.motivationGradient(isDark),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QuitTimerSection(),
              const ProgressGridSection(),
              const DailyAffirmationSection(),
              _buildHealthPreview(),
              _buildLatestAchievements(context),
              const OngoingChallengesSection(),
              const ForumMessageSection(),
              const SocialSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        // Labels stay hidden visually but the `label` field still publishes
        // each tab's name to screen readers — keeps the current minimalist
        // look without leaving the nav unannounced.
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          _NavIcon(asset: 'assets/icons/dashboard.png', label: 'Dashboard'),
          _NavIcon(asset: 'assets/icons/trophies.png', label: 'Achievements'),
          _NavIcon(asset: 'assets/icons/chatbot.png', label: 'Chatbot'),
          _NavIcon(asset: 'assets/icons/biometrics.png', label: 'Biometrics'),
          _NavIcon(asset: 'assets/icons/explore.png', label: 'Explore'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              break;
            case 1:
              ref.read(userProvider.notifier).reloadUser();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementPage(),
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatbotPage(userId: userState.userId),
                ),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BiometricsPage()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExplorePage()),
              );
              break;
          }
        },
      ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return "${date.day}/${date.month}/${date.year}";
}

/// `BottomNavigationBarItem` subclass that bakes in our icon shape (asset
/// image with consistent top padding) and a non-empty semantic [label].
/// Labels are hidden visually by `BottomNavigationBar.showSelectedLabels:
/// false` but still reach the accessibility tree.
class _NavIcon extends BottomNavigationBarItem {
  _NavIcon({required String asset, required String label})
      : super(
          icon: Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Center(
              child: Image.asset(asset, height: 24, width: 24),
            ),
          ),
          activeIcon: Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Center(
              child: Image.asset(asset, height: 24, width: 24),
            ),
          ),
          label: label,
        );
}


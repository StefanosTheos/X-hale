import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/constants/achievements.dart';
import 'package:smoking/constants/limits.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/animated_progress_bar.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/achievement_provider.dart';
import 'package:smoking/providers/user_provider.dart';

/// One-time bucketing of the constant `allAchievements` catalogue by
/// category. Lifted to file scope so it isn't rebuilt on every `build` of
/// `AchievementPage` — the input is `const` and the result never changes
/// during a session.
final Map<String, List<Achievement>> _groupedAchievements = (() {
  final m = <String, List<Achievement>>{};
  for (final a in allAchievements) {
    m.putIfAbsent(a.category, () => []).add(a);
  }
  return m;
})();

/// Snapshot of just the user counters that map to achievement categories.
/// Used to `.select` against `userProvider` so unrelated edits (avatar,
/// theme, name, settings) don't rebuild the achievements page.
typedef AchievementCounts = ({
  int diaryCount,
  int numMilestonesCompleted,
  int numForumPosts,
  int numChatMessages,
  int numFriends,
  int snakeHighScore,
  int flappyHighScore,
  int high2048Score,
  int totalWheelSpins,
  int physicalCount,
  int financialCount,
  int numHealthBenefit,
});

class AchievementPage extends ConsumerWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementProvider);
    final isDark = ref.isDark;
    final points = ref.watch(userProvider.select((u) => u.achievementPoints));
    // Watch only the 12 counters the progress bars read. A record equality
    // means Riverpod skips rebuilds when an unrelated user-doc field changes
    // — previously every theme flip / FCM-driven mutation / score increment
    // rebuilt the entire TabBar + 3-tab ListView, even when the changed
    // field had nothing to do with achievements.
    final counts = ref.watch(
      userProvider.select(
        (u) => (
          diaryCount: u.diaryCount,
          numMilestonesCompleted: u.numMilestonesCompleted,
          numForumPosts: u.numForumPosts,
          numChatMessages: u.numChatMessages,
          numFriends: u.numFriends,
          snakeHighScore: u.snakeHighScore,
          flappyHighScore: u.flappyHighScore,
          high2048Score: u.high2048Score,
          totalWheelSpins: u.totalWheelSpins,
          physicalCount: u.physicalCount,
          financialCount: u.financialCount,
          numHealthBenefit: u.numHealthBenefit,
        ),
      ),
    );
    final notifier = ref.read(achievementProvider.notifier);

    // Render the full catalogue immediately — all locked until the background
    // evaluation finishes. `completedIds` will be empty on first frame for new
    // users; when `evaluateAchievements` resolves and pushes new state into
    // `achievementProvider`, this widget rebuilds and the relevant cards flip
    // to the unlocked tint.
    final completedIds = achievements.map((a) => a.id).toSet();

    return DefaultTabController(
      length: _groupedAchievements.keys.length,
      child: Scaffold(
        backgroundColor:
            isDark
                ? AppThemes.darkBackgroundColor
                : AppThemes.lightBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 6,
          title: Text(
            'Achievements',
            style: TextStyle(
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor:
              isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor:
                isDark
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : AppThemes.primaryBlue,
            labelColor:
                isDark
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : AppThemes.primaryBlue,
            unselectedLabelColor:
                isDark
                    ? AppThemes.darkSubtitleColor
                    : AppThemes.lightSubtitleColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs:
                _groupedAchievements.keys.map((c) {
                  String tabText = c;
                  if (c == 'SnakeGame') tabText = 'Snake';
                  if (c == 'FlappyBirdGame') tabText = 'Flappy Bird';
                  if (c == '2048Game') tabText = '2048';
                  return Tab(text: tabText);
                }).toList(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient:
                isDark
                    ? AppThemes.darkCardGradient
                    : AppThemes.lightCardGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildPointsCard(points, isDark),
                Expanded(
                  child: TabBarView(
                    children:
                        _groupedAchievements.entries.map((entry) {
                          final category = entry.key;
                          final categoryAchievements = entry.value;

                          final bronze =
                              categoryAchievements
                                  .where((a) => a.level == 'bronze')
                                  .toList();
                          final silver =
                              categoryAchievements
                                  .where((a) => a.level == 'silver')
                                  .toList();
                          final gold =
                              categoryAchievements
                                  .where((a) => a.level == 'gold')
                                  .toList();

                          return RefreshIndicator(
                            onRefresh: notifier.loadAchievements,
                            child: ListView(
                              // Preserves scroll position when the user
                              // hops between category tabs — without a stable
                              // key, `TabBarView` reuses the same scrollable
                              // element across tabs and Flutter resets the
                              // offset to 0 on every switch.
                              key: PageStorageKey<String>('ach-$category'),
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              children: [
                                if (bronze.isNotEmpty)
                                  _buildLevelSection(
                                    context,
                                    bronze,
                                    completedIds,
                                    counts,
                                    'Bronze',
                                    isDark,
                                  ),
                                if (silver.isNotEmpty)
                                  _buildLevelSection(
                                    context,
                                    silver,
                                    completedIds,
                                    counts,
                                    'Silver',
                                    isDark,
                                  ),
                                if (gold.isNotEmpty)
                                  _buildLevelSection(
                                    context,
                                    gold,
                                    completedIds,
                                    counts,
                                    'Gold',
                                    isDark,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard(int points, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppThemes.darkDialogTitleColor
                  : AppThemes.lightAppBarColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black26,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient:
            isDark ? AppThemes.darkCardGradient : AppThemes.lightCardGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Achievement Points',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedProgressBar(
            targetProgress: points / kMaxAchievementPoints,
          ),
          const SizedBox(height: 10),
          Text(
            '$points / $kMaxAchievementPoints',
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark
                      ? AppThemes.darkSubtitleColor
                      : AppThemes.lightSubtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(
    BuildContext context,
    List<Achievement> achievements,
    Set<String> completedIds,
    AchievementCounts counts,
    String level,
    bool isDark,
  ) {
    final levelColor = _getLevelColor(level, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: levelColor.withAlpha(51),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: levelColor.withAlpha(128), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: levelColor, size: 20),
              const SizedBox(width: 8),
              Text(
                level,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
            ],
          ),
        ),
        ...achievements.map((a) {
          final isCompleted = completedIds.contains(a.id);
          final current = _getUserProgress(counts, a);
          final displayedCurrent = isCompleted ? a.goal : current;
          final progressPercentage =
              isCompleted ? 1.0 : (current / a.goal).clamp(0.0, 1.0);
          final displayedPercentage =
              isCompleted
                  ? 100
                  : ((current / a.goal) * 100).clamp(0, 100).toInt();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              color:
                  isCompleted
                      ? levelColor.withAlpha(26)
                      : isDark
                      ? AppThemes.darkCardColor
                      : AppThemes.lightCardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color:
                      isCompleted
                          ? levelColor.withAlpha(128)
                          : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color:
                              isCompleted
                                  ? levelColor
                                  : (isDark
                                      ? AppThemes.darkIconColor
                                      : AppThemes.lightIconColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? AppThemes.darkTextColor
                                      : AppThemes.lightTextColor,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: levelColor.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                color: levelColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.description,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark
                                ? AppThemes.darkSubtitleColor
                                : AppThemes.lightSubtitleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: progressPercentage,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(10),
                          color: levelColor,
                          backgroundColor:
                              isDark ? Colors.grey[800] : Colors.grey[300],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$displayedCurrent / ${a.goal}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark
                                        ? AppThemes.darkSubtitleColor
                                        : AppThemes.lightSubtitleColor,
                              ),
                            ),
                            Text(
                              '$displayedPercentage%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: levelColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getLevelColor(String level, bool isDark) {
    switch (level.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32); // Bronze color
      case 'silver':
        return const Color.fromARGB(255, 146, 146, 146); // Silver color
      case 'gold':
        return const Color(0xFFFFD700); // Gold color
      default:
        return isDark ? AppThemes.darkIconColor : AppThemes.lightIconColor;
    }
  }

  int _getUserProgress(AchievementCounts c, Achievement a) {
    switch (a.category) {
      case 'Diary':
        return c.diaryCount;
      case 'Milestones':
        return c.numMilestonesCompleted;
      case 'Community':
        return c.numForumPosts;
      case 'Support':
        return c.numChatMessages;
      case 'Social':
        return c.numFriends;
      case 'SnakeGame':
        return c.snakeHighScore;
      case 'FlappyBirdGame':
        return c.flappyHighScore;
      case '2048Game':
        return c.high2048Score;
      case 'Engagement':
        return c.totalWheelSpins;
      case 'Physical':
        return c.physicalCount;
      case 'Financial':
        return c.financialCount;
      case 'Health':
        return c.numHealthBenefit;
      default:
        return 0;
    }
  }
}

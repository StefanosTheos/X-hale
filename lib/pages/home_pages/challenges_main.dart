import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/models/challenge_state.dart';
import 'package:smoking/pages/home_pages/create_challenge.dart';
import 'package:smoking/pages/home_pages/edit_challenge.dart';
import 'package:smoking/providers/challenge_provider.dart';
import 'package:smoking/providers/progress_provider.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:smoking/pages/utils/themes.dart';

class ChallengesPage extends ConsumerStatefulWidget {
  const ChallengesPage({super.key});

  @override
  ConsumerState<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends ConsumerState<ChallengesPage> {
  // Filter state lifted to `challengesFilterProvider` so it survives push/pop
  // navigation. Local field used to reset to 'Ongoing' on every return.

  void _changeFilter(String filter) {
    ref.read(challengesFilterProvider.notifier).state = filter;
  }

  void _goToCreateChallenge() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateChallengePage()),
    );

    if (created == true) ref.invalidate(challengeProvider);
  }

  Widget _buildFilterButtons(bool isDark) {
    final selectedFilter = ref.watch(challengesFilterProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          ['Ongoing', 'Completed', 'Forfeited'].map((filter) {
            final isSelected = selectedFilter == filter;
            return ElevatedButton(
              onPressed: () => _changeFilter(filter),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSelected
                        ? (isDark
                            ? AppThemes.activeColor
                            : AppThemes.lightAppBarColor)
                        : AppThemes.elevatedButtonBackground(isDark),
                foregroundColor:
                    isSelected
                        ? Colors.white
                        : (isDark
                            ? AppThemes.darkTextColor
                            : AppThemes.lightTextColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(filter),
            );
          }).toList(),
    );
  }

  Widget _buildChallengeCard(
    Challenge challenge,
    ThemeColors colors,
    double moneySaved,
    String currency,
  ) {
    final isDark = colors.isDark;
    final isFinancial = challenge.isFinancial;
    final isActive = challenge.isActive;
    final isCompleted = challenge.isCompleted;
    final isForfeited = challenge.isForfeited;

    Future<void> showCompleteConfirmationDialog() async {
      final confirmed = await showGradientDialog<bool>(
        context: context,
        gradient: isDark
            ? AppThemes.darkDialogGradient
            : AppThemes.lightDialogGradient,
        children: [
          const SizedBox(height: 12),
          Text(
            'Confirm Completion',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Are you sure you want to complete this challenge?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppThemes.elevatedButtonBackground(isDark),
                  foregroundColor: isDark
                      ? AppThemes.darkTextColor
                      : AppThemes.lightTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppThemes.darkCloseButtonColor
                      : AppThemes.lightCloseButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Complete'),
              ),
            ],
          ),
        ],
      );
      if (confirmed == true) {
        await ref
            .read(challengeProvider.notifier)
            .updateChallengeStatus(challenge.id, 'completed');
      }
    }

    Future<void> showForfeitConfirmationDialog() async {
      final confirmed = await showGradientDialog<bool>(
        context: context,
        gradient: isDark
            ? AppThemes.darkDeleteDialogGradient
            : AppThemes.lightDeleteDialogGradient,
        children: [
          const SizedBox(height: 12),
          Text(
            'Confirm Forfeit',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Are you sure you want to forfeit this challenge?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppThemes.darkTextColor : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppThemes.elevatedButtonBackground(isDark),
                  foregroundColor: isDark
                      ? AppThemes.darkTextColor
                      : AppThemes.lightTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppThemes.darkDeleteButtonColor
                      : AppThemes.lightDeleteButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ],
      );
      if (confirmed == true) {
        await ref
            .read(challengeProvider.notifier)
            .updateChallengeStatus(challenge.id, 'forfeited');
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      color: colors.card,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Image.asset(challenge.iconPath, width: 40, height: 40),
              title: Text(
                challenge.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    "Type: ${challenge.type}",
                    style: TextStyle(
                      color: colors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isFinancial) ...[
                    Text(
                      "Money collected: $currency${moneySaved.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: colors.subtitle,
                      ),
                    ),
                    Text(
                      "Goal budget: $currency${challenge.goalBudget?.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: colors.subtitle,
                      ),
                    ),
                  ] else ...[
                    Text(
                      "Last entry: ${challenge.lastEntry != null ? DateFormat('dd-MM-yyyy HH:mm:ss').format(challenge.lastEntry!.toLocal()) : 'N/A'}",
                      style: TextStyle(
                        color: colors.subtitle,
                      ),
                    ),
                  ],
                ],
              ),
              trailing:
                  isCompleted || isForfeited
                      ? Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          bottom: 12,
                          right: 8,
                        ),
                        child: Image.asset(
                          isCompleted
                              ? 'assets/icons/checkmark.png'
                              : 'assets/icons/x.png',
                          width: 46,
                          height: 46,
                        ),
                      )
                      : null,
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    iconSize: 24,
                    tooltip: 'Mark as Completed',
                    onPressed: showCompleteConfirmationDialog,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    iconSize: 24,
                    tooltip: 'Edit Challenge',
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditChallengePage(challenge: challenge),
                        ),
                      );
                      if (updated == true) {
                        final userId = ref.read(userProvider).userId;
                        await ref
                            .read(challengeProvider.notifier)
                            .fetchChallenges(userId);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    iconSize: 24,
                    tooltip: 'Forfeit Challenge',
                    onPressed: showForfeitConfirmationDialog,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Narrow each watch — the page used to do `ref.watch(challengeProvider)`
    // and recompute `_getFilteredChallenges(state)` per build, so every
    // progress tick / theme flip walked the full challenge list. Now the
    // filtering lives in `filteredChallengesProvider` (memoized on both
    // `state.challenges` and the filter) and isLoading is `.select`ed.
    final isLoading =
        ref.watch(challengeProvider.select((s) => s.isLoading));
    final filtered = ref.watch(filteredChallengesProvider);
    final moneySaved =
        ref.watch(progressProvider.select((s) => s.moneySaved));
    final currency =
        ref.watch(userProvider.select((u) => u.selectedCurrency));
    final colors = ref.themeColors;
    final isDark = colors.isDark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        title: Text(
          "Challenges",
          style: TextStyle(
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient:
                      isDark ? AppThemes.darkGradient : AppThemes.lightGradient,
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                _buildFilterButtons(isDark),
                const SizedBox(height: 12),
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: isDark
                                ? AppThemes.darkIconColor
                                : AppThemes.lightIconColor,
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildChallengeCard(
                              filtered[index],
                              colors,
                              moneySaved,
                              currency,
                            );
                          },
                        ),
                ),
                const SizedBox(height: 60),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: FloatingActionButton.extended(
                  onPressed: _goToCreateChallenge,
                  backgroundColor:
                      isDark
                          ? AppThemes.darkCloseButtonColor
                          : AppThemes.lightCloseButtonColor,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Create New Challenge",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/constants/health_benefits.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/models/healthbenefits_state.dart';
import 'package:smoking/pages/home_pages/chatbot_page.dart';
import 'package:smoking/pages/utils/animated_progress_bar.dart';
import 'package:smoking/pages/utils/back_app_bar.dart';
import 'package:smoking/providers/healthbenefits_provider.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/themes.dart';

// Severity partitions of `HealthBenefits.allBenefits` — precomputed once at
// file scope so each `build` doesn't re-walk the 14-entry catalogue three
// times. The catalogue itself is `const`, so these are deterministic and
// safe to compute eagerly.
final List<Map<String, dynamic>> _lowSeverityBenefits =
    HealthBenefits.allBenefits.where((b) => b['severity'] == 'low').toList();
final List<Map<String, dynamic>> _mediumSeverityBenefits =
    HealthBenefits.allBenefits.where((b) => b['severity'] == 'medium').toList();
final List<Map<String, dynamic>> _highSeverityBenefits =
    HealthBenefits.allBenefits.where((b) => b['severity'] == 'high').toList();

class HealthBenefitsPage extends ConsumerStatefulWidget {
  const HealthBenefitsPage({super.key});

  @override
  ConsumerState<HealthBenefitsPage> createState() => _HealthBenefitsPageState();
}

class _HealthBenefitsPageState extends ConsumerState<HealthBenefitsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(healthBenefitsProvider.notifier).checkAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthBenefitsProvider);
    final isDark = ref.isDark;
    final sortedBenefits = _getSortedBenefitsByCompletion(state);

    return Scaffold(
      appBar: const BackAppBar(title: 'Health Benefits', elevation: 4),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppThemes.darkGradient : AppThemes.lightGradient,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeveritySection(
                  context,
                  isDark: isDark,
                  title: 'Low Impact Benefits',
                  benefits: sortedBenefits['low']!,
                  color: const Color.fromARGB(255, 19, 147, 85),
                ),
                const SizedBox(height: 24),
                _buildSeveritySection(
                  context,
                  isDark: isDark,
                  title: 'Medium Impact Benefits',
                  benefits: sortedBenefits['medium']!,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 24),
                _buildSeveritySection(
                  context,
                  isDark: isDark,
                  title: 'High Impact Benefits',
                  benefits: sortedBenefits['high']!,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _getSortedBenefitsByCompletion(
    HealthBenefitsState state,
  ) {
    return {
      'low': _sortBenefits(_lowSeverityBenefits, state),
      'medium': _sortBenefits(_mediumSeverityBenefits, state),
      'high': _sortBenefits(_highSeverityBenefits, state),
    };
  }

  List<Map<String, dynamic>> _sortBenefits(
    List<Map<String, dynamic>> benefits,
    HealthBenefitsState state,
  ) {
    final completed =
        benefits.where((b) => state.hasAchieved(b['id'])).toList();
    final pending = benefits.where((b) => !state.hasAchieved(b['id'])).toList();

    pending.sort((a, b) {
      final dateA = state.completionDateFor(a['id']);
      final dateB = state.completionDateFor(b['id']);
      return dateA.compareTo(dateB);
    });

    return [...completed, ...pending];
  }

  Widget _buildSeveritySection(
    BuildContext context, {
    required bool isDark,
    required String title,
    required List<Map<String, dynamic>> benefits,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.withAlpha((0.8 * 255).round()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...benefits.map(
          (benefit) => _buildBenefitCard(context, benefit, isDark),
        ),
      ],
    );
  }

  Widget _buildBenefitCard(
    BuildContext context,
    Map<String, dynamic> benefit,
    bool isDark,
  ) {
    final state = ref.watch(healthBenefitsProvider);
    final progress = state.calculateProgress(benefit['id']);
    final isAchieved = state.hasAchieved(benefit['id']);
    final completionDate = state.completionDateFor(benefit['id']);

    return Card(
      // Keyed by benefit id so the animated progress bar and any per-card
      // ephemeral state stay attached to the same benefit when the list
      // reorders (e.g. a benefit being marked achieved).
      key: ValueKey('benefit-${benefit['id']}'),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      elevation: 0,
      color: isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(benefit['icon'], width: 24, height: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit['title'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? AppThemes.darkTextColor
                              : AppThemes.lightTextColor,
                    ),
                  ),
                ),
                _buildSeverityChip(benefit['severity']),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              benefit['description'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    isDark
                        ? AppThemes.darkSubtitleColor
                        : AppThemes.lightSubtitleColor,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedProgressBar(targetProgress: progress),
            const SizedBox(height: 8),
            Builder(
              builder: (_) {
                final metadata = HealthBenefits.getById(benefit['id']);
                if (metadata == null) return const SizedBox.shrink();

                final int minutes = metadata['time_interval'] ?? 0;
                final Duration targetDuration = Duration(minutes: minutes);

                String pluralize(int count, String singular, String plural) {
                  return '$count ${count == 1 ? singular : plural}';
                }

                String readableDuration;
                if (targetDuration.inDays >= 365 * 2) {
                  final years = (targetDuration.inDays / 365).round();
                  readableDuration = pluralize(years, 'year', 'years');
                } else if (targetDuration.inDays >= 365) {
                  readableDuration = '1 year';
                } else if (targetDuration.inDays >= 30) {
                  final months = (targetDuration.inDays / 30).round();
                  readableDuration = pluralize(months, 'month', 'months');
                } else if (targetDuration.inDays >= 7) {
                  final weeks = (targetDuration.inDays / 7).round();
                  readableDuration = pluralize(weeks, 'week', 'weeks');
                } else if (targetDuration.inDays >= 1) {
                  readableDuration = pluralize(
                    targetDuration.inDays,
                    'day',
                    'days',
                  );
                } else if (targetDuration.inHours >= 1) {
                  readableDuration = pluralize(
                    targetDuration.inHours,
                    'hour',
                    'hours',
                  );
                } else {
                  readableDuration = pluralize(
                    targetDuration.inMinutes,
                    'minute',
                    'minutes',
                  );
                }

                return Text(
                  isAchieved
                      ? 'Completed in $readableDuration'
                      : 'Requires $readableDuration',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (!isAchieved) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () async {
                        final prompt =
                            'I have read about the benefit "${benefit['title']}": '
                            '"${benefit['description']}". Can you explain more deeply '
                            'how this happens after quitting smoking?';
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatbotPage(
                                  userId: ref.read(userProvider).userId,
                                  initialPrompt: prompt,
                                ),
                          ),
                        );
                      },
                      child: Text(
                        'Learn More',
                        style: TextStyle(
                          color:
                              isDark
                                  ? AppThemes.darkCloseButtonColor
                                  : AppThemes.lightCloseButtonColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Target: ${DateFormat('MMM dd, yyyy').format(completionDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achieved on ${DateFormat('MMM dd, yyyy').format(completionDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final prompt =
                          'I have read about the benefit "${benefit['title']}": '
                          '"${benefit['description']}". Can you explain more deeply '
                          'how this happens after quitting smoking?';
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatbotPage(
                                userId: ref.read(userProvider).userId,
                                initialPrompt: prompt,
                              ),
                        ),
                      );
                    },
                    child: Text(
                      'Learn More',
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityChip(String severity) {
    final color = _getColorForSeverity(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColorForSeverity(String severity) {
    switch (severity) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return const Color.fromARGB(255, 19, 147, 85);
      default:
        return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/constants/limits.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/mixins/scroll_controller_mixin.dart';
import 'package:smoking/models/diary_state.dart';
import 'package:smoking/providers/diary_provider.dart';
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:smoking/pages/utils/empty_state.dart';
import 'package:smoking/pages/utils/load_more_footer.dart';
import 'package:smoking/pages/utils/themes.dart';

class DiaryPage extends ConsumerStatefulWidget {
  final String userId;

  const DiaryPage({super.key, required this.userId});

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage>
    with AutoDisposeScrollController {
  final TextEditingController _textController = TextEditingController();
  final List<String> _availableTags = [
    'health',
    'family',
    'progress',
    'work',
    'exercise',
    'challenge',
    'achievement',
    'stress',
    'relaxation',
    'social',
    'goals',
    'reflection',
  ];
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(diaryProvider.notifier).loadEntries());
    // Mirror the forum page's pagination trigger — fire `loadMore` when the
    // user scrolls within ~300 px of the bottom so the next page is ready
    // before they hit the end.
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;
      final pos = scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        ref.read(diaryProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _addEntry() async {
    final text = _textController.text.trim();
    final notifier = ref.read(diaryProvider.notifier);
    final state = ref.read(diaryProvider);

    if (state.wroteToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You've already written today's entry."),
        ),
      );
      return;
    }

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter some text')));
      return;
    }

    if (text.length > kDiaryMaxChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum $kDiaryMaxChars characters allowed'),
        ),
      );
      return;
    }

    try {
      await notifier.addEntry(
        text: text,
        mood: state.selectedMood,
        tags: state.selectedTags,
      );
      _textController.clear();
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add entry: ${e.toString()}')),
      );
    }
  }

  Color _getColor(String colorHex) {
    return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'excited':
        return Icons.celebration;
      case 'angry':
        return Icons.mood_bad;
      default:
        return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaryState = ref.watch(diaryProvider);
    final notifier = ref.read(diaryProvider.notifier);
    final isDark = ref.isDark;
    final wroteToday = diaryState.wroteToday;

    return Container(
      decoration: BoxDecoration(
        gradient:
            isDark ? AppThemes.darkDiaryGradient : AppThemes.lightDiaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Diary',
            style: TextStyle(
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor:
              isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
          elevation: 4,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
          ),
          iconTheme: IconThemeData(
            color: isDark ? AppThemes.darkIconColor : AppThemes.lightIconColor,
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: () => notifier.loadEntries(force: true),
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: scrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                        color:
                            isDark
                                ? AppThemes.darkDiaryCardColor
                                : AppThemes.lightDiaryCardColor,
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (wroteToday)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isDark
                                            ? AppThemes.darkAppBarColor
                                            : AppThemes.lightAppBarColor)
                                        .withAlpha((0.2 * 255).round()),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: (isDark
                                              ? AppThemes.darkAppBarColor
                                              : AppThemes.lightAppBarColor)
                                          .withAlpha((0.5 * 255).round()),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 20,
                                        color:
                                            isDark
                                                ? AppThemes.darkDiaryTextColor
                                                : AppThemes.lightDiaryTextColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "You've already written today — come back tomorrow.",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color:
                                                isDark
                                                    ? AppThemes
                                                        .darkDiaryTextColor
                                                    : AppThemes
                                                        .lightDiaryTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                'How are you feeling today?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDark
                                          ? AppThemes.darkDiaryTextColor
                                          : AppThemes.lightDiaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? AppThemes.darkCardColor
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (isDark
                                            ? AppThemes.darkIconColor
                                            : AppThemes.lightAppBarColor)
                                        .withAlpha((0.5 * 255).round()),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildMoodButton(
                                        notifier,
                                        'happy',
                                        Icons.sentiment_very_satisfied,
                                        isDark,
                                      ),
                                      _buildMoodButton(
                                        notifier,
                                        'neutral',
                                        Icons.sentiment_neutral,
                                        isDark,
                                      ),
                                      _buildMoodButton(
                                        notifier,
                                        'sad',
                                        Icons.sentiment_very_dissatisfied,
                                        isDark,
                                      ),
                                      _buildMoodButton(
                                        notifier,
                                        'excited',
                                        Icons.celebration,
                                        isDark,
                                      ),
                                      _buildMoodButton(
                                        notifier,
                                        'angry',
                                        Icons.mood_bad,
                                        isDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Select Tags:',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? AppThemes.darkDiaryTextColor
                                            : AppThemes.lightDiaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _availableTags.map((tag) {
                                      final isSelected = diaryState.selectedTags
                                          .contains(tag);
                                      return FilterChip(
                                        label: Text(tag),
                                        selected: isSelected,
                                        backgroundColor:
                                            isDark
                                                ? AppThemes.darkCardColor
                                                : Colors.white,
                                        selectedColor: (isDark
                                                ? AppThemes.darkSelectedTagColor
                                                : AppThemes
                                                    .lightSelectedTagColor)
                                            .withAlpha((0.2 * 255).round()),
                                        checkmarkColor:
                                            isDark
                                                ? AppThemes.darkDiaryTextColor
                                                : AppThemes.lightDiaryTextColor,
                                        labelStyle: TextStyle(
                                          color:
                                              isSelected
                                                  ? (isDark
                                                      ? AppThemes
                                                          .darkDiaryTextColor
                                                      : AppThemes
                                                          .lightDiaryTextColor)
                                                  : (isDark
                                                      ? AppThemes.darkTextColor
                                                      : AppThemes
                                                          .lightTextColor),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color:
                                                isSelected
                                                    ? (isDark
                                                        ? AppThemes
                                                            .darkTagBorderColor
                                                        : AppThemes
                                                            .lightTagBorderColor)
                                                    : Colors.grey.withAlpha(
                                                      (0.5 * 255).round(),
                                                    ),
                                          ),
                                        ),
                                        onSelected: (selected) {
                                          notifier.toggleTag(tag);
                                        },
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 16),
                              IntrinsicHeight(
                                child: Container(
                                  constraints: BoxConstraints(
                                    minHeight: 100,
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                        0.3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? AppThemes.darkCardColor
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SingleChildScrollView(
                                    child: TextField(
                                      controller: _textController,
                                      focusNode: _textFocusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Write your thoughts...',
                                        hintStyle: AppThemes.inputHintStyle(
                                          isDark,
                                        ),
                                        filled: true,
                                        fillColor:
                                            isDark
                                                ? AppThemes.darkCardColor
                                                : Colors.white,
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                      ),
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                      maxLines: null,
                                      maxLength: kDiaryMaxChars,
                                      keyboardType: TextInputType.multiline,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: wroteToday ? null : _addEntry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isDark
                                            ? AppThemes.darkAppBarColor
                                            : AppThemes.lightAppBarColor,
                                    foregroundColor:
                                        isDark
                                            ? AppThemes.darkTextColor
                                            : Colors.white,
                                    disabledBackgroundColor:
                                        (isDark
                                                ? AppThemes.darkAppBarColor
                                                : AppThemes.lightAppBarColor)
                                            .withAlpha((0.4 * 255).round()),
                                    disabledForegroundColor:
                                        (isDark
                                                ? AppThemes.darkTextColor
                                                : Colors.white)
                                            .withAlpha((0.7 * 255).round()),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Save Entry',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      diaryState.isLoading
                          ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color:
                                    isDark
                                        ? AppThemes.darkIconColor
                                        : AppThemes.lightAppBarColor,
                              ),
                            ),
                          )
                          : diaryState.entries.isEmpty
                          ? EmptyState(
                            icon: Icons.menu_book_outlined,
                            title: 'No diary entries yet',
                            subtitle:
                                'Start by writing how you feel today.',
                            isDark: isDark,
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            // +1 slot when paginating so a small spinner
                            // footer renders below the last entry; outer
                            // `SingleChildScrollView` drives `loadMore`.
                            itemCount: diaryState.entries.length +
                                (diaryState.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == diaryState.entries.length) {
                                return const LoadMoreFooter();
                              }
                              final entry = diaryState.entries[index];
                              return Dismissible(
                                key: Key(entry.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  final confirm = await showDeleteConfirmDialog(
                                    context: context,
                                    isDark: isDark,
                                    title: 'Delete Entry?',
                                    message:
                                        'Are you sure you want to delete this diary entry?',
                                  );

                                  if (confirm == true) {
                                    // Tactile signal for the destructive
                                    // action — fires after the user confirmed
                                    // the dialog, before the entry is wiped.
                                    // Matches the pattern in account.dart
                                    // (#18) and the open #330 on friends.
                                    HapticFeedback.mediumImpact();
                                    await ref
                                        .read(diaryProvider.notifier)
                                        .deleteEntry(entry.id);
                                    if (!context.mounted) return false;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Entry deleted"),
                                      ),
                                    );
                                  }
                                  return false;
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: _buildEntryCard(entry, isDark),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton(
    DiaryNotifier notifier,
    String mood,
    IconData icon,
    bool isDark,
  ) {
    final selectedMood = ref.watch(diaryProvider.select((s) => s.selectedMood));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color:
            selectedMood == mood
                ? _getColor(
                  notifier.getMoodColor(mood),
                ).withAlpha((0.2 * 255).round())
                : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 28),
        color:
            selectedMood == mood
                ? _getColor(notifier.getMoodColor(mood))
                : (isDark
                    ? AppThemes.darkDiaryTextColor
                    : AppThemes.lightDiaryTextColor),
        onPressed: () => notifier.updateSelectedMood(mood),
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntry entry, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color:
          isDark ? AppThemes.darkDiaryCardColor : AppThemes.lightDiaryCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, y - h:mm a').format(entry.date),
                  style: TextStyle(
                    color:
                        isDark
                            ? AppThemes.darkDiaryTextColor
                            : AppThemes.lightDiaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getColor(
                      entry.color,
                    ).withAlpha((0.2 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getMoodIcon(entry.mood),
                    color: _getColor(entry.color),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.text,
              style: TextStyle(
                fontSize: 15,
                color:
                    isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
              ),
            ),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    entry.tags
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark
                                        ? AppThemes.darkTextColor
                                        : AppThemes.lightTextColor,
                              ),
                            ),
                            backgroundColor:
                                isDark
                                    ? AppThemes.darkTagColor
                                    : AppThemes.lightTagColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color:
                                    isDark
                                        ? AppThemes.darkTagBorderColor
                                        : AppThemes.lightTagBorderColor,
                                width: 1,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


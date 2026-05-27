import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smoking/constants/limits.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/models/motivation_state.dart';
import 'package:smoking/pages/utils/back_app_bar.dart';
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:smoking/providers/motivation_provider.dart';
import 'package:smoking/pages/utils/themes.dart';

class MotivationsPage extends ConsumerStatefulWidget {
  const MotivationsPage({super.key});

  @override
  ConsumerState<MotivationsPage> createState() => _MotivationsPageState();
}

class _MotivationsPageState extends ConsumerState<MotivationsPage> {
  final TextEditingController _textController = TextEditingController();

  String selectedIcon = 'goal';
  String selectedColor = '#2196F3';

  final Map<String, String> colorNames = {
    '#F44336': 'Red',
    '#4CAF50': 'Green',
    '#2196F3': 'Blue',
    '#FF9800': 'Orange',
    '#9C27B0': 'Purple',
  };

  @override
  void initState() {
    super.initState();
    // No need to call loadMotivations here — the global provider's constructor
    // does it on first access (see motivation_provider.dart).
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Narrow to just the two fields the UI renders. Unrelated state edits
    // (theme flips, counters, other user-doc fields) no longer rebuild this
    // page; `ref.isDark` handles the theme branch through its own `.select`.
    final isLoading = ref.watch(
      motivationProvider.select((s) => s.isLoading),
    );
    final motivations = ref.watch(
      motivationProvider.select((s) => s.motivations),
    );
    final notifier = ref.read(motivationProvider.notifier);
    final isDark = ref.isDark;

    return Scaffold(
      appBar: const BackAppBar(title: 'My Motivations', elevation: 4),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient:
                isDark
                    ? AppThemes.darkMotivationGradient
                    : AppThemes.lightMotivationGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  color:
                      isDark
                          ? AppThemes.darkCardColor
                          : AppThemes.lightCardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                maxLength: kMotivationMaxChars,
                                decoration: InputDecoration(
                                  hintText: 'Add a new motivation...',
                                  hintStyle: AppThemes.inputHintStyle(isDark),
                                  border: InputBorder.none,
                                  // Hide Material's default counter — the
                                  // cap is enforced silently like the diary
                                  // input.
                                  counterText: '',
                                ),
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppThemes.darkTextColor
                                          : AppThemes.lightTextColor,
                                ),
                                maxLines: 2,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                size: 30,
                                color:
                                    isDark
                                        ? AppThemes.darkIconColor
                                        : AppThemes.lightAppBarColor,
                              ),
                              onPressed: () async {
                                final text = _textController.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Motivation cannot be empty.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final ok = await notifier.addMotivation(
                                  text,
                                  icon: selectedIcon,
                                  color: selectedColor,
                                );
                                if (!context.mounted) return;
                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to add motivation. Please try again.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _textController.clear();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? AppThemes.darkCardColor
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedIcon,
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color:
                                          isDark
                                              ? AppThemes.darkIconColor
                                              : AppThemes.lightIconColor,
                                    ),
                                    dropdownColor:
                                        isDark
                                            ? AppThemes.darkCardColor
                                            : AppThemes.lightCardColor,
                                    items:
                                        [
                                              'health',
                                              'family',
                                              'money',
                                              'sports',
                                              'goal',
                                            ]
                                            .map(
                                              (label) => DropdownMenuItem(
                                                value: label,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _getIcon(label),
                                                      color:
                                                          isDark
                                                              ? AppThemes
                                                                  .darkIconColor
                                                              : AppThemes
                                                                  .lightIconColor,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      label[0].toUpperCase() +
                                                          label.substring(1),
                                                      style: TextStyle(
                                                        color:
                                                            isDark
                                                                ? AppThemes
                                                                    .darkTextColor
                                                                : AppThemes
                                                                    .lightTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedIcon = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? AppThemes.darkCardColor
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedColor,
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color:
                                          isDark
                                              ? AppThemes.darkIconColor
                                              : AppThemes.lightIconColor,
                                    ),
                                    dropdownColor:
                                        isDark
                                            ? AppThemes.darkCardColor
                                            : AppThemes.lightCardColor,
                                    items:
                                        <String>[
                                          '#F44336', // Red
                                          '#4CAF50', // Green
                                          '#2196F3', // Blue
                                          '#FF9800', // Orange
                                          '#9C27B0', // Purple
                                        ].map((colorHex) {
                                          return DropdownMenuItem<String>(
                                            value: colorHex,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: _getColor(colorHex),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  colorNames[colorHex] ??
                                                      colorHex,
                                                  style: TextStyle(
                                                    color:
                                                        isDark
                                                            ? AppThemes
                                                                .darkTextColor
                                                            : AppThemes
                                                                .lightTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedColor = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color:
                                  isDark
                                      ? AppThemes.darkIconColor
                                      : AppThemes.lightAppBarColor,
                            ),
                          )
                          : motivations.isEmpty
                          ? Center(
                            child: Text(
                              'No motivations added yet\nAdd your reasons for quitting smoking',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    isDark
                                        ? AppThemes.darkTextColor
                                        : AppThemes.lightTextColor,
                              ),
                            ),
                          )
                          : Builder(
                            builder: (context) {
                              final pinned =
                                  motivations
                                      .where((m) => m.isPinned)
                                      .toList();
                              final unpinned =
                                  motivations
                                      .where((m) => !m.isPinned)
                                      .toList();
                              final ordered = [...pinned, ...unpinned];

                              return ListView.builder(
                                itemCount: ordered.length,
                                itemBuilder: (context, index) {
                                  return _buildMotivationCard(
                                    ordered[index],
                                    notifier,
                                    isDark,
                                  );
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationCard(
    MotivationState motivation,
    MotivationNotifier notifier,
    bool isDark,
  ) {
    return Dismissible(
      key: Key(motivation.id),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final ok = await showDeleteConfirmDialog(
          context: context,
          isDark: isDark,
          title: 'Delete Motivation?',
          message: 'Are you sure you want to delete this motivation?',
        );
        return ok ?? false;
      },
      onDismissed: (_) async {
        // Capture the messenger before the await so the lint sees the
        // post-await snackbar as guarded by the same context that produced it.
        final messenger = ScaffoldMessenger.of(context);
        final ok = await notifier.deleteMotivation(motivation.id);
        if (!ok) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Failed to delete motivation.')),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        color:
            motivation.isPinned
                ? isDark
                    ? AppThemes.darkPinnedCardColor
                    : AppThemes.lightPinnedCardColor
                : isDark
                ? AppThemes.darkCardColor
                : AppThemes.lightCardColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    _getIcon(motivation.icon),
                    color: _getColor(motivation.color),
                  ),
                  IconButton(
                    icon: Icon(
                      motivation.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color:
                          isDark
                              ? AppThemes.darkIconColor
                              : AppThemes.lightAppBarColor,
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await notifier.togglePin(
                        motivation.id,
                        motivation.isPinned,
                      );
                      if (!ok) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update pin.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                motivation.motivationText,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDark
                          ? AppThemes.darkTextColor
                          : AppThemes.lightTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Added on ${DateFormat('MMM d, y').format(motivation.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark
                          ? AppThemes.darkSubtitleColor
                          : AppThemes.lightSubtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'health':
        return Icons.favorite;
      case 'family':
        return Icons.family_restroom;
      case 'money':
        return Icons.attach_money;
      case 'sports':
        return Icons.sports_baseball;
      default:
        return Icons.flag;
    }
  }

  Color _getColor(String colorHex) {
    return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
  }
}

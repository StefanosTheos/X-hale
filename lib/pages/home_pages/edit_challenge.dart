import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/models/challenge_state.dart';
import 'package:smoking/providers/challenge_provider.dart';
import 'package:smoking/providers/progress_provider.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:smoking/pages/utils/input_decoration.dart';
import 'package:smoking/pages/utils/themes.dart';

class EditChallengePage extends ConsumerStatefulWidget {
  final Challenge challenge;

  const EditChallengePage({
    super.key,
    required this.challenge,
  });

  @override
  ConsumerState<EditChallengePage> createState() => _EditChallengePageState();
}

class _EditChallengePageState extends ConsumerState<EditChallengePage> {
  final _formKey = GlobalKey<FormState>();
  late Challenge challenge;
  final entryController = TextEditingController();
  final titleController = TextEditingController();
  final goalBudgetController = TextEditingController();
  final titleFocus = FocusNode();
  final budgetFocus = FocusNode();
  late String selectedIconPath;

  // Hand-managed error text for the goal-budget field. Same rationale as in
  // `create_challenge.dart` — Material's built-in errorText aligns with
  // `contentPadding.start` (16 px in from the box edge), but we want the
  // message flush with the box's outer left edge to line up with the
  // "Goal Budget (currency)" title above. Material's red error border
  // still fires via the validator below.
  String? _budgetError;

  final List<String> iconOptions = [
    'assets/icons/weight-lifting.png',
    'assets/icons/running.png',
    'assets/icons/piggy-bank.png',
    'assets/icons/book.png',
    'assets/icons/meditation.png',
    'assets/icons/mental-health.png',
    'assets/icons/healthy-food.png',
    'assets/icons/bike.png',
    'assets/icons/water.png',
  ];

  bool get _hasChanges {
    final title = titleController.text.trim();
    final goalBudget = goalBudgetController.text.trim();
    final newEntry = entryController.text.trim();

    return title != challenge.title ||
        goalBudget != (challenge.goalBudget?.toString() ?? '') ||
        selectedIconPath != widget.challenge.iconPath ||
        newEntry.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    challenge = widget.challenge;
    selectedIconPath = widget.challenge.iconPath;

    titleController.text = challenge.title;
    goalBudgetController.text = challenge.goalBudget?.toString() ?? '';
  }

  Listenable get _editListenable =>
      Listenable.merge([titleController, goalBudgetController, entryController]);

  @override
  void dispose() {
    titleController.dispose();
    goalBudgetController.dispose();
    titleFocus.dispose();
    budgetFocus.dispose();
    entryController.dispose();
    super.dispose();
  }

  String? _validateGoalBudget(
    String? value,
    double moneySaved,
    String currency,
  ) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < moneySaved) {
      return 'Goal budget cannot be less the than money saved '
          '($currency${moneySaved.toStringAsFixed(2)})';
    }
    return null;
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) return;
    // Mirror the form-level validator result into `_budgetError` so the
    // manually-rendered text shows up if the user submits with an invalid
    // budget. See `create_challenge.dart::_submitChallenge` for the same
    // pattern + rationale.
    if (challenge.isFinancial) {
      final moneySaved = ref.read(progressProvider).moneySaved;
      final currency = ref.read(userProvider).selectedCurrency;
      final err = _validateGoalBudget(
        goalBudgetController.text,
        moneySaved,
        currency,
      );
      setState(() => _budgetError = err);
      if (err != null) return;
    }

    final title = titleController.text.trim();
    final goalBudget = goalBudgetController.text.trim();
    final newEntry = entryController.text.trim();

    try {
      final updatedChallenge = challenge.copyWith(
        title: title,
        iconPath: selectedIconPath,
        goalBudget: challenge.isFinancial ? double.tryParse(goalBudget) : null,
        lastEntry:
            challenge.isPhysical && newEntry.isNotEmpty
                ? DateTime.now()
                : challenge.lastEntry,
      );

      if (challenge.isPhysical && newEntry.isNotEmpty) {
        await ref
            .read(challengeProvider.notifier)
            .addEntryToChallenge(challenge.userId, updatedChallenge, newEntry);
      }

      final success = await ref
          .read(challengeProvider.notifier)
          .updateChallenge(updatedChallenge);

      if (!mounted) return;
      if (!success) {
        // Provider catches internally and returns false instead of throwing,
        // so we surface the failure here rather than relying on the catch.
        await showAppErrorDialog(
          context,
          'Error Saving',
          'Failed to save your changes. Please try again.',
        );
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      // Actionable error (save failed → user may want to retry) — route
      // through the canonical error dialog instead of a bespoke AlertDialog.
      await showAppErrorDialog(
        context,
        'Error Saving',
        'An error occurred while saving changes:\n$e',
      );
    }
  }

  void _showEntriesDialog() {
    final entries = challenge.entries;
    final isDark = ref.isDark;

    if (entries.isEmpty) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text(
                "No entries",
                style: TextStyle(
                  color:
                      isDark
                          ? AppThemes.darkTextColor
                          : AppThemes.lightTextColor,
                ),
              ),
              backgroundColor:
                  isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
              content: Text(
                "There are no progress entries for this challenge.",
                style: TextStyle(
                  color:
                      isDark
                          ? AppThemes.darkTextColor
                          : AppThemes.lightTextColor,
                ),
              ),
            ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              "Progress Entries",
              style: TextStyle(
                color:
                    isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
              ),
            ),
            backgroundColor:
                isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    title: Text(
                      entry.message,
                      style: TextStyle(
                        color:
                            isDark
                                ? AppThemes.darkTextColor
                                : AppThemes.lightTextColor,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'dd-MM-yyyy HH:mm:ss',
                      ).format(entry.createdAt.toLocal()),
                      style: TextStyle(
                        color:
                            isDark
                                ? AppThemes.darkSubtitleColor
                                : AppThemes.lightSubtitleColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Close",
                  style: TextStyle(
                    color:
                        isDark
                            ? AppThemes.darkCloseButtonColor
                            : AppThemes.lightCloseButtonColor,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildIconOption(String icon, bool isDark) {
    final isSelected = icon == selectedIconPath;
    return GestureDetector(
      onTap: () => setState(() => selectedIconPath = icon),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected
                    ? (isDark
                        ? AppThemes.activeColor
                        : AppThemes.lightAppBarColor)
                    : (isDark ? Colors.grey.shade600 : Colors.grey),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
        ),
        padding: const EdgeInsets.all(4),
        child: Image.asset(icon, width: 40, height: 40),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText, bool isDark) =>
      themedInputDecoration(isDark: isDark, hint: hintText);

  @override
  Widget build(BuildContext context) {
    final moneySaved =
        ref.watch(progressProvider.select((s) => s.moneySaved));
    final currency =
        ref.watch(userProvider.select((u) => u.selectedCurrency));
    final isDark = ref.isDark;

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
          "Edit Challenge",
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient:
                      isDark ? AppThemes.darkGradient : AppThemes.lightGradient,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Challenge Title',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? AppThemes.darkTextColor
                                    : AppThemes.lightTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        focusNode: titleFocus,
                        decoration: _inputDecoration(
                          'Enter challenge title',
                          isDark,
                        ),
                        style: TextStyle(
                          color:
                              isDark
                                  ? AppThemes.darkTextColor
                                  : AppThemes.lightTextColor,
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Challenge Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? AppThemes.darkTextColor
                                    : AppThemes.lightTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? AppThemes.darkCardColor
                                  : AppThemes.lightCardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppThemes.inputBorderColor(isDark),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value:
                              challenge.type[0].toUpperCase() +
                              challenge.type.substring(1),
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor:
                              isDark
                                  ? AppThemes.darkCardColor
                                  : AppThemes.lightCardColor,
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppThemes.darkTextColor
                                    : AppThemes.lightTextColor,
                          ),
                          items:
                              ['Physical', 'Financial'].map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? AppThemes.darkTextColor
                                              : AppThemes.lightTextColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Icon:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? AppThemes.darkTextColor
                                    : AppThemes.lightTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1,
                        children:
                            iconOptions
                                .map((icon) => _buildIconOption(icon, isDark))
                                .toList(),
                      ),
                      const SizedBox(height: 16),
                      if (challenge.isFinancial) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Goal Budget ($currency)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? AppThemes.darkTextColor
                                      : AppThemes.lightTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: goalBudgetController,
                          focusNode: budgetFocus,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Enter goal amount',
                            isDark,
                          ).copyWith(
                            // Suppress Material's built-in error-text
                            // rendering (we draw it ourselves below so the
                            // leading edge can be flush with the box).
                            // Zero-height TextStyle means no vertical
                            // space is reserved for it.
                            errorStyle: const TextStyle(
                              fontSize: 0,
                              height: 0,
                            ),
                          ),
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppThemes.darkTextColor
                                    : AppThemes.lightTextColor,
                          ),
                          onChanged: (val) {
                            final err = _validateGoalBudget(
                              val,
                              moneySaved,
                              currency,
                            );
                            if (err != _budgetError) {
                              setState(() => _budgetError = err);
                            }
                          },
                          validator: (value) => _validateGoalBudget(
                            value,
                            moneySaved,
                            currency,
                          ),
                        ),
                        if (_budgetError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _budgetError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                      if (challenge.isPhysical) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'New Entry (max 100 chars)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? AppThemes.darkTextColor
                                      : AppThemes.lightTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: entryController,
                          maxLength: 100,
                          decoration: _inputDecoration(
                            'Enter progress note',
                            isDark,
                          ).copyWith(
                            counterStyle: TextStyle(
                              color:
                                  isDark
                                      ? AppThemes.darkTextColor
                                      : AppThemes.lightTextColor,
                            ),
                          ),
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppThemes.darkTextColor
                                    : AppThemes.lightTextColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      if (challenge.isFinancial) ...[
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 48,
                            child: ListenableBuilder(
                              listenable: _editListenable,
                              builder: (context, _) => ElevatedButton(
                                onPressed: _hasChanges ? _submitChanges : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark
                                          ? AppThemes.darkCloseButtonColor
                                          : AppThemes.lightCloseButtonColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 155,
                              height: 48,
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.history,
                                  color:
                                      isDark
                                          ? AppThemes.darkIconColor
                                          : AppThemes.lightIconColor,
                                ),
                                label: Text(
                                  "See Entries",
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? AppThemes.darkTextColor
                                            : AppThemes.lightTextColor,
                                  ),
                                ),
                                onPressed: _showEntriesDialog,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color:
                                        isDark
                                            ? AppThemes.darkIconColor
                                            : AppThemes.lightIconColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 155,
                              height: 48,
                              child: ListenableBuilder(
                                listenable: _editListenable,
                                builder: (context, _) => ElevatedButton(
                                  onPressed:
                                      _hasChanges ? _submitChanges : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isDark
                                            ? AppThemes.darkCloseButtonColor
                                            : AppThemes.lightCloseButtonColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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

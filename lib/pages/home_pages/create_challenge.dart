import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/models/challenge_state.dart';
import 'package:smoking/providers/challenge_provider.dart';
import 'package:smoking/providers/progress_provider.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/themes.dart';

class CreateChallengePage extends ConsumerStatefulWidget {
  const CreateChallengePage({super.key});

  @override
  ConsumerState<CreateChallengePage> createState() =>
      _CreateChallengePageState();
}

class _CreateChallengePageState extends ConsumerState<CreateChallengePage> {
  final _formKey = GlobalKey<FormState>();
  String challengeType = 'physical';
  String iconAsset = 'assets/icons/weight-lifting.png';

  final titleController = TextEditingController();
  final goalBudgetController = TextEditingController();
  final titleFocus = FocusNode();
  final budgetFocus = FocusNode();

  // In-flight guard against double-tap. Without this, two rapid presses
  // across the Appwrite round-trip create two challenges with the same
  // title. Same pattern as `_isSending` in `forum.dart` / `dm.dart`.
  bool _isSubmitting = false;

  // Hand-managed error text for the goal-budget field. Rendered manually
  // below the TextFormField so its leading edge can align with the field's
  // box outline (and with the "Goal Budget (currency)" label above), which
  // is impossible with Material's built-in errorText — that one aligns
  // with `contentPadding.start` (16 px in from the box edge). Material's
  // red error border still fires via the validator below.
  String? _budgetError;

  // Previously installed two focus-node listeners that fired empty
  // `setState(() {})` on blur to repaint validators. Removed in favor of
  // the Form's `autovalidateMode: AutovalidateMode.onUserInteraction`
  // (set below), which is what the listeners were emulating.

  @override
  void dispose() {
    titleController.dispose();
    goalBudgetController.dispose();
    titleFocus.dispose();
    budgetFocus.dispose();
    super.dispose();
  }

  String? _validateGoalBudget(
    String? value,
    double moneySaved,
    String currency,
  ) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Must be a number';
    if (parsed < moneySaved) {
      return 'Goal budget cannot be less the than money saved '
          '($currency${moneySaved.toStringAsFixed(2)})';
    }
    return null;
  }

  Future<void> _submitChallenge() async {
    if (_isSubmitting) return;
    final userId = ref.read(userProvider).userId;
    if (!_formKey.currentState!.validate()) return;
    // The goal-budget validator on the TextFormField below runs through
    // `_formKey.currentState!.validate()` and triggers Material's red
    // border, but its returned message is suppressed visually (rendered
    // manually outside the decoration). Mirror that result into the local
    // error state so the manual text appears when the user submits with
    // a budget that's still too low, even if they haven't typed since the
    // form last validated.
    if (challengeType == 'financial') {
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

    final newChallenge = Challenge(
      id: '',
      userId: '',
      title: title,
      type: challengeType.toLowerCase(),
      iconPath: iconAsset,
      status: 'active',
      createdAt: DateTime.now(),
      goalBudget:
          challengeType == 'financial' ? double.tryParse(goalBudget) : null,
      progress: 0.0,
      collected: 0.0,
      lastEntry: null,
      entries: [],
    );

    setState(() => _isSubmitting = true);
    try {
      // Provider returns false on Appwrite failure (no longer rethrows). Keep
      // the form on screen so the user can retry without retyping.
      final success = await ref
          .read(challengeProvider.notifier)
          .addChallenge(userId, newChallenge);

      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to create challenge. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _iconOption(String assetPath, bool isDark) {
    final isSelected = iconAsset == assetPath;
    return GestureDetector(
      onTap: () => setState(() => iconAsset = assetPath),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected
                    ? (isDark
                        ? AppThemes.activeColor
                        : AppThemes.lightAppBarColor)
                    : (isDark ? Colors.grey.shade600 : Colors.grey),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
        ),
        padding: const EdgeInsets.all(6),
        child: Image.asset(assetPath, width: 40, height: 40),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText, bool isDark) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppThemes.inputHintStyle(isDark),
      fillColor: isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
      filled: true,
      // Material's default `errorMaxLines` is 1, which truncates the
      // "Goal budget cannot be less than money saved (€xxxx.xx)" validator
      // message below the goal-budget field with an ellipsis. Allow up to
      // two lines so the user can actually read what they need to change.
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppThemes.inputBorderColor(isDark)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppThemes.inputBorderColor(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppThemes.activeColor : AppThemes.lightAppBarColor,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moneySaved = ref.watch(progressProvider.select((s) => s.moneySaved));
    final currency = ref.watch(userProvider.select((u) => u.selectedCurrency));
    final isDark = ref.isDark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Create New Challenge",
          style: TextStyle(
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Challenge Title",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? AppThemes.darkTextColor
                                        : AppThemes.lightTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: titleController,
                              focusNode: titleFocus,
                              decoration: _inputDecoration(
                                "Enter challenge title",
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
                                      value!.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Challenge Type",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? AppThemes.darkTextColor
                                        : AppThemes.lightTextColor,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: DropdownButton<String>(
                                value:
                                    challengeType == 'physical'
                                        ? 'Physical'
                                        : 'Financial',
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
                                onChanged:
                                    (value) => setState(() {
                                      challengeType = value!.toLowerCase();
                                    }),
                              ),
                            ),
                            if (challengeType == 'financial') ...[
                              const SizedBox(height: 16),
                              Text(
                                "Goal Budget ($currency)",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppThemes.darkTextColor
                                          : AppThemes.lightTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: goalBudgetController,
                                focusNode: budgetFocus,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  "Enter goal amount",
                                  isDark,
                                ).copyWith(
                                  // Suppress Material's built-in error-text
                                  // rendering (we draw it ourselves below
                                  // so the leading edge can be flush with
                                  // the box). Zero-height TextStyle means
                                  // no vertical space is reserved for it.
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
                                validator:
                                    (value) => _validateGoalBudget(
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
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              "Select Icon",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? AppThemes.darkTextColor
                                        : AppThemes.lightTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children:
                                  [
                                        'assets/icons/weight-lifting.png',
                                        'assets/icons/running.png',
                                        'assets/icons/piggy-bank.png',
                                        'assets/icons/book.png',
                                        'assets/icons/meditation.png',
                                        'assets/icons/mental-health.png',
                                        'assets/icons/healthy-food.png',
                                        'assets/icons/bike.png',
                                        'assets/icons/water.png',
                                      ]
                                      .map(
                                        (asset) => _iconOption(asset, isDark),
                                      )
                                      .toList(),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: ElevatedButton(
                                onPressed:
                                    _isSubmitting ? null : _submitChallenge,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark
                                          ? AppThemes.darkCloseButtonColor
                                          : AppThemes.lightCloseButtonColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                ),
                                child:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Text(
                                          "Create Challenge",
                                          style: TextStyle(color: Colors.white),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

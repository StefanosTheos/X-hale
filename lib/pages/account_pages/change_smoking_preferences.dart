import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/input_decoration.dart';
import 'package:smoking/pages/account_pages/widgets/settings_form_card.dart';
import 'package:smoking/pages/utils/themes.dart';

class SmokingPreferencesPage extends ConsumerStatefulWidget {
  final String userId;

  const SmokingPreferencesPage({super.key, required this.userId});

  @override
  ConsumerState<SmokingPreferencesPage> createState() =>
      _SmokingPreferencesPageState();
}

class _SmokingPreferencesPageState
    extends ConsumerState<SmokingPreferencesPage> {
  final _formKey = GlobalKey<FormState>();

  // Gates the Save button while the Appwrite write is in flight — without
  // it, a second tap would re-pop the confirmation dialog on top of the
  // running save and fire the success snackbar twice on success.
  bool _isSaving = false;

  late String formOfConsumption;
  late String selectedCurrency;
  late double timePerCigarette;

  final List<String> consumptionOptions = ['Cigarettes', 'Rolling Tobacco'];
  final List<String> currencyOptions = ['€', '\$', '£'];
  final List<double> timeOptions = [
    for (double i = 0.5; i <= 10.0; i += 0.5)
      double.parse(i.toStringAsFixed(2)),
  ];

  late TextEditingController cigarettesPerDayController;
  late TextEditingController cigarettesPerPackController;
  late TextEditingController yearsSmokingController;
  late TextEditingController pricePerPackController;

  @override
  void initState() {
    super.initState();
    final userState = ref.read(userProvider);

    formOfConsumption = consumptionOptions.firstWhere(
      (opt) =>
          opt.toLowerCase() == userState.formOfConsumption.toLowerCase().trim(),
      orElse: () => consumptionOptions.first,
    );
    selectedCurrency = userState.selectedCurrency;
    timePerCigarette = userState.minutesPerCig;

    cigarettesPerDayController = TextEditingController(
      text: userState.cigsPerDay.toString(),
    );
    cigarettesPerPackController = TextEditingController(
      text: userState.cigsPerPack.toString(),
    );
    yearsSmokingController = TextEditingController(
      text: userState.yearsSmoking.toString(),
    );
    pricePerPackController = TextEditingController(
      text: userState.pricePerPack.toString(),
    );
  }

  @override
  void dispose() {
    cigarettesPerDayController.dispose();
    cigarettesPerPackController.dispose();
    yearsSmokingController.dispose();
    pricePerPackController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences(bool isDark) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final userNotifier = ref.read(userProvider.notifier);

        await userNotifier.updateSettings(
          cigsPerDay: int.parse(cigarettesPerDayController.text),
          cigsPerPack: int.parse(cigarettesPerPackController.text),
          yearsSmoking: int.parse(yearsSmokingController.text),
          pricePerPack: double.parse(pricePerPackController.text),
          minutesPerCig: timePerCigarette,
          formOfConsumption: formOfConsumption,
          selectedCurrency: selectedCurrency,
        );
        if (!mounted) return;

        // Use Flutter's default snackbar styling — no custom background or
        // text color — to match the rest of the app (account, diary, dm,
        // forum, friends, motivations, home, settings all leave SnackBar
        // colors at their defaults). The previous themed-bg version stood
        // out visually compared to every other snackbar in the app.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences updated successfully.'),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          // Same default styling for error — keeps a single visual language
          // for every snackbar. The error message is appended verbatim so
          // any Appwrite schema rejection surfaces to the user instead of
          // being swallowed under a generic "Failed" string.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update preferences: $e'),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, bool isDark) =>
      themedInputDecoration(isDark: isDark, label: label);

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, isDark),
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'Smoking Preferences',
          style: TextStyle(
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
        iconTheme: IconThemeData(
          color: isDark ? AppThemes.darkIconColor : AppThemes.lightIconColor,
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppThemes.darkGradient : AppThemes.lightGradient,
        ),
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SettingsFormCard(
                    isDark: isDark,
                    child: DropdownButtonFormField<String>(
                      decoration: _inputDecoration(
                        'Form of Consumption',
                        isDark,
                      ),
                      initialValue: formOfConsumption,
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
                          consumptionOptions
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? AppThemes.darkTextColor
                                              : AppThemes.lightTextColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => formOfConsumption = value!),
                    ),
                  ),
                  SettingsFormCard(
                    isDark: isDark,
                    child: _buildNumberField(
                      label: 'Cigarettes per day',
                      controller: cigarettesPerDayController,
                      validator: (val) {
                        final num = int.tryParse(val ?? '');
                        if (num == null || num < 1 || num > 200) {
                          return 'Enter 1–200';
                        }
                        return null;
                      },
                      isDark: isDark,
                    ),
                  ),
                  SettingsFormCard(
                    isDark: isDark,
                    child: _buildNumberField(
                      label: 'Cigarettes in pack / pouch',
                      controller: cigarettesPerPackController,
                      validator: (val) {
                        final num = int.tryParse(val ?? '');
                        if (num == null || num < 1 || num > 100) {
                          return 'Enter 1–100';
                        }
                        return null;
                      },
                      isDark: isDark,
                    ),
                  ),
                  SettingsFormCard(
                    isDark: isDark,
                    child: _buildNumberField(
                      label: 'Years of smoking',
                      controller: yearsSmokingController,
                      validator: (val) {
                        final num = int.tryParse(val ?? '');
                        if (num == null || num < 1 || num > 100) {
                          return 'Enter 1–100';
                        }
                        return null;
                      },
                      isDark: isDark,
                    ),
                  ),
                  SettingsFormCard(
                    isDark: isDark,
                    child: _buildNumberField(
                      label: 'Price per pack / pouch',
                      controller: pricePerPackController,
                      validator: (val) {
                        final num = double.tryParse(val ?? '');
                        if (num == null || num < 1 || num > 1000) {
                          return 'Enter 1–1000';
                        }
                        return null;
                      },
                      isDark: isDark,
                    ),
                  ),
                  SettingsFormCard(
                    isDark: isDark,
                    child: DropdownButtonFormField<double>(
                      decoration: _inputDecoration(
                        'Time per cigarette (minutes)',
                        isDark,
                      ),
                      initialValue: timePerCigarette,
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
                          timeOptions
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e.toString(),
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? AppThemes.darkTextColor
                                              : AppThemes.lightTextColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => timePerCigarette = value!),
                    ),
                  ),
                  SettingsFormCard(
                    isDark: isDark,
                    child: DropdownButtonFormField<String>(
                      decoration: _inputDecoration(
                        'Preferred Currency',
                        isDark,
                      ),
                      initialValue: selectedCurrency,
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
                          currencyOptions
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? AppThemes.darkTextColor
                                              : AppThemes.lightTextColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => selectedCurrency = value!),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? AppThemes.darkCloseButtonColor
                              : AppThemes.lightCloseButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        final shouldProceed = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient:
                                        isDark
                                            ? AppThemes.darkDialogGradient
                                            : AppThemes.lightDialogGradient,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 48,
                                        color:
                                            isDark
                                                ? AppThemes.darkDialogTitleColor
                                                : AppThemes
                                                    .lightDialogTitleColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "This change won't affect past achievements.\nDo you wish to continue?",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDark
                                                  ? AppThemes.darkTextColor
                                                  : AppThemes.lightTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppThemes.elevatedButtonBackground(
                                                    isDark,
                                                  ),
                                              foregroundColor:
                                                  isDark
                                                      ? AppThemes.darkTextColor
                                                      : AppThemes
                                                          .lightTextColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('No'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  isDark
                                                      ? AppThemes
                                                          .darkCloseButtonColor
                                                      : AppThemes
                                                          .lightCloseButtonColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        );

                        if (shouldProceed == true) {
                          await _savePreferences(isDark);
                        }
                      }
                    },
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Preferences',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:smoking/pages/home_pages/home.dart';
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:smoking/providers/user_provider.dart';

class InitialSmokingPreferencesPage extends ConsumerStatefulWidget {
  final Account account;
  final String email;
  final String name;
  final String? phoneNumber;
  final bool fromGoogleSignIn;

  const InitialSmokingPreferencesPage({
    super.key,
    required this.account,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.fromGoogleSignIn = false,
  });

  @override
  ConsumerState<InitialSmokingPreferencesPage> createState() =>
      _InitialSmokingPreferencesPageState();
}

class _InitialSmokingPreferencesPageState
    extends ConsumerState<InitialSmokingPreferencesPage> {
  final _formKey = GlobalKey<FormState>();

  String formOfConsumption = 'Cigarettes';
  String selectedCurrency = '€';
  double timePerCigarette = 5.0;
  DateTime? selectedQuitDate;

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
  late TextEditingController passwordController;
  late TextEditingController repeatPasswordController;

  @override
  void initState() {
    super.initState();
    cigarettesPerDayController = TextEditingController();
    cigarettesPerPackController = TextEditingController();
    yearsSmokingController = TextEditingController();
    pricePerPackController = TextEditingController();
    if (widget.fromGoogleSignIn) {
      passwordController = TextEditingController();
      repeatPasswordController = TextEditingController();
    }
  }

  @override
  void dispose() {
    cigarettesPerDayController.dispose();
    cigarettesPerPackController.dispose();
    yearsSmokingController.dispose();
    pricePerPackController.dispose();
    if (widget.fromGoogleSignIn) {
      passwordController.dispose();
      repeatPasswordController.dispose();
    }
    super.dispose();
  }

  Future<void> _selectQuitDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().toLocal(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().toLocal(),
    );
    if (picked != null && picked != selectedQuitDate) {
      setState(() {
        selectedQuitDate = picked;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedQuitDate == null) {
      // Form validation only covers the TextFormFields; the date picker is
      // its own control, so surface the missing date explicitly instead of
      // silently no-op'ing on submit.
      await showAppErrorDialog(
        context,
        'Quit date required',
        'Please pick a quit date before continuing.',
      );
      return;
    }
    try {
      if (widget.fromGoogleSignIn) {
        final pass = passwordController.text.trim();
        final confirmPass = repeatPasswordController.text.trim();

        if (!_isStrongPassword(pass)) {
          // Previously these two checks `return`ed silently — Save tap with
          // a weak/mismatched password did nothing and the user had no idea
          // why. Show the same message the field validator uses.
          await showAppErrorDialog(
            context,
            'Weak password',
            'Password must be at least 8 characters and include uppercase, lowercase, a digit, and a special character.',
          );
          return;
        }
        if (pass != confirmPass) {
          await showAppErrorDialog(
            context,
            'Passwords do not match',
            'Please make sure both password fields are identical.',
          );
          return;
        }

        await widget.account.updatePassword(password: pass);
      }
      final utcQuitDate = selectedQuitDate?.toUtc();

      final userNotifier = ref.read(userProvider.notifier);
      final user = await widget.account.get();
      await userNotifier.initializeUser(
        userId: user.$id,
        email: widget.email,
        name: widget.name,
        phoneNumber:
            widget.phoneNumber?.isNotEmpty == true ? widget.phoneNumber : null,
        formOfConsumption: formOfConsumption,
        currency: selectedCurrency,
        cigsPerDay: int.parse(cigarettesPerDayController.text),
        cigsPerPack: int.parse(cigarettesPerPackController.text),
        pricePerPack: double.parse(pricePerPackController.text),
        minutesPerCig: timePerCigarette,
        quitDate: utcQuitDate!,
        yearsSmoking: int.parse(yearsSmokingController.text),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(account: widget.account)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: ${e.toString()}')),
        );
      }
      debugPrint('Error saving preferences: $e');
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(padding: const EdgeInsets.all(12.0), child: child),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      keyboardType: TextInputType.number,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your smoking preferences',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff48CAE4),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xffB5EAEA)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildCard(
                    child: DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Form of Consumption'),
                      initialValue: formOfConsumption,
                      items:
                          consumptionOptions
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => formOfConsumption = value!),
                    ),
                  ),
                  _buildCard(
                    child: _buildNumberField(
                      label: 'Cigarettes per day',
                      controller: cigarettesPerDayController,
                      validator: _intValidator(1, 200),
                    ),
                  ),
                  _buildCard(
                    child: _buildNumberField(
                      label: 'Cigarettes in pack / pouch',
                      controller: cigarettesPerPackController,
                      validator: _intValidator(1, 100),
                    ),
                  ),
                  _buildCard(
                    child: _buildNumberField(
                      label: 'Years of smoking',
                      controller: yearsSmokingController,
                      validator: _intValidator(1, 100),
                    ),
                  ),
                  _buildCard(
                    child: _buildNumberField(
                      label: 'Price per pack / pouch',
                      controller: pricePerPackController,
                      validator: _doubleValidator(1.0, 1000.0),
                    ),
                  ),
                  _buildCard(
                    child: DropdownButtonFormField<double>(
                      decoration: _inputDecoration(
                        'Time per cigarette (minutes)',
                      ),
                      initialValue: timePerCigarette,
                      items:
                          timeOptions
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.toString()),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => timePerCigarette = value!),
                    ),
                  ),
                  _buildCard(
                    child: DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Preferred Currency'),
                      initialValue: selectedCurrency,
                      items:
                          currencyOptions
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => selectedCurrency = value!),
                    ),
                  ),
                  if (widget.fromGoogleSignIn) ...[
                    _buildCard(
                      child: TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: _inputDecoration(
                          'Set password',
                        ).copyWith(errorMaxLines: 3),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (!_isStrongPassword(val)) {
                            return 'Password must be 8+ characters and include uppercase, lowercase, number and symbol.';
                          }
                          return null;
                        },
                      ),
                    ),
                    _buildCard(
                      child: TextFormField(
                        controller: repeatPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration('Confirm password'),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (val != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                  _buildCard(
                    child: InkWell(
                      onTap: () => _selectQuitDate(context),
                      child: InputDecorator(
                        decoration: _inputDecoration('Quit Date'),
                        child: Text(
                          selectedQuitDate != null
                              ? '${selectedQuitDate!.day}/${selectedQuitDate!.month}/${selectedQuitDate!.year}'
                              : 'Select your quit date',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff48CAE4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final shouldSave = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xffcaf0f8),
                                    Color(0xffade8f4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 48,
                                    color: Color(0xff0077b6),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Are you sure?\nDon’t worry, you can change them later.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xff48CAE4),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      if (shouldSave == true) {
                        await _savePreferences();
                      }
                    },

                    child: const Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  String? Function(String?) _intValidator(int min, int max) {
    return (val) {
      final num = int.tryParse(val ?? '');
      if (num == null || num < min || num > max) {
        return 'Enter a number between $min and $max';
      }
      return null;
    };
  }

  String? Function(String?) _doubleValidator(double min, double max) {
    return (val) {
      final num = double.tryParse(val ?? '');
      if (num == null || num < min || num > max) {
        return 'Enter a number between $min and $max';
      }
      return null;
    };
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }
}

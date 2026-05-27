import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:smoking/pages/utils/input_decoration.dart';
import 'package:smoking/pages/account_pages/widgets/settings_form_card.dart';
import 'package:smoking/pages/utils/themes.dart';

// Hoisted once at file scope so the three `SwitchListTile.adaptive`s below
// don't re-allocate identical resolvers on every `build`.
final WidgetStateProperty<Color?> _switchTrackColor =
    WidgetStateProperty.resolveWith<Color?>(
      (states) =>
          states.contains(WidgetState.selected)
              ? AppThemes.activeColor.withAlpha((0.3 * 255).round())
              : null,
    );
final WidgetStateProperty<Color?> _switchThumbColor =
    WidgetStateProperty.resolveWith<Color?>(
      (states) =>
          states.contains(WidgetState.selected) ? AppThemes.activeColor : null,
    );

class ChangeAccountInfoPage extends ConsumerStatefulWidget {
  const ChangeAccountInfoPage({super.key, required this.account});
  final Account account;

  @override
  ConsumerState<ChangeAccountInfoPage> createState() =>
      _ChangeAccountInfoPageState();
}

class _ChangeAccountInfoPageState extends ConsumerState<ChangeAccountInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _changePhone = false;
  bool _changeEmail = false;
  bool _changePassword = false;
  String? _currentPasswordError;
  // Gates Save while the email/password/phone updates are in flight. Each
  // section is a separate Appwrite write — without this, a rapid second
  // tap would re-fire the entire chain (and stack snackbars on success).
  bool _isSaving = false;

  String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Thin wrapper around `showAppErrorDialog` kept per-page to keep the
  /// `use_build_context_synchronously` lint quiet at call sites — the
  /// instance-method call captures `this.context` synchronously even when
  /// invoked after an await. The helper itself already handles the
  /// `context.mounted` check internally.
  void _showErrorDialog(String title, String message) {
    showAppErrorDialog(context, title, message);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, bool isDark) =>
      themedInputDecoration(isDark: isDark, label: label);

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    return hasUpper && hasLower && hasDigit && hasSpecial;
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
          'Edit Account Information',
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SettingsFormCard(
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'What would you like to change?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color:
                                          isDark
                                              ? AppThemes.darkTextColor
                                              : AppThemes.lightTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SwitchListTile.adaptive(
                                    value: _changeEmail,
                                    onChanged:
                                        (val) =>
                                            setState(() => _changeEmail = val),
                                    title: Text(
                                      "Email",
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                    ),
                                    trackColor: _switchTrackColor,
                                    thumbColor: _switchThumbColor,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  SwitchListTile.adaptive(
                                    value: _changePassword,
                                    onChanged:
                                        (val) => setState(
                                          () => _changePassword = val,
                                        ),
                                    title: Text(
                                      "Password",
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                    ),
                                    trackColor: _switchTrackColor,
                                    thumbColor: _switchThumbColor,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  SwitchListTile.adaptive(
                                    value: _changePhone,
                                    onChanged:
                                        (val) =>
                                            setState(() => _changePhone = val),
                                    title: Text(
                                      "Phone Number",
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                    ),
                                    trackColor: _switchTrackColor,
                                    thumbColor: _switchThumbColor,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                            if (_changeEmail)
                              SettingsFormCard(
                                isDark: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Change Email',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: _inputDecoration(
                                        'New Email',
                                        isDark,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                      validator: (value) {
                                        if (!_changeEmail) return null;
                                        if (value == null ||
                                            !value.contains('@')) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            if (_changePassword)
                              SettingsFormCard(
                                isDark: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Change Password',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: _inputDecoration(
                                        'New Password',
                                        isDark,
                                      ).copyWith(errorMaxLines: 2),
                                      obscureText: true,
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                      validator: (value) {
                                        if (!_changePassword) return null;
                                        if (value == null ||
                                            !_isValidPassword(value)) {
                                          return 'Password must be 8+ characters and include uppercase, lowercase, number and symbol.';
                                        }
                                        return null;
                                      },
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                    ),
                                    const SizedBox(height: 15),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      decoration: _inputDecoration(
                                        'Confirm Password',
                                        isDark,
                                      ),
                                      obscureText: true,
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                      validator: (value) {
                                        if (!_changePassword) return null;
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            if (_changePhone)
                              SettingsFormCard(
                                isDark: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Change Phone Number',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _phoneController,
                                      decoration: _inputDecoration(
                                        'New Phone Number',
                                        isDark,
                                      ),
                                      keyboardType: TextInputType.phone,
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? AppThemes.darkTextColor
                                                : AppThemes.lightTextColor,
                                      ),
                                      validator: (value) {
                                        if (!_changePhone) return null;
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Enter a valid phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),

                            SettingsFormCard(
                              isDark: isDark,
                              child: TextFormField(
                                controller: _currentPasswordController,
                                decoration: _inputDecoration(
                                  'Current Password',
                                  isDark,
                                ).copyWith(
                                  hintText:
                                      _changeEmail ||
                                              _changePassword ||
                                              _changePhone
                                          ? 'Enter your current password'
                                          : 'Enable change to edit',
                                ),
                                obscureText: true,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppThemes.darkTextColor
                                          : AppThemes.lightTextColor,
                                ),
                                enabled: _changeEmail || _changePassword,
                                validator: (value) {
                                  if (!_changeEmail && !_changePassword) {
                                    return null;
                                  }
                                  if (value == null || value.isEmpty) {
                                    return 'Current password is required';
                                  }
                                  return _currentPasswordError;
                                },
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
                              onPressed:
                                  _isSaving
                                      ? null
                                      : () async {
                                        setState(
                                          () => _currentPasswordError = null,
                                        );

                                        if (_formKey.currentState!.validate()) {
                                          if (!_changeEmail &&
                                              !_changePassword &&
                                              !_changePhone) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Nothing selected to update',
                                                  style: TextStyle(
                                                    color:
                                                        isDark
                                                            ? AppThemes
                                                                .darkTextColor
                                                            : AppThemes
                                                                .darkTextColor,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    isDark
                                                        ? AppThemes
                                                            .darkCardColor
                                                        : AppThemes
                                                            .darkCardColor,
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() => _isSaving = true);
                                          try {
                                            final currentPassword =
                                                _currentPasswordController.text
                                                    .trim();
                                            final userNotifier = ref.read(
                                              userProvider.notifier,
                                            );

                                            if (_changeEmail) {
                                              try {
                                                await widget.account
                                                    .updateEmail(
                                                      email:
                                                          _emailController.text
                                                              .trim(),
                                                      password: currentPassword,
                                                    );
                                                await userNotifier.updateMail(
                                                  _emailController.text.trim(),
                                                );
                                              } on AppwriteException {
                                                setState(() {
                                                  _currentPasswordError =
                                                      'Current password is incorrect';
                                                });
                                                _formKey.currentState!
                                                    .validate();
                                                return;
                                              }
                                            }
                                            if (_changePassword) {
                                              try {
                                                await widget.account
                                                    .updatePassword(
                                                      password:
                                                          _passwordController
                                                              .text
                                                              .trim(),
                                                      oldPassword:
                                                          currentPassword,
                                                    );
                                              } on AppwriteException {
                                                setState(() {
                                                  _currentPasswordError =
                                                      'Current password is incorrect';
                                                });
                                                _formKey.currentState!
                                                    .validate();
                                                return;
                                              }
                                            }
                                            if (_changePhone) {
                                              final rawPhone =
                                                  _phoneController.text.trim();
                                              final phone = normalizePhone(
                                                rawPhone,
                                              );

                                              if (!RegExp(
                                                r'^\d{7,15}$',
                                              ).hasMatch(phone)) {
                                                _showErrorDialog(
                                                  'Invalid Phone',
                                                  'Please enter a valid phone number.',
                                                );
                                                return;
                                              }

                                              final phoneExists =
                                                  await userNotifier
                                                      .checkIfPhoneExists(
                                                        phone,
                                                      );
                                              if (phoneExists) {
                                                _showErrorDialog(
                                                  'Phone Taken',
                                                  'This phone number is already in use.',
                                                );
                                                return;
                                              }
                                              try {
                                                await userNotifier.updatePhone(
                                                  phone,
                                                );
                                              } catch (e) {
                                                debugPrint(
                                                  "Phone update error: $e",
                                                );
                                                _showErrorDialog(
                                                  'Error',
                                                  'Failed to update phone number.',
                                                );
                                                return;
                                              }
                                            }

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Account info updated',
                                                    style: TextStyle(
                                                      color:
                                                          isDark
                                                              ? AppThemes
                                                                  .darkTextColor
                                                              : AppThemes
                                                                  .darkTextColor,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      isDark
                                                          ? AppThemes
                                                              .darkCardColor
                                                          : AppThemes
                                                              .darkCardColor,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Error: $e',
                                                    style: TextStyle(
                                                      color:
                                                          isDark
                                                              ? AppThemes
                                                                  .darkTextColor
                                                              : AppThemes
                                                                  .lightTextColor,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      isDark
                                                          ? AppThemes
                                                              .darkCardColor
                                                          : AppThemes
                                                              .lightCardColor,
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() => _isSaving = false);
                                            }
                                          }
                                        }
                                      },
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text(
                                        'Save Changes',
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
            },
          ),
        ),
      ),
    );
  }
}

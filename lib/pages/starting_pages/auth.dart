import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smoking/providers/diary_provider.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/pages/home_pages/home.dart';
import 'package:smoking/pages/starting_pages/initial_smoking_preferences.dart';
import 'package:smoking/pages/utils/notification_service.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthPage extends ConsumerStatefulWidget {
  final Account account;
  const AuthPage({super.key, required this.account});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  models.User? loggedInUser;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isRegisterMode = false;

  bool _isValidEmail(String email) {
    return RegExp(r"^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  /// Error text rendered inline below the new-password field in register
  /// mode. Identical message to the one used by the in-app "Change Password"
  /// flow in `change_account_info.dart` so both entry points read the same.
  static const _passwordCriteriaMessage =
      'Password must be 8+ characters and include uppercase, lowercase, '
      'number and symbol.';

  Future<void> registerPushTarget() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        if (kDebugMode) debugPrint('No FCM token available');
        return;
      }

      // Use userId for a stable targetId
      final user = await widget.account.get();
      final targetId = "push_${user.$id}";

      try {
        // First attempt: create the target.
        await widget.account.createPushTarget(
          targetId: targetId,
          identifier: fcmToken,
          providerId: "6899ba48001bda3c6a7c",
        );
      } on AppwriteException catch (e) {
        // 409 = same targetId already exists (typical re-login).
        // 404 = server thinks the target is in an inconsistent state (observed
        // in dev when an old target ID lingered after a partial cleanup).
        // Both are recovered the same way: best-effort delete, then recreate.
        if (e.code == 409 || e.code == 404) {
          try {
            await widget.account.deletePushTarget(targetId: targetId);
          } on AppwriteException catch (delErr) {
            // Nothing to delete is fine; any other error should surface.
            if (delErr.code != 404) rethrow;
          }
          await widget.account.createPushTarget(
            targetId: targetId,
            identifier: fcmToken,
            providerId: "6899ba48001bda3c6a7c",
          );
        } else {
          rethrow;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('registerPushTarget failed: $e');
    }
  }

  /// Thin wrapper around `showAppErrorDialog` kept per-page to keep the
  /// `use_build_context_synchronously` lint quiet at call sites — the
  /// instance-method call captures `this.context` synchronously even when
  /// invoked after an await. The helper itself already handles the
  /// `context.mounted` check internally.
  void _showErrorDialog(String title, String message) {
    showAppErrorDialog(context, title, message);
  }

  /// Register the FCM push target and (re-)schedule the daily affirmation
  /// + diary-reminder notifications. Called from every successful auth path
  /// (Google sign-in, email login, email register) — previously inlined
  /// byte-for-byte at three call sites.
  Future<void> _scheduleNotificationsAfterAuth() async {
    await registerPushTarget();
    await NotificationService().scheduleDailyAffirmation();
    final wroteToday =
        await ref.read(diaryProvider.notifier).hasEntryForToday();
    await NotificationService().scheduleDiaryReminder(wroteToday: wroteToday);
  }

  Future<void> loginWithGoogle() async {
    try {
      await widget.account.createOAuth2Session(
        provider: OAuthProvider.google,
        scopes: ["profile", "email"],
      );

      final user = await widget.account.get();
      final userId = user.$id;
      final email = user.email;
      final name = user.name;

      final userNotifier = ref.read(userProvider.notifier);

      final exists = await userNotifier.checkIfUserExistsByEmail(email);
      await _scheduleNotificationsAfterAuth();

      if (exists) {
        await userNotifier.fetchUserDataByEmail(email);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(account: widget.account)),
        );
      } else {
        final usernameExists = await userNotifier.checkIfUsernameExists(name);
        if (usernameExists) {
          _showErrorDialog('Username Taken', 'Please choose another username.');
          return;
        }

        await userNotifier.createNewUser(
          userId: userId,
          email: email,
          name: name,
          phoneNumber: null,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => InitialSmokingPreferencesPage(
                  account: widget.account,
                  email: email,
                  name: name,
                  phoneNumber: null,
                  fromGoogleSignIn: true,
                ),
          ),
        );
      }
    } catch (e) {
      // User-initiated cancellation isn't an error — bail silently so we don't
      // pop a "Sign-In Failed" dialog over a deliberate decision.
      if (e is PlatformException && e.code == 'CANCELED') return;
      if (kDebugMode) debugPrint('Google login error: $e');
      _showErrorDialog('Google Sign-In Failed', e.toString());
    }
  }

  String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> login(String email, String password) async {
    if (!_isValidEmail(email)) {
      _showErrorDialog('Invalid Email', 'Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Missing Password', 'Please enter your password');
      return;
    }

    final userNotifier = ref.read(userProvider.notifier);
    userNotifier.setLoading(true);
    try {
      // Just attempt the login. On the cold path (no existing session) this is
      // one network call instead of three. If a stale session is in the way,
      // Appwrite returns `user_session_already_exists` — drop it and retry once.
      try {
        await widget.account.createEmailPasswordSession(
          email: email,
          password: password,
        );
      } on AppwriteException catch (e) {
        final hasExistingSession =
            e.type == 'user_session_already_exists' ||
            (e.message?.contains('session is active') ?? false);
        if (!hasExistingSession) rethrow;
        await widget.account.deleteSession(sessionId: 'current');
        await widget.account.createEmailPasswordSession(
          email: email,
          password: password,
        );
      }
      final user = await widget.account.get();
      await userNotifier.fetchUserData(user.$id);

      await _scheduleNotificationsAfterAuth();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(account: widget.account)),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      _showErrorDialog(
        'Login Failed',
        e is AppwriteException
            ? e.message ?? 'Unknown error'
            : 'Please try again',
      );
    } finally {
      // Always reset the spinner — the success path used to skip this and the
      // user would pop back to auth with a stuck loading state.
      userNotifier.setLoading(false);
    }
  }

  Future<void> register(
    String email,
    String password,
    String repeatPassword,
    String name,
  ) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showErrorDialog('Missing Fields', 'Please fill in all required fields.');
      return;
    }

    // The password field also runs the same `_isStrongPassword` check via
    // its inline TextFormField validator in register mode — the dialog
    // below is the fallback path if the user somehow submits before
    // autovalidate has been triggered.
    if (!_isValidEmail(email)) {
      _showErrorDialog('Invalid Email', 'Please enter a valid email address.');
      return;
    }

    if (!_isStrongPassword(password)) {
      _showErrorDialog('Weak Password', _passwordCriteriaMessage);
      return;
    }

    if (password != repeatPassword) {
      _showErrorDialog('Mismatch', 'Passwords do not match.');
      return;
    }

    final phone = normalizePhone(phoneController.text.trim());
    final userNotifier = ref.read(userProvider.notifier);

    final usernameExists = await userNotifier.checkIfUsernameExists(name);
    if (usernameExists) {
      _showErrorDialog('Username Taken', 'Please choose another username.');
      return;
    }

    if (phone.isNotEmpty) {
      if (!RegExp(r'^\d{7,15}$').hasMatch(phone)) {
        _showErrorDialog('Invalid Phone', 'Please enter a valid phone number.');
        return;
      }

      final phoneExists = await userNotifier.checkIfPhoneExists(phone);
      if (phoneExists) {
        _showErrorDialog('Phone Taken', 'This phone number is already in use.');
        return;
      }
    }

    try {
      await widget.account.deleteSession(sessionId: 'current');
    } catch (e) {
      if (e is AppwriteException && e.code != 401) {
        rethrow;
      }
    }

    try {
      await widget.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      await widget.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      final user = await widget.account.get();

      await userNotifier.createNewUser(
        userId: user.$id,
        email: email,
        name: name,
        phoneNumber: phone.isNotEmpty ? phone : null,
      );

      await _scheduleNotificationsAfterAuth();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => InitialSmokingPreferencesPage(
                account: widget.account,
                email: email,
                name: name,
                phoneNumber: phone,
              ),
        ),
      );
    } catch (e) {
      String errorMessage = 'Registration failed.';
      if (e is AppwriteException) {
        if (e.code == 409) {
          errorMessage = 'This email is already in use.';
        } else if (e.code == 401) {
          errorMessage = 'Unauthorized. Check project/database permissions.';
        } else {
          // Surface the full Appwrite exception triple — code (HTTP
          // status), type (Appwrite-internal error key, e.g.
          // `user_password_mismatch`), and message — so generic-sounding
          // server responses don't hide the actual cause. Without the
          // type, an Appwrite-Function-emitted wrapper message reads the
          // same as a legitimate validation failure.
          final base = e.message ?? 'Unknown error';
          errorMessage =
              '$base\n\n(code ${e.code}, type "${e.type ?? "unknown"}")';
        }
      } else {
        errorMessage = 'Registration failed: $e';
      }
      _showErrorDialog('Registration Failed', errorMessage);
    }
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    AutovalidateMode? autovalidateMode,
  }) {
    // Switched from `TextField` to `TextFormField` so callers can opt into
    // inline validator-based errors (e.g. the password-criteria message in
    // register mode). `TextField` is a drop-in for `TextFormField` when no
    // validator is supplied — login mode still behaves the same.
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        // The password-criteria message wraps, so reserve two lines instead
        // of the Material default of one (which would ellipsise).
        errorMaxLines: 2,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gate the LOGIN/REGISTER button on `userProvider.isLoading` so a
    // double-tap can't fire two `createEmailPasswordSession` calls; also
    // swap the icon for a spinner while the auth attempt is in flight.
    final isAuthLoading = ref.watch(userProvider.select((u) => u.isLoading));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white, Color(0xffB5EAEA)]),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 32),
                          Text(
                            isRegisterMode ? 'Create Account' : 'Welcome Back',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loggedInUser != null
                                ? 'Logged in as ${loggedInUser!.name}'
                                : isRegisterMode
                                ? 'Register to get started'
                                : 'Please log in to continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _customTextField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _customTextField(
                            controller: passwordController,
                            label: 'Password',
                            icon: Icons.lock,
                            obscureText: true,
                            // Inline validator only in register mode — login
                            // mode would unfairly block existing accounts
                            // whose passwords pre-date the strength rules.
                            validator:
                                isRegisterMode
                                    ? (value) {
                                      if (value == null ||
                                          !_isStrongPassword(value)) {
                                        return _passwordCriteriaMessage;
                                      }
                                      return null;
                                    }
                                    : null,
                            autovalidateMode:
                                isRegisterMode
                                    ? AutovalidateMode.onUserInteraction
                                    : null,
                          ),
                          if (isRegisterMode) ...[
                            const SizedBox(height: 16),
                            _customTextField(
                              controller: repeatPasswordController,
                              label: 'Repeat Password',
                              icon: Icons.lock_outline,
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            _customTextField(
                              controller: nameController,
                              label: 'Username',
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 16),
                            _customTextField(
                              controller: phoneController,
                              label: 'Phone (optional)',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                          const SizedBox(height: 32),
                          Column(
                            children: [
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff48CAE4),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    shadowColor: Colors.black.withAlpha(
                                      (0.2 * 255).round(),
                                    ),
                                  ),
                                  onPressed:
                                      isAuthLoading
                                          ? null
                                          : () =>
                                              isRegisterMode
                                                  ? register(
                                                    emailController.text.trim(),
                                                    passwordController.text
                                                        .trim(),
                                                    repeatPasswordController
                                                        .text
                                                        .trim(),
                                                    nameController.text.trim(),
                                                  )
                                                  : login(
                                                    emailController.text.trim(),
                                                    passwordController.text
                                                        .trim(),
                                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isAuthLoading)
                                        const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      else
                                        Image.asset(
                                          isRegisterMode
                                              ? 'assets/icons/register.png'
                                              : 'assets/icons/login.png',
                                          width: 24,
                                          height: 24,
                                          color: Colors.white,
                                        ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isRegisterMode ? 'REGISTER' : 'LOGIN',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xff48CAE4),
                                    side: const BorderSide(
                                      color: Color(0xff48CAE4),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  onPressed:
                                      () => setState(() {
                                        isRegisterMode = !isRegisterMode;
                                      }),
                                  child: Text(
                                    isRegisterMode
                                        ? 'ALREADY HAVE AN ACCOUNT? LOGIN'
                                        : 'DON\'T HAVE AN ACCOUNT? REGISTER',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade800,
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  onPressed: () => loginWithGoogle(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icons/google.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'CONTINUE WITH GOOGLE',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

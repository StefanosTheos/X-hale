import 'package:flutter/material.dart';
import 'package:smoking/pages/utils/themes.dart';
import 'package:smoking/providers/global_keys.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/pages/starting_pages/splash_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:smoking/pages/utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initializeNotifications();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    // Drive MaterialApp.themeMode from the user's saved preference so the
    // whole widget tree theme-flips atomically. Individual pages still read
    // `ref.isDark` for their gradients/custom colors — that path now stays in
    // sync with `Theme.of(context).brightness` for any descendant that uses
    // it.
    final theme = ref.watch(userProvider.select((u) => u.theme));
    final themeMode = switch (theme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      title: 'Smoking App',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppThemes.lightBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppThemes.lightAppBarColor,
          foregroundColor: AppThemes.lightTextColor,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppThemes.darkBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppThemes.darkAppBarColor,
          foregroundColor: AppThemes.darkTextColor,
        ),
      ),
      themeMode: themeMode,
      home: SplashScreen(account: account),
    );
  }
}

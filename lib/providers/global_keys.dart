import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide `ScaffoldMessengerKey` so providers (which have no `BuildContext`)
/// can surface snackbars. Wired into `MaterialApp.scaffoldMessengerKey` in
/// `main.dart`.
final scaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>((ref) {
  return GlobalKey<ScaffoldMessengerState>();
});

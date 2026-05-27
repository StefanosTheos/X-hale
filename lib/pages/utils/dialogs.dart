import 'package:flutter/material.dart';
import 'package:smoking/pages/utils/themes.dart';

/// Shared dialog + error-feedback helpers.
///
/// **Feedback policy** (please follow):
/// - **Actionable errors** (the user might retry, or needs to acknowledge a
///   failed save / login / network call) → `showAppErrorDialog(...)`.
/// - **Transient info / success / non-blocking warnings** (e.g. "Friend
///   request sent", "History cleared") → `ScaffoldMessenger.showSnackBar`.
/// - **Confirmation prompts** with a destructive action behind a Yes/No →
///   `showGradientDialog<bool>(...)`.
///
/// Don't build bespoke `AlertDialog` or `Dialog → Container(gradient...)`
/// shells per page — every flavor has a canonical entry point here.

/// Show a centered dialog with a gradient-filled rounded container as its
/// body. Replaces the repeated `Dialog → Container(decoration: ... gradient)`
/// shell that was duplicated in `account_dialogs`, `friends_main`, etc.
///
/// [children] are placed inside a `Column(mainAxisSize: min)`. Callers pop the
/// dialog themselves (typically `Navigator.pop(context, value)` on buttons),
/// and the returned future resolves to the popped value.
Future<T?> showGradientDialog<T>({
  required BuildContext context,
  required Gradient gradient,
  required List<Widget> children,
  bool barrierDismissible = true,
  double borderRadius = 20,
  EdgeInsets padding = const EdgeInsets.all(20),
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    ),
  );
}

/// Destructive-confirmation dialog: warning icon, title, message, Cancel /
/// Delete buttons in the canonical red palette. Resolves to `true` on
/// Delete, `false` on Cancel, `null` if dismissed via barrier-tap.
///
/// Replaces ~100-line `Dialog → Container(gradient: darkDeleteDialogGradient)`
/// duplicates that lived in `friends_main`, `motivations`, and `diary`.
Future<bool?> showDeleteConfirmDialog({
  required BuildContext context,
  required bool isDark,
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String deleteLabel = 'Delete',
}) {
  return showGradientDialog<bool>(
    context: context,
    gradient: isDark
        ? AppThemes.darkDeleteDialogGradient
        : AppThemes.lightDeleteDialogGradient,
    children: [
      const Icon(
        Icons.warning_amber_rounded,
        size: 40,
        color: Colors.redAccent,
      ),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: isDark
              ? AppThemes.darkSubtitleColor
              : AppThemes.lightSubtitleColor,
        ),
      ),
      const SizedBox(height: 20),
      Builder(
        builder: (ctx) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.elevatedButtonBackground(isDark),
                foregroundColor: isDark
                    ? AppThemes.darkTextColor
                    : AppThemes.lightTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppThemes.darkDeleteButtonColor
                    : AppThemes.lightDeleteButtonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(deleteLabel),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Standard title + message + OK alert dialog.
///
/// Replaces the per-page `_showErrorDialog` helpers that previously had
/// byte-for-byte identical implementations in `auth.dart` and
/// `change_account_info.dart`.
Future<void> showAppErrorDialog(
  BuildContext context,
  String title,
  String message,
) async {
  // Most callers invoke this after an `await`; bail safely if the widget has
  // already been unmounted instead of letting `showDialog` throw on a stale
  // context.
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

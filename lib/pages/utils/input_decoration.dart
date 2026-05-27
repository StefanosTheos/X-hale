import 'package:flutter/material.dart';
import 'package:smoking/pages/utils/themes.dart';

/// Theme-aware `InputDecoration` shared by every form page. Replaces the
/// byte-for-byte `_inputDecoration` helper that was copy-pasted into
/// `change_account_info.dart`, `change_smoking_preferences.dart`, and
/// `edit_challenge.dart`.
///
/// Pass [label] for the floating-label form fields (account/preferences), or
/// [hint] for the placeholder-only style used by `edit_challenge`. Exactly
/// one of the two is expected.
InputDecoration themedInputDecoration({
  required bool isDark,
  String? label,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: label == null
        ? null
        : TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
    hintStyle: AppThemes.inputHintStyle(isDark),
    fillColor: isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor,
    filled: true,
    // Material defaults `errorMaxLines` to 1, which ellipsises long
    // validator messages like "Goal budget cannot be less than money saved
    // (€xxxx.xx)" mid-sentence. Two lines fits every current error string.
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

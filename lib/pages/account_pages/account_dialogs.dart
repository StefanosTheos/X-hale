import 'package:flutter/material.dart';
import 'package:smoking/pages/utils/dialogs.dart';
import 'package:smoking/pages/utils/themes.dart';

/// Confirmation dialogs used by `account.dart`. Each returns a `Future<bool>`
/// that resolves to `true` if the user confirmed the destructive action and
/// `false` (or the dialog was dismissed) otherwise. The caller is responsible
/// for performing the action when the future resolves true.

/// Where the user wants the new avatar to come from. Returned by
/// [showImageSourceDialog]; `null` means the dialog was dismissed.
enum AvatarSource { gallery, preset }

/// Grid of the 20 preset avatar assets. Returns the selected `assets/...`
/// path, or `null` if the user dismissed without picking.
Future<String?> showSelectAvatarDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Select an avatar'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 20,
          itemBuilder: (context, index) {
            final avatarPath = 'assets/icons/avataricon${index + 1}.png';
            return GestureDetector(
              onTap: () => Navigator.pop(ctx, avatarPath),
              child: Image.asset(avatarPath),
            );
          },
        ),
      ),
    ),
  );
}

/// "Choose from gallery" / "Choose avatar" two-button dialog. Resolves to
/// the user's choice or `null` if dismissed.
Future<AvatarSource?> showImageSourceDialog(
  BuildContext context,
  bool isDark,
) {
  Widget sourceButton({
    required IconData icon,
    required String label,
    required AvatarSource value,
  }) {
    return Builder(
      builder: (ctx) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(ctx, value),
          icon: Icon(
            icon,
            color:
                isDark ? AppThemes.darkIconColor : AppThemes.lightIconColor,
          ),
          label: Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppThemes.darkTextColor
                  : AppThemes.lightTextColor,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? AppThemes.darkAppBarColor
                : AppThemes.lightAppBarColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  return showGradientDialog<AvatarSource>(
    context: context,
    gradient: isDark
        ? AppThemes.darkDialogGradient
        : AppThemes.lightDialogGradient,
    children: [
      const SizedBox(height: 12),
      Text(
        'Select source',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color:
              isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
        ),
      ),
      const SizedBox(height: 20),
      sourceButton(
        icon: Icons.photo_library,
        label: 'Choose from gallery',
        value: AvatarSource.gallery,
      ),
      const SizedBox(height: 10),
      sourceButton(
        icon: Icons.face,
        label: 'Choose avatar',
        value: AvatarSource.preset,
      ),
    ],
  );
}

/// "Do you want to change your profile picture?" Yes/No prompt. Returns
/// `true` if the user accepted, `false` otherwise (including dismissal).
Future<bool> showProfilePicChangeConfirmDialog(
  BuildContext context,
  bool isDark,
) async {
  final result = await showGradientDialog<bool>(
    context: context,
    gradient: isDark
        ? AppThemes.darkDialogGradient
        : AppThemes.lightDialogGradient,
    children: [
      Icon(
        Icons.photo_camera,
        size: 40,
        color: isDark
            ? AppThemes.darkTitleColor
            : AppThemes.lightTitleColor,
      ),
      const SizedBox(height: 16),
      Text(
        'Do you want to change your profile picture?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color:
              isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
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
                backgroundColor: isDark
                    ? AppThemes.darkCardColor
                    : Colors.grey[300]!,
                foregroundColor: isDark
                    ? AppThemes.darkTextColor
                    : AppThemes.lightTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppThemes.darkCloseButtonColor
                    : AppThemes.lightCloseButtonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Yes'),
            ),
          ],
        ),
      ),
    ],
  );
  return result ?? false;
}

/// "Edit Username" text-input dialog. [validate] is called when the user
/// taps Save with the trimmed input; returning a non-null string sets the
/// dialog's error and keeps it open, returning `null` accepts and pops with
/// the new name. Returns the new username on Save, `null` on Cancel/dismiss.
Future<String?> showEditUsernameDialog({
  required BuildContext context,
  required bool isDark,
  required String initialValue,
  required Future<String?> Function(String candidate) validate,
}) {
  // The dialog body is a `StatefulWidget` so its `TextEditingController`
  // lifecycle lives with the widget it belongs to and is disposed in
  // `State.dispose` after the framework has unmounted the TextField that
  // listens to it. The previous shape (controller built outside +
  // `try/finally controller.dispose()` after `await showDialog(...)`)
  // raced the framework's deactivate-then-unmount sequence and triggered
  // `Failed assertion: '_dependents.isEmpty'` when the listener was still
  // attached at dispose time.
  return showDialog<String>(
    context: context,
    builder: (ctx) => _EditUsernameDialog(
      isDark: isDark,
      initialValue: initialValue,
      validate: validate,
    ),
  );
}

class _EditUsernameDialog extends StatefulWidget {
  const _EditUsernameDialog({
    required this.isDark,
    required this.initialValue,
    required this.validate,
  });

  final bool isDark;
  final String initialValue;
  final Future<String?> Function(String candidate) validate;

  @override
  State<_EditUsernameDialog> createState() => _EditUsernameDialogState();
}

class _EditUsernameDialogState extends State<_EditUsernameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDark
              ? AppThemes.darkDialogGradient
              : AppThemes.lightDialogGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Edit Username',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark
                    ? AppThemes.darkTextColor
                    : AppThemes.lightTextColor,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              style: TextStyle(
                color: isDark
                    ? AppThemes.darkTextColor
                    : AppThemes.lightTextColor,
              ),
              decoration: InputDecoration(
                hintText: 'Enter username',
                hintStyle: AppThemes.inputHintStyle(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppThemes.activeColor
                        : AppThemes.lightAppBarColor,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                errorText: _errorText,
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppThemes.darkCardColor
                        : Colors.grey[300]!,
                    foregroundColor: isDark
                        ? AppThemes.darkTextColor
                        : AppThemes.lightTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Capture the navigator before the async gap — the
                    // lint can't see through `State.mounted` to know the
                    // `context` it would otherwise use post-await is the
                    // same one. Capturing here keeps the analyzer happy
                    // and is no more work than a `context.mounted` check.
                    final navigator = Navigator.of(context);
                    final candidate = _controller.text.trim();
                    final err = await widget.validate(candidate);
                    if (!mounted) return;
                    if (err != null) {
                      setState(() => _errorText = err);
                      return;
                    }
                    navigator.pop(candidate);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppThemes.darkCloseButtonColor
                        : AppThemes.lightCloseButtonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Do you want to start from scratch?" — used by the Relapse settings card.
Future<bool> showRelapseConfirmDialog(BuildContext context, bool isDark) async {
  final result = await showGradientDialog<bool>(
    context: context,
    gradient: isDark
        ? AppThemes.darkDeleteDialogGradient
        : AppThemes.lightDeleteDialogGradient,
    children: [
      Icon(
        Icons.warning_amber_rounded,
        size: 40,
        color: isDark
            ? AppThemes.darkDeleteButtonColor
            : AppThemes.lightDeleteButtonColor,
      ),
      const SizedBox(height: 16),
      Text(
        'Do you want to start from scratch?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isDark
              ? AppThemes.darkTextColor
              : AppThemes.lightTextColor,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'This will reset all your milestones',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: isDark
              ? AppThemes.darkSubtitleColor
              : AppThemes.lightSubtitleColor,
        ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppThemes.darkCardColor
                  : Colors.grey[300]!,
              foregroundColor: isDark
                  ? AppThemes.darkTextColor
                  : AppThemes.lightTextColor,
            ),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppThemes.darkDeleteButtonColor
                  : AppThemes.lightDeleteButtonColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    ],
  );
  return result ?? false;
}

/// "Change Quit Date?" — used by Edit Quit Date after a date is picked.
Future<bool> showQuitDateChangeConfirmDialog(
  BuildContext context,
  bool isDark,
) async {
  final result = await showGradientDialog<bool>(
    context: context,
    gradient: isDark
        ? AppThemes.darkDialogGradient
        : AppThemes.lightDialogGradient,
    children: [
      Icon(
        Icons.calendar_today,
        size: 40,
        color: isDark
            ? AppThemes.darkTitleColor
            : AppThemes.lightTitleColor,
      ),
      const SizedBox(height: 16),
      Text(
        'Change Quit Date?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: isDark
              ? AppThemes.darkTitleColor
              : AppThemes.lightTitleColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Changing your quit date will reset all your milestones',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: isDark
              ? AppThemes.darkSubtitleColor
              : AppThemes.lightSubtitleColor,
        ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppThemes.darkCardColor
                  : Colors.grey[300]!,
              foregroundColor: isDark
                  ? AppThemes.darkTextColor
                  : AppThemes.lightTextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppThemes.darkCloseButtonColor
                  : AppThemes.lightCloseButtonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    ],
  );
  return result ?? false;
}

/// "Are you sure you want to logout?" — used by the Logout settings card.
Future<bool> showLogoutConfirmDialog(
  BuildContext context,
  bool isDark,
) async {
  final result = await showGradientDialog<bool>(
    context: context,
    gradient: isDark
        ? AppThemes.darkDeleteDialogGradient
        : AppThemes.lightDeleteDialogGradient,
    children: [
      Icon(
        Icons.logout,
        size: 40,
        color: isDark
            ? AppThemes.darkDeleteButtonColor
            : AppThemes.lightDeleteButtonColor,
      ),
      const SizedBox(height: 16),
      Text(
        'Are you sure you want to logout?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isDark
              ? AppThemes.darkTextColor
              : AppThemes.lightTextColor,
        ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppThemes.darkCardColor
                  : Colors.grey[300]!,
              foregroundColor: isDark
                  ? AppThemes.darkTextColor
                  : AppThemes.lightTextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppThemes.darkDeleteButtonColor
                  : AppThemes.lightDeleteButtonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    ],
  );
  return result ?? false;
}

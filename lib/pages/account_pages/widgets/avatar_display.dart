import 'dart:io';

import 'package:flutter/material.dart';

/// Circular avatar that handles the three possible storage forms of an avatar
/// path used in `UserState.avatarPath`:
///
///  * `assets/icons/...` → bundled asset image
///  * `http(s)://...`    → remote network image
///  * absolute local file path → on-disk file (e.g. picked via image_picker)
///  * anything else / missing → grey fallback with a person icon
///
/// Extracted verbatim from the nested `GestureDetector → CircleAvatar` block
/// in `account.dart` and `home.dart`. Made stateful so the `File.existsSync()`
/// hit is paid once per `avatarPath` change, not on every parent rebuild —
/// `home.dart`'s appbar rebuilds frequently from user-state mutations, so
/// the synchronous IO call was running on the UI thread per frame.
class AvatarDisplay extends StatefulWidget {
  final String avatarPath;
  final double radius;
  final VoidCallback? onTap;
  /// Optional fallback icon when the path is missing / a local file no
  /// longer exists. Defaults to a person glyph on a grey circle.
  final Widget? fallback;

  const AvatarDisplay({
    super.key,
    required this.avatarPath,
    this.radius = 50,
    this.onTap,
    this.fallback,
  });

  @override
  State<AvatarDisplay> createState() => _AvatarDisplayState();
}

class _AvatarDisplayState extends State<AvatarDisplay> {
  /// `true` only when the path is a local file we've already confirmed
  /// exists. Stays `false` for assets / URLs / missing files (those go
  /// down their own branch and never need the IO check).
  bool _localFileExists = false;

  @override
  void initState() {
    super.initState();
    _recheckLocalFile();
  }

  @override
  void didUpdateWidget(covariant AvatarDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath) {
      _recheckLocalFile();
    }
  }

  void _recheckLocalFile() {
    final path = widget.avatarPath;
    if (path.isEmpty ||
        path.startsWith('assets/icons/') ||
        path.startsWith('http')) {
      _localFileExists = false;
      return;
    }
    _localFileExists = File(path).existsSync();
  }

  Widget _buildAvatar() {
    final path = widget.avatarPath;
    if (path.startsWith('assets/icons/')) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: AssetImage(path),
      );
    }
    if (path.startsWith('http')) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: NetworkImage(path),
      );
    }
    if (_localFileExists) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: FileImage(File(path)),
      );
    }
    return widget.fallback ??
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: Colors.grey[400],
          child: Icon(
            Icons.person,
            size: widget.radius,
            color: Colors.white,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();
    if (widget.onTap == null) return avatar;
    return GestureDetector(onTap: widget.onTap, child: avatar);
  }
}

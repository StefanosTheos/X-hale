import 'package:flutter/material.dart';

/// 32-px footer with a small spinner — rendered at the tail of paginated
/// lists (forum, diary) while another page of items is in flight, so the
/// user has visual confirmation that scrolling triggered a load.
///
/// Previously declared byte-identically as a private `_LoadMoreFooter` in
/// both `diary.dart` and `forum.dart`.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

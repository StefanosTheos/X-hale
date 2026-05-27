import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/models/progress_state.dart';
import 'package:smoking/providers/challenge_provider.dart';
import 'package:smoking/providers/progress_provider.dart';

/// Wraps [child] with a `ref.listen<ProgressState>` that watches for newly
/// completed challenges and pops the celebratory dialog. Pulled out of
/// `home.dart` so the home build method doesn't carry the dialog-debounce
/// flag inline.
class ChallengeCompletionListener extends ConsumerStatefulWidget {
  const ChallengeCompletionListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ChallengeCompletionListener> createState() =>
      _ChallengeCompletionListenerState();
}

class _ChallengeCompletionListenerState
    extends ConsumerState<ChallengeCompletionListener> {
  // Guard against back-to-back challenge completions stacking dialogs on top
  // of each other. Reset when the active dialog dismisses.
  bool _dialogShowing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<ProgressState>(progressProvider, (previous, next) {
      if (_dialogShowing) return;
      if (next.newlyCompletedChallenges.isEmpty) return;
      if (previous?.newlyCompletedChallenges.length ==
          next.newlyCompletedChallenges.length) {
        return;
      }

      final newChallengeId = next.newlyCompletedChallenges.last;
      final challenge = ref
          .read(challengeProvider)
          .challenges
          .where((c) => c.id == newChallengeId)
          .firstOrNull;
      if (challenge == null) {
        // Challenge was deleted between completion and this listener firing.
        // Drop the stale ID so the listener doesn't get stuck on a phantom.
        ref
            .read(progressProvider.notifier)
            .removeFromNewlyCompleted(newChallengeId);
        return;
      }

      _dialogShowing = true;
      ref
          .read(progressProvider.notifier)
          .showChallengeCompletionDialog(context, challenge)
          .then((_) {
            if (!mounted) return;
            _dialogShowing = false;
            ref
                .read(progressProvider.notifier)
                .removeFromNewlyCompleted(newChallengeId);
          });
    });
    return widget.child;
  }
}

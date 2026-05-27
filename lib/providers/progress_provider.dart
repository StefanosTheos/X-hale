import 'dart:async';
import 'dart:math' as math;
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/models/challenge_state.dart';
import 'package:smoking/providers/challenge_provider.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';
import '../models/progress_state.dart';

final progressProvider = StateNotifierProvider<ProgressNotifier, ProgressState>(
  (ref) {
    // NOTE: we intentionally don't `ref.watch(userProvider.select((u) => u.userId))`
    // here even though most other identity-scoped providers do. The 1Hz
    // timer in `ProgressNotifier` calls `_ref.read(userProvider)`; if the
    // factory's watch dependency invalidates between a timer tick and the
    // framework's disposal of the old notifier, that read crashes with
    // Riverpod's "Cannot use ref functions after the dependency of a
    // provider changed" assertion. Instead, the in-constructor
    // `_ref.listen(userProvider, ...)` detects userId changes and resets
    // local state — same effect, no disposal-race window.
    return ProgressNotifier(ref, ref.watch(databasesProvider));
  },
);

class ProgressNotifier extends StateNotifier<ProgressState>
    with WidgetsBindingObserver {
  final Ref _ref;
  final Databases _db;
  Timer? _timer;
  DateTime? _lastSyncTime;
  bool _isForeground = true;
  final String _databaseId = AppwriteConfig.databaseId;
  // Progress fields are denormalized onto the user document — there is no
  // separate "progress" collection.
  final String _userCollection = AppwriteCollections.users;

  ProgressNotifier(this._ref, this._db) : super(ProgressState.initial()) {
    WidgetsBinding.instance.addObserver(this);

    // Start/stop the 1-Hz timer as the user logs in or out so it doesn't keep
    // ticking (and hitting Appwrite) after logout. Riverpod tears the listen
    // down when this notifier is disposed. Also resets local state when
    // userId changes (logout / login-as-other-user) so the next user
    // doesn't see the previous user's `moneySaved` / `cigsAvoided` /
    // `newlyCompletedChallenges` carry over (the factory can't narrow on
    // userId — see the comment up top for the disposal-race rationale).
    _ref.listen(userProvider, (prev, next) {
      final wasOn = prev?.isInitialized ?? false;
      final isOn = next.isInitialized;
      if (!wasOn && isOn) _startTimer();
      if (wasOn && !isOn) _stopTimer();
      if (prev != null && prev.userId.isNotEmpty && prev.userId != next.userId) {
        _completingChallenges.clear();
        _lastSyncTime = null;
        state = ProgressState.initial();
      }
    });

    if (_ref.read(userProvider).isInitialized) _startTimer();
  }

  void _startTimer() {
    if (_timer != null || !_isForeground) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final user = _ref.read(userProvider);
      if (!user.isInitialized) return;

      final newState = ProgressState.calculateFromUser(
        quitDate: user.quitDate.toUtc(),
        cigsPerDay: user.cigsPerDay,
        cigsPerPack: user.cigsPerPack,
        pricePerPack: user.pricePerPack,
        minutesPerCig: user.minutesPerCig,
      );

      // Refresh state every second so the displayed timer ticks. Side effects
      // (Appwrite sync, financial-challenge threshold check) only need to run
      // when an integer counter actually moves — `cigsAvoided` is monotonic
      // and `moneySaved` advances in lockstep with it.
      final cigsChanged = newState.cigsAvoided != state.cigsAvoided;
      state = newState;
      if (cigsChanged) {
        _maybeSyncWithAppwrite(user.userId);
        _checkFinancialChallengeCompletion(user.userId);
      }
    });
  }

  Future<void> _maybeSyncWithAppwrite(String userId) async {
    final now = DateTime.now();
    if (_lastSyncTime != null &&
        now.difference(_lastSyncTime!) < const Duration(minutes: 5)) {
      return;
    }

    _lastSyncTime = now;
    await _syncWithAppwrite(userId);
  }

  Future<void> _syncWithAppwrite(String userId) async {
    try {
      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollection,
        queries: [Query.equal("userId", userId)],
      );

      if (result.documents.isNotEmpty) {
        final docId = result.documents.first.$id;
        await _db.updateDocument(
          databaseId: _databaseId,
          collectionId: _userCollection,
          documentId: docId,
          data: state.toAppwritePartial(),
        );
        state = state.copyWith(isSynced: true);
      }
    } catch (e) {
      debugPrint('Progress sync failed: $e');
      state = state.copyWith(isSynced: false);
    }
  }

  // Tracks challenges currently being marked complete so rapid consecutive
  // ticks can't fire the same `updateChallengeStatus` twice and stack duplicate
  // "newly completed" entries.
  final Set<String> _completingChallenges = {};

  Future<void> _checkFinancialChallengeCompletion(String userId) async {
    final challengeState = _ref.read(challengeProvider);
    for (final challenge in challengeState.challenges) {
      if (challenge.isFinancial &&
          challenge.isActive &&
          challenge.goalBudget != null &&
          state.moneySaved >= challenge.goalBudget! &&
          !_completingChallenges.contains(challenge.id)) {
        _completingChallenges.add(challenge.id);
        try {
          await _ref
              .read(challengeProvider.notifier)
              .updateChallengeStatus(challenge.id, 'completed');
          // Idempotent push — `_completingChallenges` closes the in-flight
          // window, but if a later tick lands before the local
          // challengeProvider reflects 'completed' (it should be synchronous
          // after the await, but defend anyway) we don't want the celebration
          // dialog to surface the same challenge twice.
          if (!state.newlyCompletedChallenges.contains(challenge.id)) {
            state = state.copyWith(
              newlyCompletedChallenges: [
                ...state.newlyCompletedChallenges,
                challenge.id,
              ],
            );
          }
        } finally {
          _completingChallenges.remove(challenge.id);
        }
      }
    }
  }

  Future<void> showChallengeCompletionDialog(
    BuildContext context,
    Challenge challenge,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChallengeCompletionDialog(challenge: challenge),
    );
  }

  void removeFromNewlyCompleted(String challengeId) {
    state = state.copyWith(
      newlyCompletedChallenges:
          state.newlyCompletedChallenges
              .where((id) => id != challengeId)
              .toList(),
    );
  }

  Future<void> forceRecalculate() async {
    final user = _ref.read(userProvider);
    if (!user.isInitialized) return;

    final newState = ProgressState.calculateFromUser(
      quitDate: user.quitDate.toUtc(),
      cigsPerDay: user.cigsPerDay,
      cigsPerPack: user.cigsPerPack,
      pricePerPack: user.pricePerPack,
      minutesPerCig: user.minutesPerCig,
    );

    state = newState;
    await _syncWithAppwrite(user.userId);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      if (_ref.read(userProvider).isInitialized) _startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isForeground = false;
      _stopTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    super.dispose();
  }
}

class _ChallengeCompletionDialog extends StatefulWidget {
  const _ChallengeCompletionDialog({required this.challenge});

  final Challenge challenge;

  @override
  State<_ChallengeCompletionDialog> createState() =>
      _ChallengeCompletionDialogState();
}

class _ChallengeCompletionDialogState extends State<_ChallengeCompletionDialog>
    with TickerProviderStateMixin {
  // Single shot: drives the trophy's scale-in + the title fade-in.
  late final AnimationController _entry;
  // Continuous: drives the sparkle ring around the trophy.
  late final AnimationController _sparkle;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _entry.forward();
    // Tactile reinforcement of the visual celebration.
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _entry.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffcaf0f8), Color(0xffade8f4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: AnimatedBuilder(
                animation: Listenable.merge([_entry, _sparkle]),
                builder: (context, _) {
                  // Elastic-out so the trophy overshoots and settles — feels
                  // celebratory without needing Lottie/Rive.
                  final scale =
                      Curves.elasticOut.transform(_entry.value).clamp(0.0, 1.4);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: _SparkleRingPainter(progress: _sparkle.value),
                      ),
                      Transform.scale(
                        scale: scale,
                        child: const Icon(
                          Icons.emoji_events,
                          size: 72,
                          color: Color(0xff0077b6),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _entry,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
              ),
              child: const Text(
                'Challenge Completed!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xff0077b6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _entry,
                curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
              ),
              child: Text(
                'You completed "${widget.challenge.title}" by saving €${widget.challenge.goalBudget?.toStringAsFixed(2)}!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff48CAE4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkleRingPainter extends CustomPainter {
  _SparkleRingPainter({required this.progress});

  /// 0..1, repeats. Used to drive the staggered sparkle pulse.
  final double progress;

  static const int _count = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final paint = Paint()..color = const Color(0xff0077b6);

    for (var i = 0; i < _count; i++) {
      // Each sparkle is phase-offset around the ring so the pulse rotates.
      final phase = (progress + i / _count) % 1.0;
      // Triangle wave: 0 → 1 → 0 over the cycle.
      final pulse = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
      final opacity = (0.15 + pulse * 0.65).clamp(0.0, 1.0);
      final dotRadius = 2.0 + pulse * 3.5;

      final angle = (i / _count) * 2 * math.pi;
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      paint.color = const Color(0xff0077b6).withAlpha((opacity * 255).round());
      canvas.drawCircle(pos, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

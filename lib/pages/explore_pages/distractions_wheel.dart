import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';

class SpinTheWheelPage extends ConsumerStatefulWidget {
  const SpinTheWheelPage({super.key});

  @override
  ConsumerState<SpinTheWheelPage> createState() => _SpinTheWheelPageState();
}

class _SpinTheWheelPageState extends ConsumerState<SpinTheWheelPage>
    with SingleTickerProviderStateMixin {
  final List<String> activities = [
    'Go for a walk 🚶‍♂️',
    'Drink water 💧',
    'Call a friend 📞',
    'Do 10 pushups 💪',
    'Breathe deeply 🌬️',
    'Eat a fruit 🍎',
    'Play a game 🎮',
    'Take a cold shower 🚿',
  ];

  int selectedIndex = 0;
  bool isSpinning = false;
  Timer? countdownTimer;
  Duration remainingTime = Duration.zero;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _updateRemainingTime();
  }

  void _updateRemainingTime() {
    // Cancel any prior countdown before computing a fresh one. Without this,
    // a hot reload, re-push of the page, or a successful spin (which calls
    // this again at line 95) would leave the previous `Timer.periodic`
    // running in parallel, decrementing `remainingTime` twice per second.
    countdownTimer?.cancel();
    countdownTimer = null;
    final lastSpinTime = ref.read(userProvider).lastWheelSpin;
    if (lastSpinTime == null) return;
    final now = DateTime.now();
    final nextAvailable = lastSpinTime.add(const Duration(hours: 24));
    if (!now.isBefore(nextAvailable)) return;
    remainingTime = nextAvailable.difference(now);
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        countdownTimer?.cancel();
        return;
      }
      setState(() {
        // Clamp at zero so the displayed countdown can't briefly show a
        // negative value between the decrement and the cancel check.
        final next = remainingTime - const Duration(seconds: 1);
        remainingTime = next.isNegative ? Duration.zero : next;
        if (remainingTime == Duration.zero) {
          countdownTimer?.cancel();
          countdownTimer = null;
        }
      });
    });
  }

  Future<void> _startSpin() async {
    if (isSpinning || remainingTime.inSeconds > 0) return;

    setState(() => isSpinning = true);

    final random = Random();
    final spins = 10 + random.nextInt(10);
    selectedIndex = random.nextInt(activities.length);
    final anglePerItem = 2 * pi / activities.length;
    final targetAngle =
        spins * 2 * pi + (activities.length - selectedIndex) * anglePerItem;

    _animation = Tween<double>(
      begin: 0,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.reset();
    await _controller.forward();

    await ref.read(userProvider.notifier).updateWheelSpin();

    // `context.mounted` is the lint-required guard (`use_build_context_
    // synchronously`) after an await — and the check must come BEFORE the
    // setState below, not after. Previously the order was inverted: the
    // setState ran first and could throw on an unmounted State, then the
    // mounted check returned too late to prevent it.
    if (!context.mounted) return;
    setState(() {
      _updateRemainingTime();
      isSpinning = false;
    });

    final isDark = ref.isDark;

    // Awaited so `_startSpin` only resolves once the user dismisses the
    // celebration dialog. Previously fire-and-forget — a fast back-press while
    // the dialog was mounting could orphan the dialog handle and leave
    // `isSpinning` / `remainingTime` in an inconsistent visual state.
    //
    // The `context.mounted` guard above does cover this use, but the
    // analyzer can't see through the intervening `setState` + `final isDark`
    // statements to verify it, so the lint fires as a false positive.
    await showDialog<void>(
      // ignore: use_build_context_synchronously
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient:
                    isDark
                        ? AppThemes.darkDialogGradient
                        : AppThemes.lightDialogGradient,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 48,
                    color:
                        isDark
                            ? AppThemes.activeColor
                            : AppThemes.lightDialogTitleColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🎉 Congratulations!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color:
                          isDark
                              ? AppThemes.darkTextColor
                              : AppThemes.lightDialogTitleColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Today\'s activity:\n\n${activities[selectedIndex]}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppThemes.darkTextColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? AppThemes.activeColor
                              : AppThemes.lightCloseButtonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Nice!', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildWheel(double size, bool isDark) {
    final anglePerItem = 2 * pi / activities.length;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(activities.length, (index) {
                final angle = index * anglePerItem;
                return Transform.rotate(
                  angle: angle,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: size * 0.28,
                      height: size * 0.12,
                      margin: EdgeInsets.only(top: size * 0.07),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppThemes.darkCardColor
                                : Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          activities[index],
                          style: TextStyle(
                            fontSize: size * 0.035,
                            color:
                                isDark ? AppThemes.darkTextColor : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimer(bool isDark) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(remainingTime.inHours);
    final m = twoDigits(remainingTime.inMinutes.remainder(60));
    final s = twoDigits(remainingTime.inSeconds.remainder(60));

    return Column(
      children: [
        Text(
          'Come back again in:',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppThemes.darkTextColor : Colors.black87,
          ),
        ),
        Text(
          '$h:$m:$s',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            // Same tone as the "Spin the wheel daily 🎯" title up top —
            // visually couples the count-down with the page heading.
            // The "Come back again in:" label above stays neutral so the
            // numeric value reads as the emphasised element.
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTitleColor,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final wheelSize = screenSize.width * 0.85;
    final isDark = ref.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppThemes.motivationGradient(isDark),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Spin the wheel daily 🎯',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppThemes.darkTextColor
                            : AppThemes.lightTitleColor,
                  ),
                ),
                // ~30 dp of breathing room between the title and the wheel.
                // The wheel's pointer (below) is rendered via
                // `Positioned(top: wheelSize * 0.07 - 42)` inside a
                // `Stack(clipBehavior: Clip.none)`, which means its top
                // ~18 dp extends above the Stack on a typical phone. With
                // the previous 10-dp gap that overflow landed on top of
                // the title text — bumping to 30 dp leaves the title
                // visibly above the arrow's tip.
                const SizedBox(height: 30),
                // The pointer is anchored at the topmost activity box
                // rather than the wheel's bounding box. The box's top edge
                // sits at `wheelSize * 0.07` from the wheel's outer rim
                // (see `_buildWheel`'s `margin: EdgeInsets.only(top: size *
                // 0.07)`). Positioning the 40-px arrow image at
                // `top: wheelSize * 0.07 - 42` puts its bottom edge ~2 px
                // above that box top — visible gap, no overlap, scales
                // with screen-size variation. `clipBehavior: Clip.none`
                // lets the arrow render above the Stack's top edge.
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    _buildWheel(wheelSize, isDark),
                    Positioned(
                      top: wheelSize * 0.07 - 42,
                      child: Image.asset(
                        'assets/icons/arrow-down.png',
                        width: 40,
                        height: 40,
                        color: isDark ? AppThemes.activeColor : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                if (remainingTime.inSeconds <= 0)
                  ElevatedButton(
                    onPressed: isSpinning ? null : _startSpin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? AppThemes.activeColor
                              : AppThemes.lightCloseButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      'SPIN',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                else
                  _buildTimer(isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

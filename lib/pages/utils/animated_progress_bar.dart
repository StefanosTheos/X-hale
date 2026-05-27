import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatefulWidget {
  final double targetProgress;

  const AnimatedProgressBar({super.key, required this.targetProgress});

  @override
  AnimatedProgressBarState createState() => AnimatedProgressBarState();
}

class AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.targetProgress.clamp(0, 1),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() {
      setState(() {});
    });

    _controller.forward();
    _oldProgress = widget.targetProgress.clamp(0, 1);
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.targetProgress != widget.targetProgress) {
      _animation = Tween<double>(
        begin: _oldProgress,
        end: widget.targetProgress.clamp(0, 1),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
      _oldProgress = widget.targetProgress.clamp(0, 1);
    }
  }

  Color _getProgressColor(double value) {
    if (value < 0.1) return Colors.red.shade900;
    if (value < 0.2) return Colors.red.shade700;
    if (value < 0.3) return Colors.deepOrange;
    if (value < 0.4) return Colors.orangeAccent;
    if (value < 0.5) return Colors.amber;
    if (value < 0.6) return Colors.yellow.shade600;
    if (value < 0.7) return Colors.lightGreen.shade400;
    if (value < 0.8) return Colors.green.shade500;
    if (value < 0.9) return Colors.green.shade600;
    return Colors.green.shade800;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 8,
        width: double.infinity,
        child: CustomPaint(
          painter: _ProgressBarPainter(
            progress: _animation.value,
            color: _getProgressColor(_animation.value),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ProgressBarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressBarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );

    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    canvas.drawRRect(backgroundRRect, backgroundPaint);

    // Draw the foreground as a flat-edged rect *clipped* to the background's
    // rounded shape, instead of as a separate RRect with its own corner
    // radii. When `size.width * progress` is small (financial challenge
    // where saved-money << goal-budget), an independent foreground RRect's
    // corners get auto-shrunk to fit the narrow width — the resulting tiny
    // pill no longer fills the background's left curve, so the user sees a
    // short flat-edged sliver floating inside the rounded corner. Clipping
    // makes the foreground inherit the curve from the background for free.
    final clipWidth = (size.width * progress).clamp(0.0, size.width);
    if (clipWidth <= 0) return;
    canvas.save();
    canvas.clipRRect(backgroundRRect);
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, clipWidth, size.height),
      progressPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

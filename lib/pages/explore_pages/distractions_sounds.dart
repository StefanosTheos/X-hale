import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';
class SoundPlayerWidget extends ConsumerStatefulWidget {
  const SoundPlayerWidget({super.key});

  @override
  ConsumerState<SoundPlayerWidget> createState() => _SoundPlayerWidgetState();
}

class _SoundPlayerWidgetState extends ConsumerState<SoundPlayerWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<Duration>? _durSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<void>? _compSub;

  String? currentSound;
  bool isPlaying = false;
  late final List<double> _phaseOffsets;

  Duration totalDuration = Duration.zero;
  final ValueNotifier<Duration> _currentPosition = ValueNotifier(Duration.zero);
  double? _draggedSliderValue;

  late final AnimationController _barController;

  final List<Map<String, String>> sounds = [
    {'title': 'Rainfall', 'asset': 'audio/rain.mp3'},
    {'title': 'Ocean Waves', 'asset': 'audio/ocean.mp3'},
    {'title': 'Forest Birds', 'asset': 'audio/forest.mp3'},
    {'title': 'Crackling Fire', 'asset': 'audio/fireplace.mp3'},
    {'title': 'Night Crickets', 'asset': 'audio/night_crickets.mp3'},
    {'title': 'River Stream', 'asset': 'audio/river.mp3'},
    {'title': 'Wind Blowing', 'asset': 'audio/wind.mp3'},
    {'title': 'White Noise', 'asset': 'audio/white_noise.mp3'},
    {'title': 'Brown Noise', 'asset': 'audio/brown_noise.mp3'},
    {'title': 'Tibetan Bowl', 'asset': 'audio/tibetan-bowl.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _phaseOffsets = List.generate(20, (i) => i * 0.5);

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => totalDuration = d);
    });

    // Update currentPosition via ValueNotifier
    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      if (_draggedSliderValue == null) {
        _currentPosition.value = p;
      }
    });

    _compSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
      });
      _currentPosition.value = Duration.zero;
      _barController.stop();
    });
  }

  Future<void> _stopAndRelease() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.release();
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _durSub?.cancel();
    _posSub?.cancel();
    _compSub?.cancel();

    // Chain stop → release → dispose on a single detached future so the
    // native player drains cleanly before being freed. Previously
    // `_stopAndRelease()` (async) was called bare and `_audioPlayer.dispose()`
    // ran synchronously the next line — the stop/release could complete
    // against an already-disposed handle (silently swallowed by the
    // `catch (_) {}` at line 87) and native resources could leak past the
    // route pop. State teardown stays synchronous; only the player teardown
    // is deferred.
    unawaited(() async {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.release();
      } catch (_) {}
      await _audioPlayer.dispose();
    }());
    _barController.dispose();
    _currentPosition.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _audioPlayer.pause();
      _barController.stop();
      if (mounted) setState(() => isPlaying = false);
    }
  }

  Widget _buildVisualizer(bool isDark) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _barController,
        builder: (context, child) {
          return CustomPaint(
            painter: _VisualizerPainter(
              progress: _barController.value,
              isDark: isDark,
              phaseOffsets: _phaseOffsets,
            ),
          );
        },
      ),
    );
  }

  Future<void> _play(String asset) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(asset));
    _barController.repeat();
    if (!mounted) return;
    setState(() {
      currentSound = asset;
      isPlaying = true;
    });
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
    _barController.stop();
    if (!mounted) return;
    setState(() => isPlaying = false);
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        await _stopAndRelease();
      },
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: sounds.length,
                itemBuilder: (context, index) {
                  final sound = sounds[index];
                  final isSelected = sound['asset'] == currentSound;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color:
                        isSelected
                            ? (isDark
                                ? AppThemes.darkCardColor.withAlpha(
                                  (0.8 * 255).round(),
                                )
                                : Colors.blue.shade100)
                            : (isDark ? AppThemes.darkCardColor : Colors.white),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        sound['title']!,
                        style: TextStyle(
                          color:
                              isDark ? AppThemes.darkTextColor : Colors.black87,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isSelected && isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: isDark ? AppThemes.darkIconColor : Colors.blue,
                        ),
                        onPressed: () async {
                          if (isSelected && isPlaying) {
                            await _pause();
                          } else {
                            await _play(sound['asset']!);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isPlaying) _buildVisualizer(isDark),
            if (isPlaying)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ValueListenableBuilder<Duration>(
                  valueListenable: _currentPosition,
                  builder: (context, pos, child) {
                    return Column(
                      children: [
                        Slider(
                          min: 0,
                          max: totalDuration.inSeconds.toDouble().clamp(
                            0.0,
                            double.infinity,
                          ),
                          value:
                              _draggedSliderValue ??
                              pos.inSeconds
                                  .clamp(0, totalDuration.inSeconds)
                                  .toDouble(),
                          onChanged: (value) {
                            setState(() => _draggedSliderValue = value);
                          },
                          onChangeEnd: (value) async {
                            final newPos = Duration(seconds: value.toInt());
                            await _audioPlayer.seek(newPos);
                            _currentPosition.value = newPos;
                            setState(() => _draggedSliderValue = null);
                          },
                          activeColor:
                              isDark ? AppThemes.activeColor : Colors.blue,
                          inactiveColor:
                              isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(
                                Duration(
                                  seconds:
                                      (_draggedSliderValue ?? pos.inSeconds)
                                          .toInt(),
                                ),
                              ),
                              style: TextStyle(
                                color:
                                    isDark
                                        ? AppThemes.darkSubtitleColor
                                        : Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              _formatTime(totalDuration),
                              style: TextStyle(
                                color:
                                    isDark
                                        ? AppThemes.darkSubtitleColor
                                        : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final List<double> phaseOffsets;

  _VisualizerPainter({
    required this.progress,
    required this.isDark,
    required this.phaseOffsets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isDark ? AppThemes.activeColor : Colors.blueAccent
          ..style = PaintingStyle.fill;

    final barWidth = size.width / (phaseOffsets.length * 2);
    final centerY = size.height / 2;

    for (int i = 0; i < phaseOffsets.length; i++) {
      final height = 20 + 30 * sin((progress * 2 * pi) + phaseOffsets[i]);
      final barHeight = height.clamp(10, 60);
      final x = (i * barWidth * 2) + barWidth / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, centerY),
            width: barWidth,
            height: barHeight.toDouble(),
          ),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

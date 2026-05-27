import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/models/breathing_state.dart';
import 'package:smoking/pages/explore_pages/widgets/dropdown_card.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';
class BreathingExercisePage extends ConsumerStatefulWidget {
  const BreathingExercisePage({super.key});

  @override
  ConsumerState<BreathingExercisePage> createState() =>
      _BreathingExercisePageState();
}

class _BreathingExercisePageState extends ConsumerState<BreathingExercisePage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late BreathingTechnique _selectedTechnique;
  final AudioPlayer _phasePlayer = AudioPlayer();
  bool _isDisposed = false;

  bool _isRunning = false;
  String _phase = 'Inhale';
  Timer? _cycleTimer;
  int _remainingSeconds = 60;
  int _selectedDuration = 1;
  int _phaseIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedTechnique = techniques[0];
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
      lowerBound: 0.8,
      upperBound: 1.2,
    );
  }

  Future<void> _playPhase(String phase) async {
    if (_isDisposed) return;
    try {
      await _phasePlayer.stop();
      await _phasePlayer.play(
        AssetSource('audio/${_selectedTechnique.audioPrefix}_$phase.mp3'),
      );
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _remainingSeconds = _selectedDuration * 60;
    });
    _startCycle();
  }

  void _startCycle() {
    _cycleTimer?.cancel();
    _runNextPhase();
  }

  final List<String> boxCycle = ['Inhale', 'Hold', 'Exhale', 'Hold'];

  void _runNextPhase() {
    if (!_isRunning || _isDisposed || !mounted || _remainingSeconds <= 0) {
      _stopExercise();
      return;
    }

    _phase = boxCycle[_phaseIndex];
    Duration phaseDuration;
    switch (_phase) {
      case 'Inhale':
        phaseDuration = _selectedTechnique.inhale;
        break;
      case 'Hold':
        phaseDuration = _selectedTechnique.hold;
        break;
      case 'Exhale':
        phaseDuration = _selectedTechnique.exhale;
        break;
      default:
        phaseDuration = _selectedTechnique.inhale;
    }

    _controller.duration = phaseDuration;
    _controller.forward(from: 0);
    _playPhase(_phase.toLowerCase());

    int phaseSeconds = phaseDuration.inSeconds;
    _cycleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning || _isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      // Defense-in-depth: the bail check above is in the same synchronous
      // block, but keep an immediately-adjacent mounted check before the
      // setState so any future async insertion in between can't leave us
      // calling setState on a disposed State.
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        phaseSeconds--;
      });

      if (phaseSeconds <= 0) {
        timer.cancel();
        _phaseIndex = (_phaseIndex + 1) % boxCycle.length;
        _runNextPhase();
      }
    });
  }

  void _stopExercise() {
    _cycleTimer?.cancel();
    _cycleTimer = null;
    // Reset every piece of cycle state, not just the visible timer text.
    // Previously only `_remainingSeconds` and the `_phase` label were
    // cleared on stop, so the next `_startExercise` would:
    //   - resume from the stored `_phaseIndex` (boxCycle[i]) — audio cue
    //     started from the wrong phase
    //   - inherit the half-played `_controller` value — the circle's scale
    //     animated from its last position instead of from rest
    //   - hear the previous phase's audio finish (no `_phasePlayer.stop()`)
    _phaseIndex = 0;
    _phasePlayer.stop();
    _controller.stop();
    _controller.value = _controller.lowerBound;

    if (!_isDisposed && mounted) {
      setState(() {
        _isRunning = false;
        _phase = 'Inhale';
        _remainingSeconds = _selectedDuration * 60;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isRunning = false;
    _controller.dispose();
    _cycleTimer?.cancel();
    _phasePlayer.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Breathing Techniques',
          style: TextStyle(
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isDark
                ? Colors.teal[800]?.withAlpha((0.8 * 255).round())
                : const Color.fromARGB(255, 119, 203, 196),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppThemes.darkMotivationGradient
                  : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE6F7FF), Color(0xFFB5EAEA)],
                  ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownCard<BreathingTechnique>(
                  label: "Select Technique",
                  value: _selectedTechnique,
                  lightCardColor: const Color(0xffe0f7fa),
                  lightLabelColor: const Color(0xff00796b),
                  items:
                      techniques
                          .map(
                            (tech) => DropdownMenuItem(
                              value: tech,
                              child: Text(tech.name),
                            ),
                          )
                          .toList(),
                  onChanged:
                      _isRunning
                          ? null
                          : (value) {
                            if (value != null) {
                              setState(() => _selectedTechnique = value);
                            }
                          },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                DropdownCard<int>(
                  label: "Select Duration",
                  lightCardColor: const Color(0xffe0f7fa),
                  lightLabelColor: const Color(0xff00796b),
                  value: _selectedDuration,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 Minute')),
                    DropdownMenuItem(value: 3, child: Text('3 Minutes')),
                    DropdownMenuItem(value: 5, child: Text('5 Minutes')),
                  ],
                  onChanged:
                      _isRunning
                          ? null
                          : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedDuration = value;
                                _remainingSeconds = value * 60;
                              });
                            }
                          },
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppThemes.darkTextColor
                              : const Color(0xff0077B6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppThemes.darkCardColor
                            : Color.fromRGBO(255, 255, 255, 0.8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark
                                ? Colors.black.withAlpha((0.4 * 255).round())
                                : Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _selectedTechnique.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppThemes.darkTextColor : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: ScaleTransition(
                    scale: _controller,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isDark
                                ? Colors.teal[800]?.withAlpha(
                                  (0.8 * 255).round(),
                                )
                                : Colors.teal.withAlpha((0.4 * 255).round()),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _phase,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? AppThemes.darkTextColor
                                  : const Color(0xff023E8A),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Time Left: ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark
                          ? AppThemes.darkSubtitleColor
                          : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child:
                      _isRunning
                          ? ElevatedButton.icon(
                            onPressed: _stopExercise,
                            icon: Icon(Icons.stop),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDark
                                      ? AppThemes.darkDeleteButtonColor
                                      : Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            label: const Text('Stop'),
                          )
                          : ElevatedButton.icon(
                            onPressed: _startExercise,
                            icon: const Icon(Icons.play_arrow),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDark
                                      ? AppThemes.activeColor
                                      : const Color(0xff00B4D8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            label: const Text('Start'),
                          ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

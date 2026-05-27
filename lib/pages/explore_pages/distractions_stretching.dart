import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/models/stretches_state.dart';
import 'package:smoking/pages/explore_pages/widgets/dropdown_card.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';
class StretchRoutinePage extends ConsumerStatefulWidget {
  const StretchRoutinePage({super.key});

  @override
  ConsumerState<StretchRoutinePage> createState() => _StretchRoutinePageState();
}

class _StretchRoutinePageState extends ConsumerState<StretchRoutinePage> {
  late StretchExercise _selectedStretch;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDisposed = false;

  bool _isRunning = false;
  bool _isResting = false;
  Timer? _exerciseTimer;
  int _remainingSeconds = 0;
  int _selectedRepetitions = 1;
  int _currentRepetition = 1;
  String _currentSide = 'Right side';
  bool _hasChangedSide = false;

  @override
  void initState() {
    super.initState();
    _selectedStretch = stretches[0];
    _remainingSeconds = _selectedStretch.duration.inSeconds;
  }

  Future<void> _playSound(String sound) async {
    if (_isDisposed) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/$sound.mp3'));
    } catch (e) {
      debugPrint('Audio player error: $e');
    }
  }

  void _startRoutine() {
    setState(() {
      _isRunning = true;
      _currentRepetition = 1;
      _remainingSeconds = _selectedStretch.duration.inSeconds;
      _currentSide = 'Right side';
      _hasChangedSide = false;
    });
    _playSound('start');
    _startExerciseTimer();
  }

  void _startExerciseTimer() {
    _exerciseTimer?.cancel();
    setState(() {
      _isResting = false;
      _currentSide = 'Right side';
      _hasChangedSide = false;
    });

    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;

        if (!_hasChangedSide &&
            _remainingSeconds <=
                (_selectedStretch.duration.inSeconds / 2).floor()) {
          _currentSide = 'Left side';
          _hasChangedSide = true;
          _playSound('change');
        }
      });

      if (_remainingSeconds <= 0) {
        if (_isResting) {
          _startNextExercise();
        } else {
          _startRestPeriod();
        }
      }
    });
  }

  void _startRestPeriod() {
    if (_currentRepetition >= _selectedRepetitions) {
      _stopRoutine();
      return;
    }

    setState(() {
      _isResting = true;
      _remainingSeconds = _selectedStretch.restDuration.inSeconds;
    });
    _playSound('rest');
  }

  void _startNextExercise() {
    if (_currentRepetition >= _selectedRepetitions) {
      _stopRoutine();
      return;
    }

    setState(() {
      _isResting = false;
      _remainingSeconds = _selectedStretch.duration.inSeconds;
      _currentSide = 'Right side';
      _hasChangedSide = false;
      _currentRepetition++;
    });
    _playSound('next');
    _startExerciseTimer();
  }

  void _stopRoutine() {
    _exerciseTimer?.cancel();
    _playSound('complete');

    if (!_isDisposed && mounted) {
      setState(() {
        _isRunning = false;
        _isResting = false;
        _remainingSeconds = _selectedStretch.duration.inSeconds;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isRunning = false;
    _exerciseTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildInstructionCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isDark ? AppThemes.darkTextColor : AppThemes.lightTitleColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppThemes.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark ? Color.fromRGBO(0, 0, 0, 0.4) : Colors.black26,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _selectedStretch.instructions,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppThemes.darkTextColor : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppThemes.motivationGradient(isDark),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20,
              top: 5,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownCard<StretchExercise>(
                  label: "Select Stretch",
                  value: _selectedStretch,
                  items:
                      stretches
                          .map(
                            (stretch) => DropdownMenuItem(
                              value: stretch,
                              child: Text(stretch.name),
                            ),
                          )
                          .toList(),
                  onChanged:
                      _isRunning
                          ? null
                          : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStretch = value;
                                _remainingSeconds = value.duration.inSeconds;
                              });
                            }
                          },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                DropdownCard<int>(
                  label: "Repetitions",
                  value: _selectedRepetitions,
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    ),
                  ),
                  onChanged:
                      _isRunning
                          ? null
                          : (value) {
                            if (value != null) {
                              setState(() => _selectedRepetitions = value);
                            }
                          },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildInstructionCard(isDark),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: AssetImage(_selectedStretch.imageAsset),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      Text(
                        _isRunning
                            ? (_isResting ? 'Rest Time' : _selectedStretch.name)
                            : _remainingSeconds ==
                                _selectedStretch.duration.inSeconds
                            ? 'Ready to Start'
                            : 'Complete',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? AppThemes.darkTextColor
                                  : AppThemes.lightTitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRunning && !_isResting
                            ? _currentSide
                            : 'Repetition $_currentRepetition/$_selectedRepetitions',
                        style: TextStyle(
                          fontSize: 18,
                          color:
                              isDark
                                  ? AppThemes.darkSubtitleColor
                                  : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isRunning && !_isResting)
                        Text(
                          'Repetition $_currentRepetition/$_selectedRepetitions',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDark
                                    ? AppThemes.darkSubtitleColor
                                    : Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color:
                              _isResting
                                  ? Colors.orange
                                  : (isDark
                                      ? AppThemes.darkDiaryTextColor
                                      : const Color(0xff0096C7)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child:
                      _isRunning
                          ? ElevatedButton.icon(
                            onPressed: _stopRoutine,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Routine'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemes.darkDeleteButtonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )
                          : ElevatedButton.icon(
                            onPressed: _startRoutine,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Routine'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDark
                                      ? AppThemes.activeColor
                                      : const Color(0xff00B4D8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
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

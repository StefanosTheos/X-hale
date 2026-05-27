import 'package:audioplayers/audioplayers.dart';

/// Flappy-Bird audio. Migrated from `flame_audio` to `audioplayers` as part of
/// consolidating to a single audio engine.
///
/// The two players share an [AudioContext] that disables Android audio focus
/// and enables iOS `mixWithOthers`. By default every `audioplayers` instance
/// requests `AUDIOFOCUS_GAIN` on Android — so the first call to
/// [playJumpMusic] / [playCollisionMusic] would steal focus from [_bgm] and
/// stop the background music for the rest of the round. `audioFocus: none`
/// keeps the bgm and the one-shot sfx coexisting; on iOS the equivalent is
/// `AVAudioSessionCategory.playback` + `mixWithOthers` (the `mixWithOthers`
/// option is only legal on `playback`, `playAndRecord`, or `multiRoute`, so
/// `ambient` — which mixes by default — can't be paired with it explicitly).
class AudioController {
  bool isAudioEnabled;
  final AudioPlayer _bgm = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();

  static final AudioContext _mixingContext = AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  AudioController({required this.isAudioEnabled}) {
    // Loop the background music; release behaviour matches the old
    // `FlameAudio.bgm` semantics.
    _bgm.setReleaseMode(ReleaseMode.loop);
    _bgm.setAudioContext(_mixingContext);
    _sfx.setAudioContext(_mixingContext);
    startBackGroundMusic(isAudioEnabled);
  }

  Future<void> startBackGroundMusic(bool isAudioEnabled) async {
    this.isAudioEnabled = isAudioEnabled;
    if (isAudioEnabled) {
      await _bgm.setVolume(0.4);
      await _bgm.play(AssetSource('audio/music_bg.mp3'));
    }
  }

  Future<void> stopBackgroundMusic(bool isAudioEnabled) async {
    this.isAudioEnabled = isAudioEnabled;
    await _bgm.stop();
  }

  Future<void> playJumpMusic() async {
    if (isAudioEnabled) {
      await _sfx.play(AssetSource('audio/dash_jump.mp3'));
    }
  }

  Future<void> playCollisionMusic() async {
    if (isAudioEnabled) {
      await _sfx.play(AssetSource('audio/collision.mp3'));
    }
  }

  void dispose() {
    _bgm.dispose();
    _sfx.dispose();
  }
}

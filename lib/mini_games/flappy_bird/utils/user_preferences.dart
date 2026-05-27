import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  final SharedPreferences preferences;

  // Private constructor — use `UserPreferences.create()` so callers can't
  // skip the `SharedPreferences.getInstance()` await. The previous default
  // constructor fire-and-forgot `initPreference()` as `void async`, which
  // left `preferences` uninitialised whenever cold-start gameplay (and the
  // synchronous `prefGetAudioEnabled` it calls) raced ahead of the platform
  // channel — `LateInitializationError`.
  UserPreferences._(this.preferences);

  static Future<UserPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return UserPreferences._(prefs);
  }

  void prefSetAudioEnabled(bool enabled) {
    preferences.setBool("is_audio_enabled", enabled);
  }

  bool prefGetAudioEnabled() {
    return preferences.getBool("is_audio_enabled") ?? true;
  }
}

import 'package:appwrite/models.dart' as appwrite;
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_state.freezed.dart';

@freezed
class ProgressState with _$ProgressState {
  const ProgressState._();
  const factory ProgressState({
    required Duration timeSinceQuit,
    required int cigsAvoided,
    required double moneySaved,
    required Duration lifeGained,
    required Duration timeSaved,
    @Default(false) bool isSynced,
    @Default([]) List<String> newlyCompletedChallenges,
  }) = _ProgressState;

  factory ProgressState.initial() => const ProgressState(
    timeSinceQuit: Duration.zero,
    cigsAvoided: 0,
    moneySaved: 0.0,
    lifeGained: Duration.zero,
    timeSaved: Duration.zero,
    newlyCompletedChallenges: [],
  );

  factory ProgressState.calculateFromUser({
    required DateTime quitDate,
    required int cigsPerDay,
    required int cigsPerPack,
    required double pricePerPack,
    required double minutesPerCig,
  }) {
    // Normalize both sides to UTC. `quitDate` is stored UTC in Appwrite, and
    // `DateTime.difference` works on absolute instants regardless of zone —
    // computing in UTC keeps the math consistent and avoids the "compared a
    // local timestamp against a UTC one" smell across the codebase.
    final now = DateTime.now().toUtc();
    final duration = now.difference(quitDate.toUtc());

    // Future quit dates can sneak in via a stale Appwrite document or a brief
    // device-clock drift just after the user picks "today". Render zeros
    // silently; the UI shows "0 cigarettes avoided" which is the right answer
    // until the quit date has actually passed.
    if (duration.isNegative) {
      return ProgressState.initial();
    }

    // Use seconds (not minutes) so the derived counters tick at second
    // resolution. Keep `cigsAvoided` as a floored int for display, but compute
    // money / life / time from the fractional value — otherwise nothing budges
    // for ~144 minutes when the user smokes 10/day, which feels broken.
    final totalSeconds = duration.inSeconds;
    final secondsPerCigAvoided = (24 * 60 * 60) / cigsPerDay;
    final cigsAvoidedFractional = totalSeconds / secondsPerCigAvoided;
    final costPerCig = pricePerPack / cigsPerPack;

    return ProgressState(
      timeSinceQuit: duration,
      cigsAvoided: cigsAvoidedFractional.floor(),
      moneySaved: cigsAvoidedFractional * costPerCig,
      lifeGained: Duration(
        seconds: (cigsAvoidedFractional * 20 * 60).round(),
      ),
      timeSaved: Duration(
        seconds: (cigsAvoidedFractional * minutesPerCig * 60).round(),
      ),
    );
  }

  factory ProgressState.fromAppwriteDocument(appwrite.Document doc) {
    return ProgressState(
      timeSinceQuit: DateTime.now().toUtc().difference(
        DateTime.parse(doc.data['quitDate'] as String),
      ),
      cigsAvoided: doc.data['totalCigsAvoided'] as int? ?? 0,
      moneySaved: (doc.data['totalMoneySaved'] as num?)?.toDouble() ?? 0.0,
      lifeGained: Duration(
        minutes: doc.data['totalLifeGainedMinutes'] as int? ?? 0,
      ),
      timeSaved: Duration(
        minutes: doc.data['totalTimeSavedMinutes'] as int? ?? 0,
      ),
      isSynced: true,
    );
  }
}

extension ProgressStateAppwrite on ProgressState {
  Map<String, dynamic> toAppwritePartial() {
    return {
      'totalCigsAvoided': cigsAvoided,
      'totalMoneySaved': moneySaved,
      'totalLifeGainedMinutes': lifeGained.inMinutes,
      'totalTimeSavedMinutes': timeSaved.inMinutes,
      'lastProgressUpdate': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

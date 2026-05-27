import 'package:appwrite/models.dart' as appwrite;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'diary_state.freezed.dart';

@freezed
class DiaryEntry with _$DiaryEntry {
  const factory DiaryEntry({
    required String id,
    required String userId,
    required DateTime date,
    required String mood,
    required String text,
    @Default([]) List<String> tags,
    required String color,
  }) = _DiaryEntry;

  factory DiaryEntry.fromAppwriteDocument(appwrite.Document doc) {
    return DiaryEntry(
      id: doc.$id,
      userId: doc.data['userId'] as String,
      date: DateTime.parse(doc.data['date'] as String),
      mood: doc.data['mood'] as String? ?? 'neutral',
      text: doc.data['text'] as String,
      tags: (doc.data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      color: doc.data['color'] as String? ?? '#48CAE4',
    );
  }
}

@freezed
class DiaryState with _$DiaryState {
  const DiaryState._();

  const factory DiaryState({
    required String userId,
    @Default([]) List<DiaryEntry> entries,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasError,
    String? errorMessage,
    @Default('neutral') String selectedMood,
    @Default([]) List<String> selectedTags,
  }) = _DiaryState;

  factory DiaryState.initial({required String userId}) =>
      DiaryState(userId: userId);

  /// Sorted copy of [entries], newest first. Returns a new list — sorting in
  /// place would mutate the canonical state and surface as "the order changed
  /// on second read" elsewhere.
  List<DiaryEntry> get entriesByDateDesc =>
      [...entries]..sort((a, b) => b.date.compareTo(a.date));

  /// True if there is at least one entry whose local date is today. Used by
  /// the compose UI to block stacking multiple entries on the same date.
  bool get wroteToday {
    final now = DateTime.now().toLocal();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return entries.any((e) {
      final d = e.date.toLocal();
      return !d.isBefore(start) && d.isBefore(end);
    });
  }
}

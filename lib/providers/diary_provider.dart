import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/models/diary_state.dart';
import 'package:smoking/pages/utils/notification_service.dart';
import 'package:smoking/providers/user_provider.dart';
import 'package:smoking/services/appwrite_config.dart';
import 'package:smoking/services/appwrite_providers.dart';
import 'package:smoking/services/appwrite_query.dart';
import 'package:smoking/services/user_document_repository.dart';

final diaryProvider = StateNotifierProvider<DiaryNotifier, DiaryState>((ref) {
  // Narrowed to `userId` so theme flips and counter ticks don't recreate the
  // notifier (and wipe its in-memory cache + `_lastLoadedAt`).
  final userId = ref.watch(userProvider.select((u) => u.userId));
  return DiaryNotifier(
    db: ref.watch(databasesProvider),
    userRepo: ref.watch(userDocRepositoryProvider),
    ref: ref,
    userId: userId,
  );
});

class DiaryNotifier extends StateNotifier<DiaryState> {
  final Databases _db;
  final UserDocumentRepository _userRepo;
  final String _userId;
  final String _databaseId = AppwriteConfig.databaseId;
  final String _diaryCollection = AppwriteCollections.diary;

  // Skip re-fetching if the cache is still warm. Mutating ops pass `force: true`.
  DateTime? _lastLoadedAt;
  static const _cacheTtl = Duration(minutes: 2);

  // Cursor pagination — same pattern as `forum_provider`. `loadEntries` loads
  // the first page (newest first); `loadMore` appends the next page on
  // scroll. Was unbounded — pulling 200+ entries on every refresh got
  // expensive for long-time users.
  static const int _pageSize = 20;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  DiaryNotifier({
    required Databases db,
    required UserDocumentRepository userRepo,
    required Ref ref,
    required String userId,
  }) : _db = db,
       _userRepo = userRepo,
       _userId = userId,
       super(DiaryState.initial(userId: userId)) {
    loadEntries();
  }
  Future<void> loadEntries({bool force = false}) async {
    // In-flight guard: two concurrent callers (e.g. pull-to-refresh racing
    // an `initState`-triggered load) could both pass the TTL check and fire
    // duplicate Appwrite reads. Skipping when a load is already running keeps
    // it single-flight without losing the eventual result.
    if (state.isLoading) return;
    if (!force &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _cacheTtl &&
        state.entries.isNotEmpty) {
      return;
    }
    state = state.copyWith(isLoading: true);
    _hasMore = true;
    try {
      final entries = await listAndMap(
        _db,
        _diaryCollection,
        DiaryEntry.fromAppwriteDocument,
        queries: [
          Query.equal('userId', _userId),
          Query.orderDesc('date'),
          Query.limit(_pageSize),
        ],
      );
      if (!mounted) return;
      _lastLoadedAt = DateTime.now();
      state = state.copyWith(entries: entries, isLoading: false);
      _hasMore = entries.length >= _pageSize;
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        hasError: true,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Append the next page of entries (older than the last currently in
  /// state). No-op if a load is already in flight, the cursor is exhausted,
  /// or the list is empty (in which case `loadEntries` should be called).
  Future<void> loadMore() async {
    if (!mounted || state.isLoadingMore || !_hasMore) return;
    if (state.entries.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final newEntries = await listAndMap(
        _db,
        _diaryCollection,
        DiaryEntry.fromAppwriteDocument,
        queries: [
          Query.equal('userId', _userId),
          Query.orderDesc('date'),
          Query.limit(_pageSize),
          Query.cursorAfter(state.entries.last.id),
        ],
      );
      if (!mounted) return;
      state = state.copyWith(
        entries: [...state.entries, ...newEntries],
        isLoadingMore: false,
      );
      _hasMore = newEntries.length >= _pageSize;
    } catch (e) {
      debugPrint('diary loadMore error: $e');
      if (mounted) state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> updateDiaryCountInAppwrite() async {
    try {
      final diaryResponse = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _diaryCollection,
        queries: [Query.equal('userId', _userId)],
      );

      await _userRepo.updateUserField(
        _userId,
        'diaryCount',
        diaryResponse.total,
      );
    } catch (e) {
      state = state.copyWith(hasError: true, errorMessage: e.toString());
    }
  }

  Future<void> addEntry({
    required String text,
    required String mood,
    List<String> tags = const [],
  }) async {
    if (text.trim().isEmpty) return;

    try {
      final created = await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _diaryCollection,
        documentId: ID.unique(),
        data: {
          'userId': _userId,
          // Persist UTC (Z-suffixed) so cross-timezone reads still bucket
          // the entry under the user's "today" correctly. `DiaryEntry`
          // parses with `DateTime.parse`, which preserves the UTC flag,
          // and `wroteToday` calls `.toLocal()` to convert at the render
          // boundary.
          'date': DateTime.now().toUtc().toIso8601String(),
          'mood': mood,
          'text': text,
          'tags': tags,
          'color': getMoodColor(mood),
        },
      );
      // Optimistic prepend from the created doc — the page already sorts by
      // date desc via `entriesByDateDesc`, so insertion order doesn't have
      // to match Appwrite's. Previously called `loadEntries(force: true)`
      // here, which round-tripped the full first page (page size 20) on
      // every write for data we already have.
      state = state.copyWith(
        entries: [
          DiaryEntry.fromAppwriteDocument(created),
          ...state.entries,
        ],
        selectedMood: 'neutral',
        selectedTags: [],
        hasError: false,
        errorMessage: null,
      );
      await updateDiaryCountInAppwrite();
      // Suppress today's "don't forget to write a diary entry" reminder, then
      // re-schedule for tomorrow so the chain stays alive. Without the second
      // call, `cancel(1002)` would clear the OS-side daily repeat too — and
      // the user wouldn't get a ping tomorrow either.
      await NotificationService().cancelDiaryReminder();
      await NotificationService().scheduleDiaryReminder(wroteToday: true);
    } catch (e) {
      state = state.copyWith(hasError: true, errorMessage: e.toString());
    }
  }

  Future<void> deleteEntry(String documentId) async {
    // Optimistic remove with revert-on-failure. Previously `loadEntries(
    // force: true)` re-fetched the whole first page after every delete.
    final previous = state.entries;
    state = state.copyWith(
      entries: [for (final e in previous) if (e.id != documentId) e],
    );
    try {
      await _db.deleteDocument(
        databaseId: _databaseId,
        collectionId: _diaryCollection,
        documentId: documentId,
      );
      await updateDiaryCountInAppwrite();
    } catch (e) {
      state = state.copyWith(
        entries: previous,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  void updateSelectedMood(String mood) {
    state = state.copyWith(selectedMood: mood);
  }

  void toggleTag(String tag) {
    final tags = List<String>.from(state.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(selectedTags: tags);
  }

  Future<bool> hasEntryForToday() async {
    try {
      // Compute "today" from the user's local-clock perspective, then convert
      // the boundary instants to UTC ISO strings so the query lines up with
      // the new UTC-suffixed writes in `addEntry`. (Existing naive entries
      // still sort correctly against the UTC bounds for everything except
      // the exact-midnight edge case.)
      final localNow = DateTime.now();
      final localStartOfDay =
          DateTime(localNow.year, localNow.month, localNow.day);
      final localEndOfDay = localStartOfDay.add(const Duration(days: 1));

      final response = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _diaryCollection,
        queries: [
          Query.equal('userId', _userId),
          Query.greaterThanEqual(
            'date',
            localStartOfDay.toUtc().toIso8601String(),
          ),
          Query.lessThan(
            'date',
            localEndOfDay.toUtc().toIso8601String(),
          ),
        ],
      );

      return response.documents.isNotEmpty;
    } catch (e) {
      state = state.copyWith(hasError: true, errorMessage: e.toString());
      return false;
    }
  }

  String getMoodColor(String mood) {
    switch (mood) {
      case 'happy':
        return '#4CAF50';
      case 'sad':
        return '#2196F3';
      case 'excited':
        return '#FFC107';
      case 'angry':
        return '#F44336';
      case 'neutral':
      default:
        return '#48CAE4';
    }
  }
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DiaryEntry {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get mood => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiaryEntryCopyWith<DiaryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiaryEntryCopyWith<$Res> {
  factory $DiaryEntryCopyWith(
    DiaryEntry value,
    $Res Function(DiaryEntry) then,
  ) = _$DiaryEntryCopyWithImpl<$Res, DiaryEntry>;
  @useResult
  $Res call({
    String id,
    String userId,
    DateTime date,
    String mood,
    String text,
    List<String> tags,
    String color,
  });
}

/// @nodoc
class _$DiaryEntryCopyWithImpl<$Res, $Val extends DiaryEntry>
    implements $DiaryEntryCopyWith<$Res> {
  _$DiaryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? mood = null,
    Object? text = null,
    Object? tags = null,
    Object? color = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            date:
                null == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            mood:
                null == mood
                    ? _value.mood
                    : mood // ignore: cast_nullable_to_non_nullable
                        as String,
            text:
                null == text
                    ? _value.text
                    : text // ignore: cast_nullable_to_non_nullable
                        as String,
            tags:
                null == tags
                    ? _value.tags
                    : tags // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            color:
                null == color
                    ? _value.color
                    : color // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiaryEntryImplCopyWith<$Res>
    implements $DiaryEntryCopyWith<$Res> {
  factory _$$DiaryEntryImplCopyWith(
    _$DiaryEntryImpl value,
    $Res Function(_$DiaryEntryImpl) then,
  ) = __$$DiaryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    DateTime date,
    String mood,
    String text,
    List<String> tags,
    String color,
  });
}

/// @nodoc
class __$$DiaryEntryImplCopyWithImpl<$Res>
    extends _$DiaryEntryCopyWithImpl<$Res, _$DiaryEntryImpl>
    implements _$$DiaryEntryImplCopyWith<$Res> {
  __$$DiaryEntryImplCopyWithImpl(
    _$DiaryEntryImpl _value,
    $Res Function(_$DiaryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? mood = null,
    Object? text = null,
    Object? tags = null,
    Object? color = null,
  }) {
    return _then(
      _$DiaryEntryImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        date:
            null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        mood:
            null == mood
                ? _value.mood
                : mood // ignore: cast_nullable_to_non_nullable
                    as String,
        text:
            null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                    as String,
        tags:
            null == tags
                ? _value._tags
                : tags // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        color:
            null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc

class _$DiaryEntryImpl with DiagnosticableTreeMixin implements _DiaryEntry {
  const _$DiaryEntryImpl({
    required this.id,
    required this.userId,
    required this.date,
    required this.mood,
    required this.text,
    final List<String> tags = const [],
    required this.color,
  }) : _tags = tags;

  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime date;
  @override
  final String mood;
  @override
  final String text;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final String color;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DiaryEntry(id: $id, userId: $userId, date: $date, mood: $mood, text: $text, tags: $tags, color: $color)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DiaryEntry'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('userId', userId))
      ..add(DiagnosticsProperty('date', date))
      ..add(DiagnosticsProperty('mood', mood))
      ..add(DiagnosticsProperty('text', text))
      ..add(DiagnosticsProperty('tags', tags))
      ..add(DiagnosticsProperty('color', color));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiaryEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.color, color) || other.color == color));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    date,
    mood,
    text,
    const DeepCollectionEquality().hash(_tags),
    color,
  );

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiaryEntryImplCopyWith<_$DiaryEntryImpl> get copyWith =>
      __$$DiaryEntryImplCopyWithImpl<_$DiaryEntryImpl>(this, _$identity);
}

abstract class _DiaryEntry implements DiaryEntry {
  const factory _DiaryEntry({
    required final String id,
    required final String userId,
    required final DateTime date,
    required final String mood,
    required final String text,
    final List<String> tags,
    required final String color,
  }) = _$DiaryEntryImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get date;
  @override
  String get mood;
  @override
  String get text;
  @override
  List<String> get tags;
  @override
  String get color;

  /// Create a copy of DiaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiaryEntryImplCopyWith<_$DiaryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DiaryState {
  String get userId => throw _privateConstructorUsedError;
  List<DiaryEntry> get entries => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isLoadingMore => throw _privateConstructorUsedError;
  bool get hasError => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  String get selectedMood => throw _privateConstructorUsedError;
  List<String> get selectedTags => throw _privateConstructorUsedError;

  /// Create a copy of DiaryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiaryStateCopyWith<DiaryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiaryStateCopyWith<$Res> {
  factory $DiaryStateCopyWith(
    DiaryState value,
    $Res Function(DiaryState) then,
  ) = _$DiaryStateCopyWithImpl<$Res, DiaryState>;
  @useResult
  $Res call({
    String userId,
    List<DiaryEntry> entries,
    bool isLoading,
    bool isLoadingMore,
    bool hasError,
    String? errorMessage,
    String selectedMood,
    List<String> selectedTags,
  });
}

/// @nodoc
class _$DiaryStateCopyWithImpl<$Res, $Val extends DiaryState>
    implements $DiaryStateCopyWith<$Res> {
  _$DiaryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiaryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? entries = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasError = null,
    Object? errorMessage = freezed,
    Object? selectedMood = null,
    Object? selectedTags = null,
  }) {
    return _then(
      _value.copyWith(
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            entries:
                null == entries
                    ? _value.entries
                    : entries // ignore: cast_nullable_to_non_nullable
                        as List<DiaryEntry>,
            isLoading:
                null == isLoading
                    ? _value.isLoading
                    : isLoading // ignore: cast_nullable_to_non_nullable
                        as bool,
            isLoadingMore:
                null == isLoadingMore
                    ? _value.isLoadingMore
                    : isLoadingMore // ignore: cast_nullable_to_non_nullable
                        as bool,
            hasError:
                null == hasError
                    ? _value.hasError
                    : hasError // ignore: cast_nullable_to_non_nullable
                        as bool,
            errorMessage:
                freezed == errorMessage
                    ? _value.errorMessage
                    : errorMessage // ignore: cast_nullable_to_non_nullable
                        as String?,
            selectedMood:
                null == selectedMood
                    ? _value.selectedMood
                    : selectedMood // ignore: cast_nullable_to_non_nullable
                        as String,
            selectedTags:
                null == selectedTags
                    ? _value.selectedTags
                    : selectedTags // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiaryStateImplCopyWith<$Res>
    implements $DiaryStateCopyWith<$Res> {
  factory _$$DiaryStateImplCopyWith(
    _$DiaryStateImpl value,
    $Res Function(_$DiaryStateImpl) then,
  ) = __$$DiaryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    List<DiaryEntry> entries,
    bool isLoading,
    bool isLoadingMore,
    bool hasError,
    String? errorMessage,
    String selectedMood,
    List<String> selectedTags,
  });
}

/// @nodoc
class __$$DiaryStateImplCopyWithImpl<$Res>
    extends _$DiaryStateCopyWithImpl<$Res, _$DiaryStateImpl>
    implements _$$DiaryStateImplCopyWith<$Res> {
  __$$DiaryStateImplCopyWithImpl(
    _$DiaryStateImpl _value,
    $Res Function(_$DiaryStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiaryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? entries = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasError = null,
    Object? errorMessage = freezed,
    Object? selectedMood = null,
    Object? selectedTags = null,
  }) {
    return _then(
      _$DiaryStateImpl(
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        entries:
            null == entries
                ? _value._entries
                : entries // ignore: cast_nullable_to_non_nullable
                    as List<DiaryEntry>,
        isLoading:
            null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                    as bool,
        isLoadingMore:
            null == isLoadingMore
                ? _value.isLoadingMore
                : isLoadingMore // ignore: cast_nullable_to_non_nullable
                    as bool,
        hasError:
            null == hasError
                ? _value.hasError
                : hasError // ignore: cast_nullable_to_non_nullable
                    as bool,
        errorMessage:
            freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                    as String?,
        selectedMood:
            null == selectedMood
                ? _value.selectedMood
                : selectedMood // ignore: cast_nullable_to_non_nullable
                    as String,
        selectedTags:
            null == selectedTags
                ? _value._selectedTags
                : selectedTags // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$DiaryStateImpl extends _DiaryState with DiagnosticableTreeMixin {
  const _$DiaryStateImpl({
    required this.userId,
    final List<DiaryEntry> entries = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasError = false,
    this.errorMessage,
    this.selectedMood = 'neutral',
    final List<String> selectedTags = const [],
  }) : _entries = entries,
       _selectedTags = selectedTags,
       super._();

  @override
  final String userId;
  final List<DiaryEntry> _entries;
  @override
  @JsonKey()
  List<DiaryEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isLoadingMore;
  @override
  @JsonKey()
  final bool hasError;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final String selectedMood;
  final List<String> _selectedTags;
  @override
  @JsonKey()
  List<String> get selectedTags {
    if (_selectedTags is EqualUnmodifiableListView) return _selectedTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedTags);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DiaryState(userId: $userId, entries: $entries, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasError: $hasError, errorMessage: $errorMessage, selectedMood: $selectedMood, selectedTags: $selectedTags)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DiaryState'))
      ..add(DiagnosticsProperty('userId', userId))
      ..add(DiagnosticsProperty('entries', entries))
      ..add(DiagnosticsProperty('isLoading', isLoading))
      ..add(DiagnosticsProperty('isLoadingMore', isLoadingMore))
      ..add(DiagnosticsProperty('hasError', hasError))
      ..add(DiagnosticsProperty('errorMessage', errorMessage))
      ..add(DiagnosticsProperty('selectedMood', selectedMood))
      ..add(DiagnosticsProperty('selectedTags', selectedTags));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiaryStateImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other._entries, _entries) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.hasError, hasError) ||
                other.hasError == hasError) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.selectedMood, selectedMood) ||
                other.selectedMood == selectedMood) &&
            const DeepCollectionEquality().equals(
              other._selectedTags,
              _selectedTags,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    const DeepCollectionEquality().hash(_entries),
    isLoading,
    isLoadingMore,
    hasError,
    errorMessage,
    selectedMood,
    const DeepCollectionEquality().hash(_selectedTags),
  );

  /// Create a copy of DiaryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiaryStateImplCopyWith<_$DiaryStateImpl> get copyWith =>
      __$$DiaryStateImplCopyWithImpl<_$DiaryStateImpl>(this, _$identity);
}

abstract class _DiaryState extends DiaryState {
  const factory _DiaryState({
    required final String userId,
    final List<DiaryEntry> entries,
    final bool isLoading,
    final bool isLoadingMore,
    final bool hasError,
    final String? errorMessage,
    final String selectedMood,
    final List<String> selectedTags,
  }) = _$DiaryStateImpl;
  const _DiaryState._() : super._();

  @override
  String get userId;
  @override
  List<DiaryEntry> get entries;
  @override
  bool get isLoading;
  @override
  bool get isLoadingMore;
  @override
  bool get hasError;
  @override
  String? get errorMessage;
  @override
  String get selectedMood;
  @override
  List<String> get selectedTags;

  /// Create a copy of DiaryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiaryStateImplCopyWith<_$DiaryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

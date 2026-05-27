// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'challenge_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChallengeEntry {
  String get id => throw _privateConstructorUsedError;
  String get challengeId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of ChallengeEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChallengeEntryCopyWith<ChallengeEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChallengeEntryCopyWith<$Res> {
  factory $ChallengeEntryCopyWith(
    ChallengeEntry value,
    $Res Function(ChallengeEntry) then,
  ) = _$ChallengeEntryCopyWithImpl<$Res, ChallengeEntry>;
  @useResult
  $Res call({
    String id,
    String challengeId,
    String userId,
    String message,
    DateTime createdAt,
  });
}

/// @nodoc
class _$ChallengeEntryCopyWithImpl<$Res, $Val extends ChallengeEntry>
    implements $ChallengeEntryCopyWith<$Res> {
  _$ChallengeEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChallengeEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? challengeId = null,
    Object? userId = null,
    Object? message = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            challengeId:
                null == challengeId
                    ? _value.challengeId
                    : challengeId // ignore: cast_nullable_to_non_nullable
                        as String,
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            message:
                null == message
                    ? _value.message
                    : message // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChallengeEntryImplCopyWith<$Res>
    implements $ChallengeEntryCopyWith<$Res> {
  factory _$$ChallengeEntryImplCopyWith(
    _$ChallengeEntryImpl value,
    $Res Function(_$ChallengeEntryImpl) then,
  ) = __$$ChallengeEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String challengeId,
    String userId,
    String message,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$ChallengeEntryImplCopyWithImpl<$Res>
    extends _$ChallengeEntryCopyWithImpl<$Res, _$ChallengeEntryImpl>
    implements _$$ChallengeEntryImplCopyWith<$Res> {
  __$$ChallengeEntryImplCopyWithImpl(
    _$ChallengeEntryImpl _value,
    $Res Function(_$ChallengeEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChallengeEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? challengeId = null,
    Object? userId = null,
    Object? message = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ChallengeEntryImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        challengeId:
            null == challengeId
                ? _value.challengeId
                : challengeId // ignore: cast_nullable_to_non_nullable
                    as String,
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        message:
            null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$ChallengeEntryImpl implements _ChallengeEntry {
  const _$ChallengeEntryImpl({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.message,
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final String challengeId;
  @override
  final String userId;
  @override
  final String message;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'ChallengeEntry(id: $id, challengeId: $challengeId, userId: $userId, message: $message, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChallengeEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.challengeId, challengeId) ||
                other.challengeId == challengeId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, challengeId, userId, message, createdAt);

  /// Create a copy of ChallengeEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChallengeEntryImplCopyWith<_$ChallengeEntryImpl> get copyWith =>
      __$$ChallengeEntryImplCopyWithImpl<_$ChallengeEntryImpl>(
        this,
        _$identity,
      );
}

abstract class _ChallengeEntry implements ChallengeEntry {
  const factory _ChallengeEntry({
    required final String id,
    required final String challengeId,
    required final String userId,
    required final String message,
    required final DateTime createdAt,
  }) = _$ChallengeEntryImpl;

  @override
  String get id;
  @override
  String get challengeId;
  @override
  String get userId;
  @override
  String get message;
  @override
  DateTime get createdAt;

  /// Create a copy of ChallengeEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChallengeEntryImplCopyWith<_$ChallengeEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Challenge {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get iconPath => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // Financial-only fields
  double? get goalBudget => throw _privateConstructorUsedError;
  double? get progress => throw _privateConstructorUsedError;
  double? get collected =>
      throw _privateConstructorUsedError; // Physical-only fields
  DateTime? get lastEntry => throw _privateConstructorUsedError;
  List<ChallengeEntry> get entries => throw _privateConstructorUsedError;

  /// Create a copy of Challenge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChallengeCopyWith<Challenge> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChallengeCopyWith<$Res> {
  factory $ChallengeCopyWith(Challenge value, $Res Function(Challenge) then) =
      _$ChallengeCopyWithImpl<$Res, Challenge>;
  @useResult
  $Res call({
    String id,
    String userId,
    String title,
    String type,
    String iconPath,
    String status,
    DateTime createdAt,
    double? goalBudget,
    double? progress,
    double? collected,
    DateTime? lastEntry,
    List<ChallengeEntry> entries,
  });
}

/// @nodoc
class _$ChallengeCopyWithImpl<$Res, $Val extends Challenge>
    implements $ChallengeCopyWith<$Res> {
  _$ChallengeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Challenge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? type = null,
    Object? iconPath = null,
    Object? status = null,
    Object? createdAt = null,
    Object? goalBudget = freezed,
    Object? progress = freezed,
    Object? collected = freezed,
    Object? lastEntry = freezed,
    Object? entries = null,
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
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String,
            iconPath:
                null == iconPath
                    ? _value.iconPath
                    : iconPath // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            goalBudget:
                freezed == goalBudget
                    ? _value.goalBudget
                    : goalBudget // ignore: cast_nullable_to_non_nullable
                        as double?,
            progress:
                freezed == progress
                    ? _value.progress
                    : progress // ignore: cast_nullable_to_non_nullable
                        as double?,
            collected:
                freezed == collected
                    ? _value.collected
                    : collected // ignore: cast_nullable_to_non_nullable
                        as double?,
            lastEntry:
                freezed == lastEntry
                    ? _value.lastEntry
                    : lastEntry // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            entries:
                null == entries
                    ? _value.entries
                    : entries // ignore: cast_nullable_to_non_nullable
                        as List<ChallengeEntry>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChallengeImplCopyWith<$Res>
    implements $ChallengeCopyWith<$Res> {
  factory _$$ChallengeImplCopyWith(
    _$ChallengeImpl value,
    $Res Function(_$ChallengeImpl) then,
  ) = __$$ChallengeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String title,
    String type,
    String iconPath,
    String status,
    DateTime createdAt,
    double? goalBudget,
    double? progress,
    double? collected,
    DateTime? lastEntry,
    List<ChallengeEntry> entries,
  });
}

/// @nodoc
class __$$ChallengeImplCopyWithImpl<$Res>
    extends _$ChallengeCopyWithImpl<$Res, _$ChallengeImpl>
    implements _$$ChallengeImplCopyWith<$Res> {
  __$$ChallengeImplCopyWithImpl(
    _$ChallengeImpl _value,
    $Res Function(_$ChallengeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Challenge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? type = null,
    Object? iconPath = null,
    Object? status = null,
    Object? createdAt = null,
    Object? goalBudget = freezed,
    Object? progress = freezed,
    Object? collected = freezed,
    Object? lastEntry = freezed,
    Object? entries = null,
  }) {
    return _then(
      _$ChallengeImpl(
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
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String,
        iconPath:
            null == iconPath
                ? _value.iconPath
                : iconPath // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        goalBudget:
            freezed == goalBudget
                ? _value.goalBudget
                : goalBudget // ignore: cast_nullable_to_non_nullable
                    as double?,
        progress:
            freezed == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                    as double?,
        collected:
            freezed == collected
                ? _value.collected
                : collected // ignore: cast_nullable_to_non_nullable
                    as double?,
        lastEntry:
            freezed == lastEntry
                ? _value.lastEntry
                : lastEntry // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        entries:
            null == entries
                ? _value._entries
                : entries // ignore: cast_nullable_to_non_nullable
                    as List<ChallengeEntry>,
      ),
    );
  }
}

/// @nodoc

class _$ChallengeImpl extends _Challenge {
  const _$ChallengeImpl({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.iconPath,
    required this.status,
    required this.createdAt,
    this.goalBudget,
    this.progress,
    this.collected,
    this.lastEntry,
    final List<ChallengeEntry> entries = const [],
  }) : _entries = entries,
       super._();

  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String type;
  @override
  final String iconPath;
  @override
  final String status;
  @override
  final DateTime createdAt;
  // Financial-only fields
  @override
  final double? goalBudget;
  @override
  final double? progress;
  @override
  final double? collected;
  // Physical-only fields
  @override
  final DateTime? lastEntry;
  final List<ChallengeEntry> _entries;
  @override
  @JsonKey()
  List<ChallengeEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @override
  String toString() {
    return 'Challenge(id: $id, userId: $userId, title: $title, type: $type, iconPath: $iconPath, status: $status, createdAt: $createdAt, goalBudget: $goalBudget, progress: $progress, collected: $collected, lastEntry: $lastEntry, entries: $entries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChallengeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.iconPath, iconPath) ||
                other.iconPath == iconPath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.goalBudget, goalBudget) ||
                other.goalBudget == goalBudget) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.collected, collected) ||
                other.collected == collected) &&
            (identical(other.lastEntry, lastEntry) ||
                other.lastEntry == lastEntry) &&
            const DeepCollectionEquality().equals(other._entries, _entries));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    title,
    type,
    iconPath,
    status,
    createdAt,
    goalBudget,
    progress,
    collected,
    lastEntry,
    const DeepCollectionEquality().hash(_entries),
  );

  /// Create a copy of Challenge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChallengeImplCopyWith<_$ChallengeImpl> get copyWith =>
      __$$ChallengeImplCopyWithImpl<_$ChallengeImpl>(this, _$identity);
}

abstract class _Challenge extends Challenge {
  const factory _Challenge({
    required final String id,
    required final String userId,
    required final String title,
    required final String type,
    required final String iconPath,
    required final String status,
    required final DateTime createdAt,
    final double? goalBudget,
    final double? progress,
    final double? collected,
    final DateTime? lastEntry,
    final List<ChallengeEntry> entries,
  }) = _$ChallengeImpl;
  const _Challenge._() : super._();

  @override
  String get id;
  @override
  String get userId;
  @override
  String get title;
  @override
  String get type;
  @override
  String get iconPath;
  @override
  String get status;
  @override
  DateTime get createdAt; // Financial-only fields
  @override
  double? get goalBudget;
  @override
  double? get progress;
  @override
  double? get collected; // Physical-only fields
  @override
  DateTime? get lastEntry;
  @override
  List<ChallengeEntry> get entries;

  /// Create a copy of Challenge
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChallengeImplCopyWith<_$ChallengeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChallengeState {
  List<Challenge> get challenges => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get hasError => throw _privateConstructorUsedError;

  /// Create a copy of ChallengeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChallengeStateCopyWith<ChallengeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChallengeStateCopyWith<$Res> {
  factory $ChallengeStateCopyWith(
    ChallengeState value,
    $Res Function(ChallengeState) then,
  ) = _$ChallengeStateCopyWithImpl<$Res, ChallengeState>;
  @useResult
  $Res call({List<Challenge> challenges, bool isLoading, bool hasError});
}

/// @nodoc
class _$ChallengeStateCopyWithImpl<$Res, $Val extends ChallengeState>
    implements $ChallengeStateCopyWith<$Res> {
  _$ChallengeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChallengeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? challenges = null,
    Object? isLoading = null,
    Object? hasError = null,
  }) {
    return _then(
      _value.copyWith(
            challenges:
                null == challenges
                    ? _value.challenges
                    : challenges // ignore: cast_nullable_to_non_nullable
                        as List<Challenge>,
            isLoading:
                null == isLoading
                    ? _value.isLoading
                    : isLoading // ignore: cast_nullable_to_non_nullable
                        as bool,
            hasError:
                null == hasError
                    ? _value.hasError
                    : hasError // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChallengeStateImplCopyWith<$Res>
    implements $ChallengeStateCopyWith<$Res> {
  factory _$$ChallengeStateImplCopyWith(
    _$ChallengeStateImpl value,
    $Res Function(_$ChallengeStateImpl) then,
  ) = __$$ChallengeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Challenge> challenges, bool isLoading, bool hasError});
}

/// @nodoc
class __$$ChallengeStateImplCopyWithImpl<$Res>
    extends _$ChallengeStateCopyWithImpl<$Res, _$ChallengeStateImpl>
    implements _$$ChallengeStateImplCopyWith<$Res> {
  __$$ChallengeStateImplCopyWithImpl(
    _$ChallengeStateImpl _value,
    $Res Function(_$ChallengeStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChallengeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? challenges = null,
    Object? isLoading = null,
    Object? hasError = null,
  }) {
    return _then(
      _$ChallengeStateImpl(
        challenges:
            null == challenges
                ? _value._challenges
                : challenges // ignore: cast_nullable_to_non_nullable
                    as List<Challenge>,
        isLoading:
            null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                    as bool,
        hasError:
            null == hasError
                ? _value.hasError
                : hasError // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$ChallengeStateImpl extends _ChallengeState {
  const _$ChallengeStateImpl({
    final List<Challenge> challenges = const [],
    this.isLoading = false,
    this.hasError = false,
  }) : _challenges = challenges,
       super._();

  final List<Challenge> _challenges;
  @override
  @JsonKey()
  List<Challenge> get challenges {
    if (_challenges is EqualUnmodifiableListView) return _challenges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_challenges);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool hasError;

  @override
  String toString() {
    return 'ChallengeState(challenges: $challenges, isLoading: $isLoading, hasError: $hasError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChallengeStateImpl &&
            const DeepCollectionEquality().equals(
              other._challenges,
              _challenges,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasError, hasError) ||
                other.hasError == hasError));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_challenges),
    isLoading,
    hasError,
  );

  /// Create a copy of ChallengeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChallengeStateImplCopyWith<_$ChallengeStateImpl> get copyWith =>
      __$$ChallengeStateImplCopyWithImpl<_$ChallengeStateImpl>(
        this,
        _$identity,
      );
}

abstract class _ChallengeState extends ChallengeState {
  const factory _ChallengeState({
    final List<Challenge> challenges,
    final bool isLoading,
    final bool hasError,
  }) = _$ChallengeStateImpl;
  const _ChallengeState._() : super._();

  @override
  List<Challenge> get challenges;
  @override
  bool get isLoading;
  @override
  bool get hasError;

  /// Create a copy of ChallengeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChallengeStateImplCopyWith<_$ChallengeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

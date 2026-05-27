// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'milestone_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Milestone {
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  bool get completed => throw _privateConstructorUsedError;
  bool get isEligible => throw _privateConstructorUsedError;

  /// Create a copy of Milestone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MilestoneCopyWith<Milestone> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MilestoneCopyWith<$Res> {
  factory $MilestoneCopyWith(Milestone value, $Res Function(Milestone) then) =
      _$MilestoneCopyWithImpl<$Res, Milestone>;
  @useResult
  $Res call({
    String title,
    String description,
    DateTime date,
    bool completed,
    bool isEligible,
  });
}

/// @nodoc
class _$MilestoneCopyWithImpl<$Res, $Val extends Milestone>
    implements $MilestoneCopyWith<$Res> {
  _$MilestoneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Milestone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? date = null,
    Object? completed = null,
    Object? isEligible = null,
  }) {
    return _then(
      _value.copyWith(
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            date:
                null == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            completed:
                null == completed
                    ? _value.completed
                    : completed // ignore: cast_nullable_to_non_nullable
                        as bool,
            isEligible:
                null == isEligible
                    ? _value.isEligible
                    : isEligible // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MilestoneImplCopyWith<$Res>
    implements $MilestoneCopyWith<$Res> {
  factory _$$MilestoneImplCopyWith(
    _$MilestoneImpl value,
    $Res Function(_$MilestoneImpl) then,
  ) = __$$MilestoneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String description,
    DateTime date,
    bool completed,
    bool isEligible,
  });
}

/// @nodoc
class __$$MilestoneImplCopyWithImpl<$Res>
    extends _$MilestoneCopyWithImpl<$Res, _$MilestoneImpl>
    implements _$$MilestoneImplCopyWith<$Res> {
  __$$MilestoneImplCopyWithImpl(
    _$MilestoneImpl _value,
    $Res Function(_$MilestoneImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Milestone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? date = null,
    Object? completed = null,
    Object? isEligible = null,
  }) {
    return _then(
      _$MilestoneImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        date:
            null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        completed:
            null == completed
                ? _value.completed
                : completed // ignore: cast_nullable_to_non_nullable
                    as bool,
        isEligible:
            null == isEligible
                ? _value.isEligible
                : isEligible // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$MilestoneImpl with DiagnosticableTreeMixin implements _Milestone {
  const _$MilestoneImpl({
    required this.title,
    required this.description,
    required this.date,
    required this.completed,
    this.isEligible = false,
  });

  @override
  final String title;
  @override
  final String description;
  @override
  final DateTime date;
  @override
  final bool completed;
  @override
  @JsonKey()
  final bool isEligible;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Milestone(title: $title, description: $description, date: $date, completed: $completed, isEligible: $isEligible)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Milestone'))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('date', date))
      ..add(DiagnosticsProperty('completed', completed))
      ..add(DiagnosticsProperty('isEligible', isEligible));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MilestoneImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.isEligible, isEligible) ||
                other.isEligible == isEligible));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, title, description, date, completed, isEligible);

  /// Create a copy of Milestone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MilestoneImplCopyWith<_$MilestoneImpl> get copyWith =>
      __$$MilestoneImplCopyWithImpl<_$MilestoneImpl>(this, _$identity);
}

abstract class _Milestone implements Milestone {
  const factory _Milestone({
    required final String title,
    required final String description,
    required final DateTime date,
    required final bool completed,
    final bool isEligible,
  }) = _$MilestoneImpl;

  @override
  String get title;
  @override
  String get description;
  @override
  DateTime get date;
  @override
  bool get completed;
  @override
  bool get isEligible;

  /// Create a copy of Milestone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MilestoneImplCopyWith<_$MilestoneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MilestoneState {
  DateTime get startDate => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  List<Milestone> get allMilestones => throw _privateConstructorUsedError;
  Set<String> get completedTitles => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get hasError => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of MilestoneState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MilestoneStateCopyWith<MilestoneState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MilestoneStateCopyWith<$Res> {
  factory $MilestoneStateCopyWith(
    MilestoneState value,
    $Res Function(MilestoneState) then,
  ) = _$MilestoneStateCopyWithImpl<$Res, MilestoneState>;
  @useResult
  $Res call({
    DateTime startDate,
    String userId,
    List<Milestone> allMilestones,
    Set<String> completedTitles,
    bool isLoading,
    bool hasError,
    String? errorMessage,
  });
}

/// @nodoc
class _$MilestoneStateCopyWithImpl<$Res, $Val extends MilestoneState>
    implements $MilestoneStateCopyWith<$Res> {
  _$MilestoneStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MilestoneState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startDate = null,
    Object? userId = null,
    Object? allMilestones = null,
    Object? completedTitles = null,
    Object? isLoading = null,
    Object? hasError = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            startDate:
                null == startDate
                    ? _value.startDate
                    : startDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            allMilestones:
                null == allMilestones
                    ? _value.allMilestones
                    : allMilestones // ignore: cast_nullable_to_non_nullable
                        as List<Milestone>,
            completedTitles:
                null == completedTitles
                    ? _value.completedTitles
                    : completedTitles // ignore: cast_nullable_to_non_nullable
                        as Set<String>,
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
            errorMessage:
                freezed == errorMessage
                    ? _value.errorMessage
                    : errorMessage // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MilestoneStateImplCopyWith<$Res>
    implements $MilestoneStateCopyWith<$Res> {
  factory _$$MilestoneStateImplCopyWith(
    _$MilestoneStateImpl value,
    $Res Function(_$MilestoneStateImpl) then,
  ) = __$$MilestoneStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime startDate,
    String userId,
    List<Milestone> allMilestones,
    Set<String> completedTitles,
    bool isLoading,
    bool hasError,
    String? errorMessage,
  });
}

/// @nodoc
class __$$MilestoneStateImplCopyWithImpl<$Res>
    extends _$MilestoneStateCopyWithImpl<$Res, _$MilestoneStateImpl>
    implements _$$MilestoneStateImplCopyWith<$Res> {
  __$$MilestoneStateImplCopyWithImpl(
    _$MilestoneStateImpl _value,
    $Res Function(_$MilestoneStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MilestoneState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startDate = null,
    Object? userId = null,
    Object? allMilestones = null,
    Object? completedTitles = null,
    Object? isLoading = null,
    Object? hasError = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$MilestoneStateImpl(
        startDate:
            null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        allMilestones:
            null == allMilestones
                ? _value._allMilestones
                : allMilestones // ignore: cast_nullable_to_non_nullable
                    as List<Milestone>,
        completedTitles:
            null == completedTitles
                ? _value._completedTitles
                : completedTitles // ignore: cast_nullable_to_non_nullable
                    as Set<String>,
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
        errorMessage:
            freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

class _$MilestoneStateImpl extends _MilestoneState
    with DiagnosticableTreeMixin {
  const _$MilestoneStateImpl({
    required this.startDate,
    required this.userId,
    final List<Milestone> allMilestones = const [],
    final Set<String> completedTitles = const <String>{},
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  }) : _allMilestones = allMilestones,
       _completedTitles = completedTitles,
       super._();

  @override
  final DateTime startDate;
  @override
  final String userId;
  final List<Milestone> _allMilestones;
  @override
  @JsonKey()
  List<Milestone> get allMilestones {
    if (_allMilestones is EqualUnmodifiableListView) return _allMilestones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allMilestones);
  }

  final Set<String> _completedTitles;
  @override
  @JsonKey()
  Set<String> get completedTitles {
    if (_completedTitles is EqualUnmodifiableSetView) return _completedTitles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_completedTitles);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool hasError;
  @override
  final String? errorMessage;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MilestoneState(startDate: $startDate, userId: $userId, allMilestones: $allMilestones, completedTitles: $completedTitles, isLoading: $isLoading, hasError: $hasError, errorMessage: $errorMessage)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'MilestoneState'))
      ..add(DiagnosticsProperty('startDate', startDate))
      ..add(DiagnosticsProperty('userId', userId))
      ..add(DiagnosticsProperty('allMilestones', allMilestones))
      ..add(DiagnosticsProperty('completedTitles', completedTitles))
      ..add(DiagnosticsProperty('isLoading', isLoading))
      ..add(DiagnosticsProperty('hasError', hasError))
      ..add(DiagnosticsProperty('errorMessage', errorMessage));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MilestoneStateImpl &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(
              other._allMilestones,
              _allMilestones,
            ) &&
            const DeepCollectionEquality().equals(
              other._completedTitles,
              _completedTitles,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasError, hasError) ||
                other.hasError == hasError) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    startDate,
    userId,
    const DeepCollectionEquality().hash(_allMilestones),
    const DeepCollectionEquality().hash(_completedTitles),
    isLoading,
    hasError,
    errorMessage,
  );

  /// Create a copy of MilestoneState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MilestoneStateImplCopyWith<_$MilestoneStateImpl> get copyWith =>
      __$$MilestoneStateImplCopyWithImpl<_$MilestoneStateImpl>(
        this,
        _$identity,
      );
}

abstract class _MilestoneState extends MilestoneState {
  const factory _MilestoneState({
    required final DateTime startDate,
    required final String userId,
    final List<Milestone> allMilestones,
    final Set<String> completedTitles,
    final bool isLoading,
    final bool hasError,
    final String? errorMessage,
  }) = _$MilestoneStateImpl;
  const _MilestoneState._() : super._();

  @override
  DateTime get startDate;
  @override
  String get userId;
  @override
  List<Milestone> get allMilestones;
  @override
  Set<String> get completedTitles;
  @override
  bool get isLoading;
  @override
  bool get hasError;
  @override
  String? get errorMessage;

  /// Create a copy of MilestoneState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MilestoneStateImplCopyWith<_$MilestoneStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'motivation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MotivationState {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get motivationText => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;

  /// Create a copy of MotivationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MotivationStateCopyWith<MotivationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MotivationStateCopyWith<$Res> {
  factory $MotivationStateCopyWith(
    MotivationState value,
    $Res Function(MotivationState) then,
  ) = _$MotivationStateCopyWithImpl<$Res, MotivationState>;
  @useResult
  $Res call({
    String id,
    String userId,
    String motivationText,
    DateTime createdAt,
    bool isPinned,
    String color,
    String icon,
  });
}

/// @nodoc
class _$MotivationStateCopyWithImpl<$Res, $Val extends MotivationState>
    implements $MotivationStateCopyWith<$Res> {
  _$MotivationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MotivationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? motivationText = null,
    Object? createdAt = null,
    Object? isPinned = null,
    Object? color = null,
    Object? icon = null,
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
            motivationText:
                null == motivationText
                    ? _value.motivationText
                    : motivationText // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            isPinned:
                null == isPinned
                    ? _value.isPinned
                    : isPinned // ignore: cast_nullable_to_non_nullable
                        as bool,
            color:
                null == color
                    ? _value.color
                    : color // ignore: cast_nullable_to_non_nullable
                        as String,
            icon:
                null == icon
                    ? _value.icon
                    : icon // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MotivationStateImplCopyWith<$Res>
    implements $MotivationStateCopyWith<$Res> {
  factory _$$MotivationStateImplCopyWith(
    _$MotivationStateImpl value,
    $Res Function(_$MotivationStateImpl) then,
  ) = __$$MotivationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String motivationText,
    DateTime createdAt,
    bool isPinned,
    String color,
    String icon,
  });
}

/// @nodoc
class __$$MotivationStateImplCopyWithImpl<$Res>
    extends _$MotivationStateCopyWithImpl<$Res, _$MotivationStateImpl>
    implements _$$MotivationStateImplCopyWith<$Res> {
  __$$MotivationStateImplCopyWithImpl(
    _$MotivationStateImpl _value,
    $Res Function(_$MotivationStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MotivationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? motivationText = null,
    Object? createdAt = null,
    Object? isPinned = null,
    Object? color = null,
    Object? icon = null,
  }) {
    return _then(
      _$MotivationStateImpl(
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
        motivationText:
            null == motivationText
                ? _value.motivationText
                : motivationText // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        isPinned:
            null == isPinned
                ? _value.isPinned
                : isPinned // ignore: cast_nullable_to_non_nullable
                    as bool,
        color:
            null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                    as String,
        icon:
            null == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc

class _$MotivationStateImpl implements _MotivationState {
  const _$MotivationStateImpl({
    required this.id,
    required this.userId,
    required this.motivationText,
    required this.createdAt,
    this.isPinned = false,
    this.color = '#48CAE4',
    this.icon = 'goal',
  });

  @override
  final String id;
  @override
  final String userId;
  @override
  final String motivationText;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final bool isPinned;
  @override
  @JsonKey()
  final String color;
  @override
  @JsonKey()
  final String icon;

  @override
  String toString() {
    return 'MotivationState(id: $id, userId: $userId, motivationText: $motivationText, createdAt: $createdAt, isPinned: $isPinned, color: $color, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MotivationStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.motivationText, motivationText) ||
                other.motivationText == motivationText) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    motivationText,
    createdAt,
    isPinned,
    color,
    icon,
  );

  /// Create a copy of MotivationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MotivationStateImplCopyWith<_$MotivationStateImpl> get copyWith =>
      __$$MotivationStateImplCopyWithImpl<_$MotivationStateImpl>(
        this,
        _$identity,
      );
}

abstract class _MotivationState implements MotivationState {
  const factory _MotivationState({
    required final String id,
    required final String userId,
    required final String motivationText,
    required final DateTime createdAt,
    final bool isPinned,
    final String color,
    final String icon,
  }) = _$MotivationStateImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get motivationText;
  @override
  DateTime get createdAt;
  @override
  bool get isPinned;
  @override
  String get color;
  @override
  String get icon;

  /// Create a copy of MotivationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MotivationStateImplCopyWith<_$MotivationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MotivationsListState {
  List<MotivationState> get motivations => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get hasError => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of MotivationsListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MotivationsListStateCopyWith<MotivationsListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MotivationsListStateCopyWith<$Res> {
  factory $MotivationsListStateCopyWith(
    MotivationsListState value,
    $Res Function(MotivationsListState) then,
  ) = _$MotivationsListStateCopyWithImpl<$Res, MotivationsListState>;
  @useResult
  $Res call({
    List<MotivationState> motivations,
    bool isLoading,
    bool hasError,
    String? errorMessage,
  });
}

/// @nodoc
class _$MotivationsListStateCopyWithImpl<
  $Res,
  $Val extends MotivationsListState
>
    implements $MotivationsListStateCopyWith<$Res> {
  _$MotivationsListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MotivationsListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? motivations = null,
    Object? isLoading = null,
    Object? hasError = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            motivations:
                null == motivations
                    ? _value.motivations
                    : motivations // ignore: cast_nullable_to_non_nullable
                        as List<MotivationState>,
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
abstract class _$$MotivationsListStateImplCopyWith<$Res>
    implements $MotivationsListStateCopyWith<$Res> {
  factory _$$MotivationsListStateImplCopyWith(
    _$MotivationsListStateImpl value,
    $Res Function(_$MotivationsListStateImpl) then,
  ) = __$$MotivationsListStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<MotivationState> motivations,
    bool isLoading,
    bool hasError,
    String? errorMessage,
  });
}

/// @nodoc
class __$$MotivationsListStateImplCopyWithImpl<$Res>
    extends _$MotivationsListStateCopyWithImpl<$Res, _$MotivationsListStateImpl>
    implements _$$MotivationsListStateImplCopyWith<$Res> {
  __$$MotivationsListStateImplCopyWithImpl(
    _$MotivationsListStateImpl _value,
    $Res Function(_$MotivationsListStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MotivationsListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? motivations = null,
    Object? isLoading = null,
    Object? hasError = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$MotivationsListStateImpl(
        motivations:
            null == motivations
                ? _value._motivations
                : motivations // ignore: cast_nullable_to_non_nullable
                    as List<MotivationState>,
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

class _$MotivationsListStateImpl implements _MotivationsListState {
  const _$MotivationsListStateImpl({
    final List<MotivationState> motivations = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  }) : _motivations = motivations;

  final List<MotivationState> _motivations;
  @override
  @JsonKey()
  List<MotivationState> get motivations {
    if (_motivations is EqualUnmodifiableListView) return _motivations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_motivations);
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
  String toString() {
    return 'MotivationsListState(motivations: $motivations, isLoading: $isLoading, hasError: $hasError, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MotivationsListStateImpl &&
            const DeepCollectionEquality().equals(
              other._motivations,
              _motivations,
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
    const DeepCollectionEquality().hash(_motivations),
    isLoading,
    hasError,
    errorMessage,
  );

  /// Create a copy of MotivationsListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MotivationsListStateImplCopyWith<_$MotivationsListStateImpl>
  get copyWith =>
      __$$MotivationsListStateImplCopyWithImpl<_$MotivationsListStateImpl>(
        this,
        _$identity,
      );
}

abstract class _MotivationsListState implements MotivationsListState {
  const factory _MotivationsListState({
    final List<MotivationState> motivations,
    final bool isLoading,
    final bool hasError,
    final String? errorMessage,
  }) = _$MotivationsListStateImpl;

  @override
  List<MotivationState> get motivations;
  @override
  bool get isLoading;
  @override
  bool get hasError;
  @override
  String? get errorMessage;

  /// Create a copy of MotivationsListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MotivationsListStateImplCopyWith<_$MotivationsListStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}

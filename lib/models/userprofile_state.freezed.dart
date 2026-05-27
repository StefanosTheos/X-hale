// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'userprofile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserProfile {
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get avatarPath => throw _privateConstructorUsedError;
  DateTime get quitDate => throw _privateConstructorUsedError;
  int get achievementsCount => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
    UserProfile value,
    $Res Function(UserProfile) then,
  ) = _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call({
    String userId,
    String name,
    String avatarPath,
    DateTime quitDate,
    int achievementsCount,
  });
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? name = null,
    Object? avatarPath = null,
    Object? quitDate = null,
    Object? achievementsCount = null,
  }) {
    return _then(
      _value.copyWith(
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            avatarPath:
                null == avatarPath
                    ? _value.avatarPath
                    : avatarPath // ignore: cast_nullable_to_non_nullable
                        as String,
            quitDate:
                null == quitDate
                    ? _value.quitDate
                    : quitDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            achievementsCount:
                null == achievementsCount
                    ? _value.achievementsCount
                    : achievementsCount // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
    _$UserProfileImpl value,
    $Res Function(_$UserProfileImpl) then,
  ) = __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String name,
    String avatarPath,
    DateTime quitDate,
    int achievementsCount,
  });
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
    _$UserProfileImpl _value,
    $Res Function(_$UserProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? name = null,
    Object? avatarPath = null,
    Object? quitDate = null,
    Object? achievementsCount = null,
  }) {
    return _then(
      _$UserProfileImpl(
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        avatarPath:
            null == avatarPath
                ? _value.avatarPath
                : avatarPath // ignore: cast_nullable_to_non_nullable
                    as String,
        quitDate:
            null == quitDate
                ? _value.quitDate
                : quitDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        achievementsCount:
            null == achievementsCount
                ? _value.achievementsCount
                : achievementsCount // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc

class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl({
    required this.userId,
    required this.name,
    required this.avatarPath,
    required this.quitDate,
    this.achievementsCount = 0,
  });

  @override
  final String userId;
  @override
  final String name;
  @override
  final String avatarPath;
  @override
  final DateTime quitDate;
  @override
  @JsonKey()
  final int achievementsCount;

  @override
  String toString() {
    return 'UserProfile(userId: $userId, name: $name, avatarPath: $avatarPath, quitDate: $quitDate, achievementsCount: $achievementsCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatarPath, avatarPath) ||
                other.avatarPath == avatarPath) &&
            (identical(other.quitDate, quitDate) ||
                other.quitDate == quitDate) &&
            (identical(other.achievementsCount, achievementsCount) ||
                other.achievementsCount == achievementsCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    name,
    avatarPath,
    quitDate,
    achievementsCount,
  );

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile({
    required final String userId,
    required final String name,
    required final String avatarPath,
    required final DateTime quitDate,
    final int achievementsCount,
  }) = _$UserProfileImpl;

  @override
  String get userId;
  @override
  String get name;
  @override
  String get avatarPath;
  @override
  DateTime get quitDate;
  @override
  int get achievementsCount;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forum_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ForumPost {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get userAvatar => throw _privateConstructorUsedError;

  /// Create a copy of ForumPost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ForumPostCopyWith<ForumPost> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ForumPostCopyWith<$Res> {
  factory $ForumPostCopyWith(ForumPost value, $Res Function(ForumPost) then) =
      _$ForumPostCopyWithImpl<$Res, ForumPost>;
  @useResult
  $Res call({
    String id,
    String userId,
    String username,
    String message,
    DateTime createdAt,
    String userAvatar,
  });
}

/// @nodoc
class _$ForumPostCopyWithImpl<$Res, $Val extends ForumPost>
    implements $ForumPostCopyWith<$Res> {
  _$ForumPostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ForumPost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? username = null,
    Object? message = null,
    Object? createdAt = null,
    Object? userAvatar = null,
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
            username:
                null == username
                    ? _value.username
                    : username // ignore: cast_nullable_to_non_nullable
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
            userAvatar:
                null == userAvatar
                    ? _value.userAvatar
                    : userAvatar // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ForumPostImplCopyWith<$Res>
    implements $ForumPostCopyWith<$Res> {
  factory _$$ForumPostImplCopyWith(
    _$ForumPostImpl value,
    $Res Function(_$ForumPostImpl) then,
  ) = __$$ForumPostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String username,
    String message,
    DateTime createdAt,
    String userAvatar,
  });
}

/// @nodoc
class __$$ForumPostImplCopyWithImpl<$Res>
    extends _$ForumPostCopyWithImpl<$Res, _$ForumPostImpl>
    implements _$$ForumPostImplCopyWith<$Res> {
  __$$ForumPostImplCopyWithImpl(
    _$ForumPostImpl _value,
    $Res Function(_$ForumPostImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ForumPost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? username = null,
    Object? message = null,
    Object? createdAt = null,
    Object? userAvatar = null,
  }) {
    return _then(
      _$ForumPostImpl(
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
        username:
            null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
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
        userAvatar:
            null == userAvatar
                ? _value.userAvatar
                : userAvatar // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc

class _$ForumPostImpl implements _ForumPost {
  const _$ForumPostImpl({
    required this.id,
    required this.userId,
    required this.username,
    required this.message,
    required this.createdAt,
    required this.userAvatar,
  });

  @override
  final String id;
  @override
  final String userId;
  @override
  final String username;
  @override
  final String message;
  @override
  final DateTime createdAt;
  @override
  final String userAvatar;

  @override
  String toString() {
    return 'ForumPost(id: $id, userId: $userId, username: $username, message: $message, createdAt: $createdAt, userAvatar: $userAvatar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ForumPostImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.userAvatar, userAvatar) ||
                other.userAvatar == userAvatar));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    username,
    message,
    createdAt,
    userAvatar,
  );

  /// Create a copy of ForumPost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ForumPostImplCopyWith<_$ForumPostImpl> get copyWith =>
      __$$ForumPostImplCopyWithImpl<_$ForumPostImpl>(this, _$identity);
}

abstract class _ForumPost implements ForumPost {
  const factory _ForumPost({
    required final String id,
    required final String userId,
    required final String username,
    required final String message,
    required final DateTime createdAt,
    required final String userAvatar,
  }) = _$ForumPostImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get username;
  @override
  String get message;
  @override
  DateTime get createdAt;
  @override
  String get userAvatar;

  /// Create a copy of ForumPost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ForumPostImplCopyWith<_$ForumPostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ForumPostState {
  List<ForumPost> get posts => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isLoadingMore => throw _privateConstructorUsedError;
  bool get hasError => throw _privateConstructorUsedError;

  /// Create a copy of ForumPostState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ForumPostStateCopyWith<ForumPostState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ForumPostStateCopyWith<$Res> {
  factory $ForumPostStateCopyWith(
    ForumPostState value,
    $Res Function(ForumPostState) then,
  ) = _$ForumPostStateCopyWithImpl<$Res, ForumPostState>;
  @useResult
  $Res call({
    List<ForumPost> posts,
    bool isLoading,
    bool isLoadingMore,
    bool hasError,
  });
}

/// @nodoc
class _$ForumPostStateCopyWithImpl<$Res, $Val extends ForumPostState>
    implements $ForumPostStateCopyWith<$Res> {
  _$ForumPostStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ForumPostState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasError = null,
  }) {
    return _then(
      _value.copyWith(
            posts:
                null == posts
                    ? _value.posts
                    : posts // ignore: cast_nullable_to_non_nullable
                        as List<ForumPost>,
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ForumPostStateImplCopyWith<$Res>
    implements $ForumPostStateCopyWith<$Res> {
  factory _$$ForumPostStateImplCopyWith(
    _$ForumPostStateImpl value,
    $Res Function(_$ForumPostStateImpl) then,
  ) = __$$ForumPostStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<ForumPost> posts,
    bool isLoading,
    bool isLoadingMore,
    bool hasError,
  });
}

/// @nodoc
class __$$ForumPostStateImplCopyWithImpl<$Res>
    extends _$ForumPostStateCopyWithImpl<$Res, _$ForumPostStateImpl>
    implements _$$ForumPostStateImplCopyWith<$Res> {
  __$$ForumPostStateImplCopyWithImpl(
    _$ForumPostStateImpl _value,
    $Res Function(_$ForumPostStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ForumPostState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasError = null,
  }) {
    return _then(
      _$ForumPostStateImpl(
        posts:
            null == posts
                ? _value._posts
                : posts // ignore: cast_nullable_to_non_nullable
                    as List<ForumPost>,
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
      ),
    );
  }
}

/// @nodoc

class _$ForumPostStateImpl extends _ForumPostState {
  const _$ForumPostStateImpl({
    final List<ForumPost> posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasError = false,
  }) : _posts = posts,
       super._();

  final List<ForumPost> _posts;
  @override
  @JsonKey()
  List<ForumPost> get posts {
    if (_posts is EqualUnmodifiableListView) return _posts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_posts);
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
  String toString() {
    return 'ForumPostState(posts: $posts, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasError: $hasError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ForumPostStateImpl &&
            const DeepCollectionEquality().equals(other._posts, _posts) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.hasError, hasError) ||
                other.hasError == hasError));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_posts),
    isLoading,
    isLoadingMore,
    hasError,
  );

  /// Create a copy of ForumPostState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ForumPostStateImplCopyWith<_$ForumPostStateImpl> get copyWith =>
      __$$ForumPostStateImplCopyWithImpl<_$ForumPostStateImpl>(
        this,
        _$identity,
      );
}

abstract class _ForumPostState extends ForumPostState {
  const factory _ForumPostState({
    final List<ForumPost> posts,
    final bool isLoading,
    final bool isLoadingMore,
    final bool hasError,
  }) = _$ForumPostStateImpl;
  const _ForumPostState._() : super._();

  @override
  List<ForumPost> get posts;
  @override
  bool get isLoading;
  @override
  bool get isLoadingMore;
  @override
  bool get hasError;

  /// Create a copy of ForumPostState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ForumPostStateImplCopyWith<_$ForumPostStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

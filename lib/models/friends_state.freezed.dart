// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friends_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$FriendRequest {
  String get requestId => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get receiverId => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'pending', 'accepted', 'declined'
  DateTime get sentAt => throw _privateConstructorUsedError;

  /// Create a copy of FriendRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendRequestCopyWith<FriendRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendRequestCopyWith<$Res> {
  factory $FriendRequestCopyWith(
    FriendRequest value,
    $Res Function(FriendRequest) then,
  ) = _$FriendRequestCopyWithImpl<$Res, FriendRequest>;
  @useResult
  $Res call({
    String requestId,
    String senderId,
    String receiverId,
    String status,
    DateTime sentAt,
  });
}

/// @nodoc
class _$FriendRequestCopyWithImpl<$Res, $Val extends FriendRequest>
    implements $FriendRequestCopyWith<$Res> {
  _$FriendRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FriendRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? senderId = null,
    Object? receiverId = null,
    Object? status = null,
    Object? sentAt = null,
  }) {
    return _then(
      _value.copyWith(
            requestId:
                null == requestId
                    ? _value.requestId
                    : requestId // ignore: cast_nullable_to_non_nullable
                        as String,
            senderId:
                null == senderId
                    ? _value.senderId
                    : senderId // ignore: cast_nullable_to_non_nullable
                        as String,
            receiverId:
                null == receiverId
                    ? _value.receiverId
                    : receiverId // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            sentAt:
                null == sentAt
                    ? _value.sentAt
                    : sentAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FriendRequestImplCopyWith<$Res>
    implements $FriendRequestCopyWith<$Res> {
  factory _$$FriendRequestImplCopyWith(
    _$FriendRequestImpl value,
    $Res Function(_$FriendRequestImpl) then,
  ) = __$$FriendRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String requestId,
    String senderId,
    String receiverId,
    String status,
    DateTime sentAt,
  });
}

/// @nodoc
class __$$FriendRequestImplCopyWithImpl<$Res>
    extends _$FriendRequestCopyWithImpl<$Res, _$FriendRequestImpl>
    implements _$$FriendRequestImplCopyWith<$Res> {
  __$$FriendRequestImplCopyWithImpl(
    _$FriendRequestImpl _value,
    $Res Function(_$FriendRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FriendRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? senderId = null,
    Object? receiverId = null,
    Object? status = null,
    Object? sentAt = null,
  }) {
    return _then(
      _$FriendRequestImpl(
        requestId:
            null == requestId
                ? _value.requestId
                : requestId // ignore: cast_nullable_to_non_nullable
                    as String,
        senderId:
            null == senderId
                ? _value.senderId
                : senderId // ignore: cast_nullable_to_non_nullable
                    as String,
        receiverId:
            null == receiverId
                ? _value.receiverId
                : receiverId // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        sentAt:
            null == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$FriendRequestImpl
    with DiagnosticableTreeMixin
    implements _FriendRequest {
  const _$FriendRequestImpl({
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.sentAt,
  });

  @override
  final String requestId;
  @override
  final String senderId;
  @override
  final String receiverId;
  @override
  final String status;
  // 'pending', 'accepted', 'declined'
  @override
  final DateTime sentAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FriendRequest(requestId: $requestId, senderId: $senderId, receiverId: $receiverId, status: $status, sentAt: $sentAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'FriendRequest'))
      ..add(DiagnosticsProperty('requestId', requestId))
      ..add(DiagnosticsProperty('senderId', senderId))
      ..add(DiagnosticsProperty('receiverId', receiverId))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('sentAt', sentAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendRequestImpl &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.receiverId, receiverId) ||
                other.receiverId == receiverId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, requestId, senderId, receiverId, status, sentAt);

  /// Create a copy of FriendRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendRequestImplCopyWith<_$FriendRequestImpl> get copyWith =>
      __$$FriendRequestImplCopyWithImpl<_$FriendRequestImpl>(this, _$identity);
}

abstract class _FriendRequest implements FriendRequest {
  const factory _FriendRequest({
    required final String requestId,
    required final String senderId,
    required final String receiverId,
    required final String status,
    required final DateTime sentAt,
  }) = _$FriendRequestImpl;

  @override
  String get requestId;
  @override
  String get senderId;
  @override
  String get receiverId;
  @override
  String get status; // 'pending', 'accepted', 'declined'
  @override
  DateTime get sentAt;

  /// Create a copy of FriendRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendRequestImplCopyWith<_$FriendRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Friendship {
  String get friendshipId => throw _privateConstructorUsedError;
  String get user1Id => throw _privateConstructorUsedError;
  String get user2Id => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendshipCopyWith<Friendship> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendshipCopyWith<$Res> {
  factory $FriendshipCopyWith(
    Friendship value,
    $Res Function(Friendship) then,
  ) = _$FriendshipCopyWithImpl<$Res, Friendship>;
  @useResult
  $Res call({
    String friendshipId,
    String user1Id,
    String user2Id,
    DateTime createdAt,
  });
}

/// @nodoc
class _$FriendshipCopyWithImpl<$Res, $Val extends Friendship>
    implements $FriendshipCopyWith<$Res> {
  _$FriendshipCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendshipId = null,
    Object? user1Id = null,
    Object? user2Id = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            friendshipId:
                null == friendshipId
                    ? _value.friendshipId
                    : friendshipId // ignore: cast_nullable_to_non_nullable
                        as String,
            user1Id:
                null == user1Id
                    ? _value.user1Id
                    : user1Id // ignore: cast_nullable_to_non_nullable
                        as String,
            user2Id:
                null == user2Id
                    ? _value.user2Id
                    : user2Id // ignore: cast_nullable_to_non_nullable
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
abstract class _$$FriendshipImplCopyWith<$Res>
    implements $FriendshipCopyWith<$Res> {
  factory _$$FriendshipImplCopyWith(
    _$FriendshipImpl value,
    $Res Function(_$FriendshipImpl) then,
  ) = __$$FriendshipImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String friendshipId,
    String user1Id,
    String user2Id,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$FriendshipImplCopyWithImpl<$Res>
    extends _$FriendshipCopyWithImpl<$Res, _$FriendshipImpl>
    implements _$$FriendshipImplCopyWith<$Res> {
  __$$FriendshipImplCopyWithImpl(
    _$FriendshipImpl _value,
    $Res Function(_$FriendshipImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendshipId = null,
    Object? user1Id = null,
    Object? user2Id = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$FriendshipImpl(
        friendshipId:
            null == friendshipId
                ? _value.friendshipId
                : friendshipId // ignore: cast_nullable_to_non_nullable
                    as String,
        user1Id:
            null == user1Id
                ? _value.user1Id
                : user1Id // ignore: cast_nullable_to_non_nullable
                    as String,
        user2Id:
            null == user2Id
                ? _value.user2Id
                : user2Id // ignore: cast_nullable_to_non_nullable
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

class _$FriendshipImpl with DiagnosticableTreeMixin implements _Friendship {
  const _$FriendshipImpl({
    required this.friendshipId,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
  });

  @override
  final String friendshipId;
  @override
  final String user1Id;
  @override
  final String user2Id;
  @override
  final DateTime createdAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Friendship(friendshipId: $friendshipId, user1Id: $user1Id, user2Id: $user2Id, createdAt: $createdAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Friendship'))
      ..add(DiagnosticsProperty('friendshipId', friendshipId))
      ..add(DiagnosticsProperty('user1Id', user1Id))
      ..add(DiagnosticsProperty('user2Id', user2Id))
      ..add(DiagnosticsProperty('createdAt', createdAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendshipImpl &&
            (identical(other.friendshipId, friendshipId) ||
                other.friendshipId == friendshipId) &&
            (identical(other.user1Id, user1Id) || other.user1Id == user1Id) &&
            (identical(other.user2Id, user2Id) || other.user2Id == user2Id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, friendshipId, user1Id, user2Id, createdAt);

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendshipImplCopyWith<_$FriendshipImpl> get copyWith =>
      __$$FriendshipImplCopyWithImpl<_$FriendshipImpl>(this, _$identity);
}

abstract class _Friendship implements Friendship {
  const factory _Friendship({
    required final String friendshipId,
    required final String user1Id,
    required final String user2Id,
    required final DateTime createdAt,
  }) = _$FriendshipImpl;

  @override
  String get friendshipId;
  @override
  String get user1Id;
  @override
  String get user2Id;
  @override
  DateTime get createdAt;

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendshipImplCopyWith<_$FriendshipImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Message {
  String get messageId => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get receiverId => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime get sentAt => throw _privateConstructorUsedError;
  bool get read => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call({
    String messageId,
    String senderId,
    String receiverId,
    String message,
    DateTime sentAt,
    bool read,
  });
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? senderId = null,
    Object? receiverId = null,
    Object? message = null,
    Object? sentAt = null,
    Object? read = null,
  }) {
    return _then(
      _value.copyWith(
            messageId:
                null == messageId
                    ? _value.messageId
                    : messageId // ignore: cast_nullable_to_non_nullable
                        as String,
            senderId:
                null == senderId
                    ? _value.senderId
                    : senderId // ignore: cast_nullable_to_non_nullable
                        as String,
            receiverId:
                null == receiverId
                    ? _value.receiverId
                    : receiverId // ignore: cast_nullable_to_non_nullable
                        as String,
            message:
                null == message
                    ? _value.message
                    : message // ignore: cast_nullable_to_non_nullable
                        as String,
            sentAt:
                null == sentAt
                    ? _value.sentAt
                    : sentAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            read:
                null == read
                    ? _value.read
                    : read // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
    _$MessageImpl value,
    $Res Function(_$MessageImpl) then,
  ) = __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String messageId,
    String senderId,
    String receiverId,
    String message,
    DateTime sentAt,
    bool read,
  });
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
    _$MessageImpl _value,
    $Res Function(_$MessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? senderId = null,
    Object? receiverId = null,
    Object? message = null,
    Object? sentAt = null,
    Object? read = null,
  }) {
    return _then(
      _$MessageImpl(
        messageId:
            null == messageId
                ? _value.messageId
                : messageId // ignore: cast_nullable_to_non_nullable
                    as String,
        senderId:
            null == senderId
                ? _value.senderId
                : senderId // ignore: cast_nullable_to_non_nullable
                    as String,
        receiverId:
            null == receiverId
                ? _value.receiverId
                : receiverId // ignore: cast_nullable_to_non_nullable
                    as String,
        message:
            null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String,
        sentAt:
            null == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        read:
            null == read
                ? _value.read
                : read // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$MessageImpl with DiagnosticableTreeMixin implements _Message {
  const _$MessageImpl({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.sentAt,
    this.read = false,
  });

  @override
  final String messageId;
  @override
  final String senderId;
  @override
  final String receiverId;
  @override
  final String message;
  @override
  final DateTime sentAt;
  @override
  @JsonKey()
  final bool read;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Message(messageId: $messageId, senderId: $senderId, receiverId: $receiverId, message: $message, sentAt: $sentAt, read: $read)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Message'))
      ..add(DiagnosticsProperty('messageId', messageId))
      ..add(DiagnosticsProperty('senderId', senderId))
      ..add(DiagnosticsProperty('receiverId', receiverId))
      ..add(DiagnosticsProperty('message', message))
      ..add(DiagnosticsProperty('sentAt', sentAt))
      ..add(DiagnosticsProperty('read', read));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.receiverId, receiverId) ||
                other.receiverId == receiverId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.read, read) || other.read == read));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    messageId,
    senderId,
    receiverId,
    message,
    sentAt,
    read,
  );

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);
}

abstract class _Message implements Message {
  const factory _Message({
    required final String messageId,
    required final String senderId,
    required final String receiverId,
    required final String message,
    required final DateTime sentAt,
    final bool read,
  }) = _$MessageImpl;

  @override
  String get messageId;
  @override
  String get senderId;
  @override
  String get receiverId;
  @override
  String get message;
  @override
  DateTime get sentAt;
  @override
  bool get read;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FriendPageState {
  List<Friendship> get friends => throw _privateConstructorUsedError;
  List<FriendRequest> get incomingRequests =>
      throw _privateConstructorUsedError;
  List<FriendRequest> get outgoingRequests =>
      throw _privateConstructorUsedError;
  List<Message> get messages =>
      throw _privateConstructorUsedError; // Friend profiles preloaded in one batch from `fetchFriendProfiles`,
  // keyed by the other user's id. Lets the friends list render each tile
  // synchronously from cache instead of firing two `listDocuments` calls
  // per row (one for profile, one for quitDate) on every rebuild.
  Map<String, UserProfile> get friendProfiles =>
      throw _privateConstructorUsedError; // Same idea for the Friend Requests tab — preloaded sender profiles
  // (incl. their quitDate) so `_buildFriendRequests`'s `ListView.builder`
  // doesn't fire two `listDocuments` calls per row per rebuild.
  Map<String, UserProfile> get incomingRequestProfiles =>
      throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get hasError => throw _privateConstructorUsedError;
  UserProfile? get searchResult => throw _privateConstructorUsedError;

  /// Create a copy of FriendPageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendPageStateCopyWith<FriendPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendPageStateCopyWith<$Res> {
  factory $FriendPageStateCopyWith(
    FriendPageState value,
    $Res Function(FriendPageState) then,
  ) = _$FriendPageStateCopyWithImpl<$Res, FriendPageState>;
  @useResult
  $Res call({
    List<Friendship> friends,
    List<FriendRequest> incomingRequests,
    List<FriendRequest> outgoingRequests,
    List<Message> messages,
    Map<String, UserProfile> friendProfiles,
    Map<String, UserProfile> incomingRequestProfiles,
    bool isLoading,
    bool hasError,
    UserProfile? searchResult,
  });

  $UserProfileCopyWith<$Res>? get searchResult;
}

/// @nodoc
class _$FriendPageStateCopyWithImpl<$Res, $Val extends FriendPageState>
    implements $FriendPageStateCopyWith<$Res> {
  _$FriendPageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FriendPageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friends = null,
    Object? incomingRequests = null,
    Object? outgoingRequests = null,
    Object? messages = null,
    Object? friendProfiles = null,
    Object? incomingRequestProfiles = null,
    Object? isLoading = null,
    Object? hasError = null,
    Object? searchResult = freezed,
  }) {
    return _then(
      _value.copyWith(
            friends:
                null == friends
                    ? _value.friends
                    : friends // ignore: cast_nullable_to_non_nullable
                        as List<Friendship>,
            incomingRequests:
                null == incomingRequests
                    ? _value.incomingRequests
                    : incomingRequests // ignore: cast_nullable_to_non_nullable
                        as List<FriendRequest>,
            outgoingRequests:
                null == outgoingRequests
                    ? _value.outgoingRequests
                    : outgoingRequests // ignore: cast_nullable_to_non_nullable
                        as List<FriendRequest>,
            messages:
                null == messages
                    ? _value.messages
                    : messages // ignore: cast_nullable_to_non_nullable
                        as List<Message>,
            friendProfiles:
                null == friendProfiles
                    ? _value.friendProfiles
                    : friendProfiles // ignore: cast_nullable_to_non_nullable
                        as Map<String, UserProfile>,
            incomingRequestProfiles:
                null == incomingRequestProfiles
                    ? _value.incomingRequestProfiles
                    : incomingRequestProfiles // ignore: cast_nullable_to_non_nullable
                        as Map<String, UserProfile>,
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
            searchResult:
                freezed == searchResult
                    ? _value.searchResult
                    : searchResult // ignore: cast_nullable_to_non_nullable
                        as UserProfile?,
          )
          as $Val,
    );
  }

  /// Create a copy of FriendPageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<$Res>? get searchResult {
    if (_value.searchResult == null) {
      return null;
    }

    return $UserProfileCopyWith<$Res>(_value.searchResult!, (value) {
      return _then(_value.copyWith(searchResult: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FriendPageStateImplCopyWith<$Res>
    implements $FriendPageStateCopyWith<$Res> {
  factory _$$FriendPageStateImplCopyWith(
    _$FriendPageStateImpl value,
    $Res Function(_$FriendPageStateImpl) then,
  ) = __$$FriendPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Friendship> friends,
    List<FriendRequest> incomingRequests,
    List<FriendRequest> outgoingRequests,
    List<Message> messages,
    Map<String, UserProfile> friendProfiles,
    Map<String, UserProfile> incomingRequestProfiles,
    bool isLoading,
    bool hasError,
    UserProfile? searchResult,
  });

  @override
  $UserProfileCopyWith<$Res>? get searchResult;
}

/// @nodoc
class __$$FriendPageStateImplCopyWithImpl<$Res>
    extends _$FriendPageStateCopyWithImpl<$Res, _$FriendPageStateImpl>
    implements _$$FriendPageStateImplCopyWith<$Res> {
  __$$FriendPageStateImplCopyWithImpl(
    _$FriendPageStateImpl _value,
    $Res Function(_$FriendPageStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FriendPageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friends = null,
    Object? incomingRequests = null,
    Object? outgoingRequests = null,
    Object? messages = null,
    Object? friendProfiles = null,
    Object? incomingRequestProfiles = null,
    Object? isLoading = null,
    Object? hasError = null,
    Object? searchResult = freezed,
  }) {
    return _then(
      _$FriendPageStateImpl(
        friends:
            null == friends
                ? _value._friends
                : friends // ignore: cast_nullable_to_non_nullable
                    as List<Friendship>,
        incomingRequests:
            null == incomingRequests
                ? _value._incomingRequests
                : incomingRequests // ignore: cast_nullable_to_non_nullable
                    as List<FriendRequest>,
        outgoingRequests:
            null == outgoingRequests
                ? _value._outgoingRequests
                : outgoingRequests // ignore: cast_nullable_to_non_nullable
                    as List<FriendRequest>,
        messages:
            null == messages
                ? _value._messages
                : messages // ignore: cast_nullable_to_non_nullable
                    as List<Message>,
        friendProfiles:
            null == friendProfiles
                ? _value._friendProfiles
                : friendProfiles // ignore: cast_nullable_to_non_nullable
                    as Map<String, UserProfile>,
        incomingRequestProfiles:
            null == incomingRequestProfiles
                ? _value._incomingRequestProfiles
                : incomingRequestProfiles // ignore: cast_nullable_to_non_nullable
                    as Map<String, UserProfile>,
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
        searchResult:
            freezed == searchResult
                ? _value.searchResult
                : searchResult // ignore: cast_nullable_to_non_nullable
                    as UserProfile?,
      ),
    );
  }
}

/// @nodoc

class _$FriendPageStateImpl
    with DiagnosticableTreeMixin
    implements _FriendPageState {
  const _$FriendPageStateImpl({
    final List<Friendship> friends = const [],
    final List<FriendRequest> incomingRequests = const [],
    final List<FriendRequest> outgoingRequests = const [],
    final List<Message> messages = const [],
    final Map<String, UserProfile> friendProfiles = const {},
    final Map<String, UserProfile> incomingRequestProfiles = const {},
    this.isLoading = false,
    this.hasError = false,
    this.searchResult,
  }) : _friends = friends,
       _incomingRequests = incomingRequests,
       _outgoingRequests = outgoingRequests,
       _messages = messages,
       _friendProfiles = friendProfiles,
       _incomingRequestProfiles = incomingRequestProfiles;

  final List<Friendship> _friends;
  @override
  @JsonKey()
  List<Friendship> get friends {
    if (_friends is EqualUnmodifiableListView) return _friends;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_friends);
  }

  final List<FriendRequest> _incomingRequests;
  @override
  @JsonKey()
  List<FriendRequest> get incomingRequests {
    if (_incomingRequests is EqualUnmodifiableListView)
      return _incomingRequests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_incomingRequests);
  }

  final List<FriendRequest> _outgoingRequests;
  @override
  @JsonKey()
  List<FriendRequest> get outgoingRequests {
    if (_outgoingRequests is EqualUnmodifiableListView)
      return _outgoingRequests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_outgoingRequests);
  }

  final List<Message> _messages;
  @override
  @JsonKey()
  List<Message> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  // Friend profiles preloaded in one batch from `fetchFriendProfiles`,
  // keyed by the other user's id. Lets the friends list render each tile
  // synchronously from cache instead of firing two `listDocuments` calls
  // per row (one for profile, one for quitDate) on every rebuild.
  final Map<String, UserProfile> _friendProfiles;
  // Friend profiles preloaded in one batch from `fetchFriendProfiles`,
  // keyed by the other user's id. Lets the friends list render each tile
  // synchronously from cache instead of firing two `listDocuments` calls
  // per row (one for profile, one for quitDate) on every rebuild.
  @override
  @JsonKey()
  Map<String, UserProfile> get friendProfiles {
    if (_friendProfiles is EqualUnmodifiableMapView) return _friendProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_friendProfiles);
  }

  // Same idea for the Friend Requests tab — preloaded sender profiles
  // (incl. their quitDate) so `_buildFriendRequests`'s `ListView.builder`
  // doesn't fire two `listDocuments` calls per row per rebuild.
  final Map<String, UserProfile> _incomingRequestProfiles;
  // Same idea for the Friend Requests tab — preloaded sender profiles
  // (incl. their quitDate) so `_buildFriendRequests`'s `ListView.builder`
  // doesn't fire two `listDocuments` calls per row per rebuild.
  @override
  @JsonKey()
  Map<String, UserProfile> get incomingRequestProfiles {
    if (_incomingRequestProfiles is EqualUnmodifiableMapView)
      return _incomingRequestProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_incomingRequestProfiles);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool hasError;
  @override
  final UserProfile? searchResult;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FriendPageState(friends: $friends, incomingRequests: $incomingRequests, outgoingRequests: $outgoingRequests, messages: $messages, friendProfiles: $friendProfiles, incomingRequestProfiles: $incomingRequestProfiles, isLoading: $isLoading, hasError: $hasError, searchResult: $searchResult)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'FriendPageState'))
      ..add(DiagnosticsProperty('friends', friends))
      ..add(DiagnosticsProperty('incomingRequests', incomingRequests))
      ..add(DiagnosticsProperty('outgoingRequests', outgoingRequests))
      ..add(DiagnosticsProperty('messages', messages))
      ..add(DiagnosticsProperty('friendProfiles', friendProfiles))
      ..add(
        DiagnosticsProperty('incomingRequestProfiles', incomingRequestProfiles),
      )
      ..add(DiagnosticsProperty('isLoading', isLoading))
      ..add(DiagnosticsProperty('hasError', hasError))
      ..add(DiagnosticsProperty('searchResult', searchResult));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendPageStateImpl &&
            const DeepCollectionEquality().equals(other._friends, _friends) &&
            const DeepCollectionEquality().equals(
              other._incomingRequests,
              _incomingRequests,
            ) &&
            const DeepCollectionEquality().equals(
              other._outgoingRequests,
              _outgoingRequests,
            ) &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            const DeepCollectionEquality().equals(
              other._friendProfiles,
              _friendProfiles,
            ) &&
            const DeepCollectionEquality().equals(
              other._incomingRequestProfiles,
              _incomingRequestProfiles,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasError, hasError) ||
                other.hasError == hasError) &&
            (identical(other.searchResult, searchResult) ||
                other.searchResult == searchResult));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_friends),
    const DeepCollectionEquality().hash(_incomingRequests),
    const DeepCollectionEquality().hash(_outgoingRequests),
    const DeepCollectionEquality().hash(_messages),
    const DeepCollectionEquality().hash(_friendProfiles),
    const DeepCollectionEquality().hash(_incomingRequestProfiles),
    isLoading,
    hasError,
    searchResult,
  );

  /// Create a copy of FriendPageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendPageStateImplCopyWith<_$FriendPageStateImpl> get copyWith =>
      __$$FriendPageStateImplCopyWithImpl<_$FriendPageStateImpl>(
        this,
        _$identity,
      );
}

abstract class _FriendPageState implements FriendPageState {
  const factory _FriendPageState({
    final List<Friendship> friends,
    final List<FriendRequest> incomingRequests,
    final List<FriendRequest> outgoingRequests,
    final List<Message> messages,
    final Map<String, UserProfile> friendProfiles,
    final Map<String, UserProfile> incomingRequestProfiles,
    final bool isLoading,
    final bool hasError,
    final UserProfile? searchResult,
  }) = _$FriendPageStateImpl;

  @override
  List<Friendship> get friends;
  @override
  List<FriendRequest> get incomingRequests;
  @override
  List<FriendRequest> get outgoingRequests;
  @override
  List<Message> get messages; // Friend profiles preloaded in one batch from `fetchFriendProfiles`,
  // keyed by the other user's id. Lets the friends list render each tile
  // synchronously from cache instead of firing two `listDocuments` calls
  // per row (one for profile, one for quitDate) on every rebuild.
  @override
  Map<String, UserProfile> get friendProfiles; // Same idea for the Friend Requests tab — preloaded sender profiles
  // (incl. their quitDate) so `_buildFriendRequests`'s `ListView.builder`
  // doesn't fire two `listDocuments` calls per row per rebuild.
  @override
  Map<String, UserProfile> get incomingRequestProfiles;
  @override
  bool get isLoading;
  @override
  bool get hasError;
  @override
  UserProfile? get searchResult;

  /// Create a copy of FriendPageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendPageStateImplCopyWith<_$FriendPageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

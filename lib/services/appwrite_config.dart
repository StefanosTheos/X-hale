/// Single source of truth for Appwrite connection details.
///
/// Replaces the hard-coded endpoint / project / database ID that were
/// previously duplicated across `main.dart` and every provider.
class AppwriteConfig {
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = '685d2b28003a614fa813';
  static const String databaseId = '685d2f83002cb88b5ddf';

  /// Bucket that hosts user-uploaded avatars. Create it in
  /// Appwrite console → Storage → Buckets, set Read permission to `users` (or
  /// `any` if the avatar should be visible to other users), and paste the
  /// bucket ID here. Until then [UserNotifier.updateAvatarFromFile] will fail
  /// loudly instead of silently storing a device-local path.
  static const String userAvatarsBucketId = '6a031c95003375921887';

  /// Stable public URL for a stored file — replaces the device-local-path
  /// pattern that broke when the user signed in on another device.
  static String fileViewUrl(String bucketId, String fileId) =>
      '$endpoint/storage/buckets/$bucketId/files/$fileId/view?project=$projectId';
}

/// IDs of every Appwrite collection used by the app. Previously the same
/// IDs were duplicated in ~36 places across 11 provider files.
class AppwriteCollections {
  static const String users = '685d2f88001fc9471631';
  static const String milestones = '685d3181002fc385b957';
  static const String healthBenefits = '685d31af00311c899268';
  static const String diary = '685d31ff000ee7a914ff';
  static const String forum = '685d31d9003c29f13421';
  static const String challenges = '685d3233002933bc80d6';
  static const String challengeEntries = '685d32bb0023444507f9';
  static const String achievements = '685d32f80037407606c4';
  static const String motivations = '685d314700303649367a';
  static const String friendships = '6880cd730012d3aac2cc';
  static const String friendRequests = '6880ce0d000a1ad99b58';
  static const String directMessages = '6880ce5800193d799b9f';
  // Miscellaneous messages collection (used by user_message_provider).
  static const String messagesMisc = '686d38950033f3fcd785';
}

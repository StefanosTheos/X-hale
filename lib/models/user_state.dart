import 'package:appwrite/models.dart' as appwrite;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'user_state.freezed.dart';

@freezed
class UserState with _$UserState {
  const factory UserState({
    required String userId,
    required String email,
    required String name,
    required String formOfConsumption,
    required String selectedCurrency,
    required double minutesPerCig,
    required int cigsPerDay,
    required int cigsPerPack,
    required int yearsSmoking,
    required double pricePerPack,
    required DateTime quitDate,

    String? phoneNumber,
    @Default('assets/icons/account.png') String avatarPath,
    @Default(0) int achievementsCount,

    @Default(false) bool notifications,
    @Default(false) bool hasSamsungHealth,
    @Default('light') String theme,
    @Default('en') String language,
    @Default(false) bool isInitialized,
    @Default(false) bool isLoading,
    @Default(false) bool hasError,
    DateTime? lastWheelSpin,
    @Default(0) int totalWheelSpins,
    @Default(0) int snakeHighScore,
    @Default(0) int flappyHighScore,
    @Default(0) int high2048Score,
    @Default(0) int numFriends,
    @Default(0) int achievementPoints,
    @Default(0) int diaryCount,
    @Default(0) int physicalCount,
    @Default(0) int financialCount,
    @Default(0) int numChatMessages,
    @Default(0) int numForumPosts,
    @Default(0) int numMilestonesCompleted,
    @Default(0) int numHealthBenefit,
  }) = _UserState;

  factory UserState.initial() => UserState(
    userId: '',
    email: '',
    name: 'User123',
    formOfConsumption: 'cigarettes',
    selectedCurrency: '€',
    minutesPerCig: 5.0,
    cigsPerDay: 10,
    cigsPerPack: 20,
    yearsSmoking: 5,
    pricePerPack: 5.0,
    quitDate: DateTime.now().toUtc().subtract(const Duration(days: 15)),
  );

  factory UserState.fromAppwriteDocument(appwrite.Document doc) {
    final rawLastWheelSpin = doc.data['lastWheelSpin'] as String?;
    DateTime? lastWheelSpin;
    final rawQuitDate = doc.data['quitDate'] as String? ?? '';
    DateTime quitDate;

    if (rawQuitDate.isNotEmpty) {
      quitDate = DateTime.parse(rawQuitDate).toLocal();
    } else {
      // Fresh signup before onboarding completes — no log; legitimate state.
      quitDate = DateTime.now().toLocal();
    }
    if (rawLastWheelSpin != null && rawLastWheelSpin.isNotEmpty) {
      lastWheelSpin = DateTime.tryParse(rawLastWheelSpin)?.toLocal();
    }
    return UserState(
      userId: doc.data['userId'] as String? ?? '',
      email: doc.data['email'] as String? ?? '',
      name: doc.data['name'] as String? ?? 'New User',
      phoneNumber: doc.data['phoneNumber'] as String?,
      formOfConsumption:
          doc.data['formOfConsumption'] as String? ?? 'cigarettes',
      selectedCurrency: doc.data['selectedCurrency'] as String? ?? '€',
      minutesPerCig: (doc.data['timePerCigarette'] as num?)?.toDouble() ?? 5.0,
      cigsPerDay: doc.data['cigarettesPerDay'] as int? ?? 10,
      cigsPerPack: doc.data['cigarettesPerPack'] as int? ?? 20,
      yearsSmoking: doc.data['yearsSmoking'] as int? ?? 0,
      pricePerPack: (doc.data['pricePerPack'] as num?)?.toDouble() ?? 5.0,
      quitDate: quitDate,
      avatarPath:
          doc.data['profileIcon'] as String? ?? 'assets/icons/account.png',
      achievementsCount: (doc.data['achievementsCount'] as num?)?.toInt() ?? 0,
      theme: doc.data['theme'] as String? ?? 'light',
      language: doc.data['language'] as String? ?? 'en',
      notifications: doc.data['notifications'] as bool? ?? false,
      hasSamsungHealth: doc.data['hasSamsungHealth'] as bool? ?? false,
      isInitialized: doc.data['isInitialized'] as bool? ?? false,
      lastWheelSpin: lastWheelSpin,
      totalWheelSpins: (doc.data['totalWheelSpins'] as num?)?.toInt() ?? 0,
      snakeHighScore: (doc.data['snakeHighScore'] as num?)?.toInt() ?? 0,
      flappyHighScore: (doc.data['flappyHighScore'] as num?)?.toInt() ?? 0,
      high2048Score: (doc.data['high2048Score'] as num?)?.toInt() ?? 0,
      numFriends: (doc.data['numFriends'] as num?)?.toInt() ?? 0,
      achievementPoints: (doc.data['achievementPoints'] as num?)?.toInt() ?? 0,
      diaryCount: (doc.data['diaryCount'] as num?)?.toInt() ?? 0,
      physicalCount: (doc.data['physicalCount'] as num?)?.toInt() ?? 0,
      financialCount: (doc.data['financialCount'] as num?)?.toInt() ?? 0,
      numChatMessages: (doc.data['numChatMessages'] as num?)?.toInt() ?? 0,
      numForumPosts: (doc.data['numForumPosts'] as num?)?.toInt() ?? 0,
      numMilestonesCompleted:
          (doc.data['numMilestonesCompleted'] as num?)?.toInt() ?? 0,
      numHealthBenefit: (doc.data['numHealthBenefit'] as num?)?.toInt() ?? 0,
    );
  }
}

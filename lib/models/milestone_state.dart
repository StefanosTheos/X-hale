import 'package:appwrite/models.dart' as appwrite;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'milestone_state.freezed.dart';

@freezed
class Milestone with _$Milestone {
  const factory Milestone({
    required String title,
    required String description,
    required DateTime date,
    required bool completed,
    @Default(false) bool isEligible,
  }) = _Milestone;

  factory Milestone.fromAppwriteDocument(appwrite.Document doc) {
    return Milestone(
      title: doc.data['label'] as String,
      description: '',
      date: DateTime.parse(doc.data['dateReached'] as String),
      completed: true,
      isEligible: true,
    );
  }
}

@freezed
class MilestoneState with _$MilestoneState {
  const MilestoneState._();

  const factory MilestoneState({
    required DateTime startDate,
    required String userId,
    @Default([]) List<Milestone> allMilestones,
    @Default(<String>{}) Set<String> completedTitles,
    @Default(false) bool isLoading,
    @Default(false) bool hasError,
    String? errorMessage,
  }) = _MilestoneState;

  factory MilestoneState.initial({
    required DateTime startDate,
    required String userId,
  }) => MilestoneState(startDate: startDate, userId: userId);

  List<Milestone> get daysMilestones =>
      allMilestones.where((m) => m.title.contains('Day')).toList();

  List<Milestone> get weeksMilestones =>
      allMilestones.where((m) => m.title.contains('Week')).toList();

  List<Milestone> get monthsMilestones =>
      allMilestones.where((m) => m.title.contains('Month')).toList();

  List<Milestone> get yearsMilestones =>
      allMilestones.where((m) => m.title.contains('Year')).toList();

  List<Milestone> generateMilestones() {
    List<Milestone> milestones = [];
    // Hoist once instead of paying for 54 fresh `DateTime` allocations per
    // call (one per `isEligible:` check in each milestone-list branch). The
    // ~ms it takes to advance between checks is negligible against the day-
    // and-month-scale comparisons below, so a single "now" is correct.
    final now = DateTime.now();

    DateTime addMonths(DateTime date, int monthsToAdd) {
      int newYear = date.year + ((date.month + monthsToAdd - 1) ~/ 12);
      int newMonth = ((date.month + monthsToAdd - 1) % 12) + 1;
      int newDay = date.day;
      int daysInMonth = DateTime(newYear, newMonth + 1, 0).day;
      if (newDay > daysInMonth) newDay = daysInMonth;
      return DateTime(newYear, newMonth, newDay);
    }

    String getDescription(String title) {
      final value = int.tryParse(title.split(' ').first) ?? 0;
      final unit = title.split(' ').last.toLowerCase();

      switch (unit) {
        case 'day':
        case 'days':
          return "$value day${value > 1 ? 's' : ''} smoke-free! Amazing achievement!";
        case 'week':
        case 'weeks':
          return "$value week${value > 1 ? 's' : ''} without smoking! Keep it up!";
        case 'month':
        case 'months':
          return "$value month${value > 1 ? 's' : ''} of freedom from smoking!";
        case 'year':
        case 'years':
          return "$value year${value > 1 ? 's' : ''} smoke-free! You're an inspiration!";
        default:
          return "Congratulations on reaching this milestone!";
      }
    }

    // Days milestones
    const daysList = [1, 5, 10, 25, 50, 100, 250, 500, 1000, 1500, 2000, 5000];
    for (final days in daysList) {
      final title = "$days Day${days > 1 ? 's' : ''}";
      final date = startDate.add(Duration(days: days));
      milestones.add(
        Milestone(
          title: title,
          description: getDescription(title),
          date: date,
          completed: completedTitles.contains(title),
          isEligible: now.isAfter(date),
        ),
      );
    }

    // Weeks milestones
    const weeksList = [
      1,
      2,
      5,
      10,
      15,
      20,
      30,
      40,
      50,
      75,
      100,
      150,
      200,
      350,
      500,
    ];
    for (final weeks in weeksList) {
      final title = "$weeks Week${weeks > 1 ? 's' : ''}";
      final date = startDate.add(Duration(days: weeks * 7));
      milestones.add(
        Milestone(
          title: title,
          description: getDescription(title),
          date: date,
          completed: completedTitles.contains(title),
          isEligible: now.isAfter(date),
        ),
      );
    }

    // Months milestones
    const monthsList = [
      1,
      2,
      3,
      6,
      9,
      12,
      15,
      20,
      30,
      40,
      50,
      75,
      100,
      150,
      200,
    ];
    for (final months in monthsList) {
      final title = "$months Month${months > 1 ? 's' : ''}";
      final date = addMonths(startDate, months);
      milestones.add(
        Milestone(
          title: title,
          description: getDescription(title),
          date: date,
          completed: completedTitles.contains(title),
          isEligible: now.isAfter(date),
        ),
      );
    }

    // Years milestones
    const yearsList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20];
    for (final years in yearsList) {
      final title = "$years Year${years > 1 ? 's' : ''}";
      final date = DateTime(
        startDate.year + years,
        startDate.month,
        startDate.day,
      );
      milestones.add(
        Milestone(
          title: title,
          description: getDescription(title),
          date: date,
          completed: completedTitles.contains(title),
          isEligible: now.isAfter(date),
        ),
      );
    }

    return milestones;
  }
}

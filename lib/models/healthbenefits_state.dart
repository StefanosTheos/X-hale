import 'package:smoking/constants/health_benefits.dart';

class HealthBenefitsState {
  final String userId;
  final DateTime quitDate;
  final List<String> achievedBenefits;

  HealthBenefitsState({
    required this.userId,
    required this.quitDate,
    this.achievedBenefits = const [],
  });

  factory HealthBenefitsState.fromAppwrite(Map<String, dynamic> data) {
    return HealthBenefitsState(
      userId: data['userId'],
      quitDate: DateTime.parse(data['quitDate']),
      achievedBenefits: List<String>.from(data['achievedBenefits'] ?? []),
    );
  }

  Map<String, dynamic> toAppwrite() {
    return {
      'userId': userId,
      'quitDate': quitDate.toIso8601String(),
      'achievedBenefits': achievedBenefits,
    };
  }

  HealthBenefitsState copyWith({
    String? userId,
    DateTime? quitDate,
    List<String>? achievedBenefits,
  }) {
    return HealthBenefitsState(
      userId: userId ?? this.userId,
      quitDate: quitDate ?? this.quitDate,
      achievedBenefits: achievedBenefits ?? this.achievedBenefits,
    );
  }

  bool hasAchieved(String benefitId) => achievedBenefits.contains(benefitId);

  Duration timeSinceQuit() => DateTime.now().difference(quitDate);

  double calculateProgress(String benefitId) {
    final benefit = HealthBenefits.getById(benefitId);
    if (benefit == null) return 0.0;

    final elapsed = timeSinceQuit().inMinutes;
    return (elapsed / benefit['time_interval']).clamp(0.0, 1.0);
  }

  DateTime completionDateFor(String benefitId) {
    final benefit = HealthBenefits.getById(benefitId);
    return benefit != null
        ? quitDate.add(Duration(minutes: benefit['time_interval']))
        : quitDate;
  }
}

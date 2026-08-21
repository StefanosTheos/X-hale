import 'package:flutter_test/flutter_test.dart';
import 'package:smoking/models/breathing_state.dart';

void main() {
  test('breathing techniques follow their documented phase order', () {
    expect(
      techniques.singleWhere((technique) => technique.name == 'Box Breathing').phases,
      ['Inhale', 'Hold', 'Exhale', 'Hold'],
    );
    expect(
      techniques.singleWhere((technique) => technique.name == '4-7-8 Breathing').phases,
      ['Inhale', 'Hold', 'Exhale'],
    );
    expect(
      techniques.singleWhere((technique) => technique.name == 'Nadi Shodhana').phases,
      ['Inhale', 'Exhale'],
    );
  });

  test('every configured phase has a positive duration', () {
    for (final technique in techniques) {
      for (final phase in technique.phases) {
        final duration = switch (phase) {
          'Inhale' => technique.inhale,
          'Hold' => technique.hold,
          'Exhale' => technique.exhale,
          _ => Duration.zero,
        };
        expect(
          duration,
          greaterThan(Duration.zero),
          reason: '${technique.name} has no duration for $phase',
        );
      }
    }
  });
}

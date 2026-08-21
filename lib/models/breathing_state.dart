class BreathingTechnique {
  final String name;
  final String description;
  final Duration inhale;
  final Duration hold;
  final Duration exhale;
  final String audioPrefix;
  final List<String> phases;

  const BreathingTechnique({
    required this.name,
    required this.description,
    required this.inhale,
    required this.hold,
    required this.exhale,
    required this.audioPrefix,
    required this.phases,
  });
}

const List<BreathingTechnique> techniques = [
  BreathingTechnique(
    name: 'Box Breathing',
    description: 'Inhale, hold, exhale, hold — all for 4 seconds.',
    inhale: Duration(seconds: 4),
    hold: Duration(seconds: 4),
    exhale: Duration(seconds: 4),
    audioPrefix: 'box',
    phases: ['Inhale', 'Hold', 'Exhale', 'Hold'],
  ),
  BreathingTechnique(
    name: '4-7-8 Breathing',
    description: 'Inhale for 4, hold for 7, exhale for 8 seconds.',
    inhale: Duration(seconds: 4),
    hold: Duration(seconds: 7),
    exhale: Duration(seconds: 8),
    audioPrefix: '478',
    phases: ['Inhale', 'Hold', 'Exhale'],
  ),
  BreathingTechnique(
    name: 'Nadi Shodhana',
    description:
        'Alternate nostril breathing. Inhale and exhale slowly for 5 seconds.',
    inhale: Duration(seconds: 5),
    hold: Duration(seconds: 0),
    exhale: Duration(seconds: 5),
    audioPrefix: 'nadi',
    phases: ['Inhale', 'Exhale'],
  ),
];

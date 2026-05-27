class StretchExercise {
  final String name;
  final String description;
  final String instructions;
  final Duration duration;
  final Duration restDuration;
  final String imageAsset;

  const StretchExercise({
    required this.name,
    required this.description,
    required this.instructions,
    required this.duration,
    required this.restDuration,
    required this.imageAsset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StretchExercise &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          imageAsset == other.imageAsset;

  @override
  int get hashCode => name.hashCode ^ imageAsset.hashCode;
}

const List<StretchExercise> stretches = [
  StretchExercise(
    name: 'Neck Stretch',
    description: 'Relieves neck tension and improves mobility',
    instructions:
        '1. Sit or stand tall\n2. Slowly tilt head to one side\n3. Hold for duration\n4. Repeat on other side',
    duration: Duration(seconds: 25),
    restDuration: Duration(seconds: 10),
    imageAsset: 'assets/icons/neck-stretch.png',
  ),
  StretchExercise(
    name: 'Shoulder Stretch',
    description: 'Releases shoulder tension',
    instructions:
        '1. Stand tall\n2. Place arm horizontally across your body and hold in place with the other\n3. Hold position\n4. Repeat on other side',
    duration: Duration(seconds: 40),
    restDuration: Duration(seconds: 15),
    imageAsset: 'assets/icons/shoulder-stretch.png',
  ),
  StretchExercise(
    name: 'Hamstring Stretch',
    description: 'Improves leg flexibility',
    instructions:
        '1. Stand upright with one leg straight in front and the other slightly bent\n2. Keep your back straight and hinge forward at the hips\n3. Reach toward the toes of the straight leg without bouncing and hold\n4. Repeat on the other side',
    duration: Duration(seconds: 40),
    restDuration: Duration(seconds: 15),
    imageAsset: 'assets/icons/hamstring-stretch.png',
  ),
  StretchExercise(
    name: 'Quad Stretch',
    description: 'Stretches front thigh muscles',
    instructions:
        '1. Stand on one leg assisted by vertical surface for balance\n2. Pull other foot toward glutes and stretch the quad\n3. Hold position\n4. Repeat on other side',
    duration: Duration(seconds: 40),
    restDuration: Duration(seconds: 10),
    imageAsset: 'assets/icons/quad-stretch.png',
  ),
  StretchExercise(
    name: 'Chest Opener',
    description: 'Counters hunching posture',
    instructions:
        '1. Place hand on vertical surface\n2. Open up your body and create tension in your chest\n3. Hold position\n4. Repeat on other side',
    duration: Duration(seconds: 40),
    restDuration: Duration(seconds: 15),
    imageAsset: 'assets/icons/chest-stretch2.png',
  ),
];

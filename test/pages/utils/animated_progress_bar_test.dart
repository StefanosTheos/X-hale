import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoking/pages/utils/animated_progress_bar.dart';

void main() {
  testWidgets('non-animated updates do not leave a frame scheduled', (
    tester,
  ) async {
    var progress = 0.25;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return AnimatedProgressBar(
              targetProgress: progress,
              animateUpdates: false,
            );
          },
        ),
      ),
    );

    // Allow the initial entrance animation to complete.
    await tester.pumpAndSettle();

    update(() => progress = 0.26);
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('ordinary progress-bar updates remain animated', (tester) async {
    var progress = 0.25;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return AnimatedProgressBar(targetProgress: progress);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    update(() => progress = 0.75);
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isTrue);
  });
}

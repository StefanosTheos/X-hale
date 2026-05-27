import 'point.dart';
import 'dart:math';

// One Random per file rather than `Random()` allocated twice per call. The
// previous code reseeded from the platform on every spawn.
final Random _rng = Random();

List<List<int>> blankGrid() {
  return List.generate(4, (_) => List.filled(4, 0));
}

bool compare(List<List<int>> a, List<List<int>> b) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      if (a[i][j] != b[i][j]) return false;
    }
  }
  return true;
}

List<List<int>> copyGrid(List<List<int>> grid) {
  return List.generate(4, (i) => List.from(grid[i]));
}

List<List<int>> flipGrid(List<List<int>> grid) {
  return List.generate(4, (i) => grid[i].reversed.toList());
}

List<List<int>> transposeGrid(List<List<int>> grid) {
  final newGrid = blankGrid();
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      newGrid[i][j] = grid[j][i];
    }
  }
  return newGrid;
}

List<List<int>> addNumber(List<List<int>> grid) {
  final options = <Point>[];

  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      if (grid[i][j] == 0) {
        options.add(Point(i, j));
      }
    }
  }

  if (options.isNotEmpty) {
    final spot = options[_rng.nextInt(options.length)];
    // Canonical 2048: a "4" spawns ~10% of the time, a "2" ~90%. The previous
    // `nextInt(100) > 50` produced 4s roughly half the time, which made the
    // board fill with 4s and trivialised the 128/256/… achievements.
    final newValue = _rng.nextInt(10) == 0 ? 4 : 2;
    grid[spot.x][spot.y] = newValue;
  }

  return grid;
}

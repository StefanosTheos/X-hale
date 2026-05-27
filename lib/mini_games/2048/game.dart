// The previous `combine` also wrote `high_score` to SharedPreferences inside
// this merge loop — up to 3 disk writes per row, 12 per swipe, async and
// unawaited. The Riverpod / Appwrite path in `home2048.dart` (via
// `userNotifier.update2048HighScore`) is authoritative; the SharedPreferences
// shadow was vestigial.

List<Object> operate(List<int> row, int score) {
  row = slide(row);
  final result = combine(row, score);
  final int sc = result[0] as int;
  row = result[1] as List<int>;
  row = slide(row);

  return [sc, row];
}

List<int> filter(List<int> row) {
  return row.where((value) => value != 0).toList();
}

List<int> slide(List<int> row) {
  final arr = filter(row);
  final missing = 4 - arr.length;
  final zeroes = List.filled(missing, 0);
  return [...zeroes, ...arr];
}

List<Object> combine(List<int> row, int score) {
  for (int i = 3; i >= 1; i--) {
    if (row[i] == row[i - 1] && row[i] != 0) {
      row[i] *= 2;
      score += row[i];
      row[i - 1] = 0;
    }
  }
  return [score, row];
}

bool isGameWon(List<List<int>> grid) {
  for (final row in grid) {
    if (row.contains(2048)) return true;
  }
  return false;
}

bool isGameOver(List<List<int>> grid) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      final val = grid[i][j];
      if (val == 0) return false;
      if (i < 3 && val == grid[i + 1][j]) return false;
      if (j < 3 && val == grid[i][j + 1]) return false;
    }
  }
  return true;
}

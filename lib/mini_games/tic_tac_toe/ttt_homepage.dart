import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:smoking/pages/utils/dialogs.dart';

class TicHomePage extends StatefulWidget {
  const TicHomePage({super.key});

  @override
  TicHomePageState createState() => TicHomePageState();
}

class TicHomePageState extends State<TicHomePage> {
  late List<String> board;
  int player1Score = 0;
  int player2Score = 0;
  int draws = 0;
  int activePlayer = 1;
  bool isSinglePlayer = true;
  // Locks `playMove` after a win/draw so taps on the still-visible board
  // can't slot extra Xs/Os into the empty cells. The end-of-round dialog is
  // `barrierDismissible: true` and has a "Close" button, so the user can
  // exit it without resetting — without this lock, the board stays
  // interactive between rounds. Cleared by `resetBoard`.
  bool _isGameOver = false;

  final AudioPlayer _sfx = AudioPlayer();

  final winCombos = const [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  @override
  void initState() {
    super.initState();
    board = List.generate(9, (_) => "");
    // Pre-warm the audioplayers cache so the first tap doesn't stutter.
    AudioCache.instance.loadAll([
      'audio/tap.wav',
      'audio/win.wav',
      'audio/draw.wav',
    ]);
  }

  @override
  void dispose() {
    _sfx.dispose();
    super.dispose();
  }

  void resetBoard() {
    setState(() {
      board = List.generate(9, (_) => "");
      activePlayer = 1;
      _isGameOver = false;
    });
  }

  void toggleMode() {
    setState(() {
      isSinglePlayer = !isSinglePlayer;
      // Switching modes resets the scoreboard — wins against the AI and
      // wins against a human aren't comparable, so carrying them over
      // would mix two different "matches" under the same totals. The board
      // also clears (via `resetBoard` below).
      player1Score = 0;
      player2Score = 0;
      draws = 0;
      resetBoard();
    });
  }

  void playMove(int index) {
    if (_isGameOver) return;
    if (board[index] != "") return;

    setState(() {
      board[index] = activePlayer == 1 ? "X" : "O";
    });

    playSound("tap.wav");

    final winner = checkWinner();
    if (winner != null) {
      _isGameOver = true;
      playSound("win.wav");
      showEndDialog(winner);
      return;
    }

    if (!board.contains("")) {
      _isGameOver = true;
      draws++;
      playSound("draw.wav");
      showEndDialog(null);
      return;
    }

    setState(() {
      activePlayer = 3 - activePlayer;
    });

    if (isSinglePlayer && activePlayer == 2) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        autoPlay();
      });
    }
  }

  void autoPlay() {
    final empty = <int>[];
    for (int i = 0; i < 9; i++) {
      if (board[i] == "") empty.add(i);
    }

    if (empty.isNotEmpty) {
      final move = empty[Random().nextInt(empty.length)];
      playMove(move);
    }
  }

  String? checkWinner() {
    for (var combo in winCombos) {
      final a = combo[0], b = combo[1], c = combo[2];
      if (board[a] != "" && board[a] == board[b] && board[a] == board[c]) {
        if (board[a] == "X") {
          player1Score++;
        } else {
          player2Score++;
        }
        return board[a];
      }
    }
    return null;
  }

  void showEndDialog(String? winner) {
    showGradientDialog<void>(
      context: context,
      // TTT's own cyan gradient — the game has its own palette (the rest
      // of the app's `AppThemes` gradients are user-theme-aware).
      gradient: const LinearGradient(
        colors: [Color(0xffcaf0f8), Color(0xffade8f4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      children: [
        Icon(
          winner == null ? Icons.handshake : Icons.emoji_events,
          size: 40,
          color: const Color(0xff0077b6),
        ),
        const SizedBox(height: 16),
        Text(
          winner == null
              ? "It's a Draw!"
              : "Player ${winner == "X" ? 1 : 2} Wins!",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        Builder(
          builder: (ctx) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  resetBoard();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff48CAE4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Play Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void playSound(String file) {
    // Fire-and-forget by design (tap/win/draw cues), but mark the Future as
    // intentionally unawaited and swallow play failures (missing asset, audio
    // focus denied) so they don't surface as unhandled async errors.
    unawaited(
      _sfx.play(AssetSource('audio/$file')).catchError((Object e) {
        debugPrint('tic_tac_toe playSound error: $e');
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xffB5EAEA)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildScoreBoard(),
                const SizedBox(height: 20),
                _buildGameGrid(),
                const SizedBox(height: 10),
                _buildModeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff0077b6)),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Center(
            child: Text(
              "Tic Tac Toe",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xff0077b6),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xff0077b6)),
          onPressed: resetBoard,
        ),
      ],
    );
  }

  Widget _buildScoreBoard() {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _scoreColumn("Player 1 (X)", player1Score, const Color(0xffFF6B6B)),
            _scoreColumn("Draws", draws, Colors.grey.shade700),
            _scoreColumn("Player 2 (O)", player2Score, const Color(0xff48CAE4)),
          ],
        ),
      ),
    );
  }

  Widget _scoreColumn(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGameGrid() {
    return Expanded(
      child: GridView.builder(
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder:
            (context, index) => GestureDetector(
              onTap: () => playMove(index),
              child: Card(
                color: Colors.white,
                elevation: 6,
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    board[index],
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color:
                          board[index] == "X"
                              ? const Color(0xffFF6B6B)
                              : const Color(0xff48CAE4),
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildModeButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.swap_horiz, color: Colors.white),
      label: Text(
        isSinglePlayer ? "Switch to 2 Players" : "Switch to vs AI",
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff48CAE4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
      ),
      onPressed: toggleMode,
    );
  }
}

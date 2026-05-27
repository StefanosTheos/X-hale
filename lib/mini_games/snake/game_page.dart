import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smoking/mini_games/snake/game_over.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/providers/user_provider.dart';

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  GamePageState createState() => GamePageState();
}

class GamePageState extends ConsumerState<GamePage>
    with SingleTickerProviderStateMixin {
  late int _playerScore;
  late bool _hasStarted;
  late Animation<double> _snakeAnimation;
  late AnimationController _snakeController;
  final List<int> _snake = [404, 405, 406, 407];
  // Parallel set kept in lockstep with `_snake` for O(1) membership checks.
  // `build` is called every 250 ms while the snake moves; rebuilding a Set
  // from the list on every frame was wasted allocation. The cycle-detection
  // in `_gameOver` still needs positional access via `_snake`.
  final Set<int> _snakeSet = {404, 405, 406, 407};
  final int _noOfSquares = 500;
  final Duration _duration = Duration(milliseconds: 250);
  final int _squareSize = 20;
  late String _currentSnakeDirection;
  late int _snakeFoodPosition;
  final Random _random = Random();
  Timer? _gameLoopTimer;

  final Color _primaryColor = Color(0xFF2D3748);
  final Color _accentColor = Color(0xFF48BB78);
  final Color _snakeHeadColor = Color(0xFF4299E1);
  final Color _snakeBodyColor = Color(0xFF3182CE);
  final Color _foodColor = Color(0xFFF56565);
  final Color _backgroundColor = Color(0xFF2D3748);
  final Color _gridColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _setUpGame();
  }

  void _setUpGame() {
    _playerScore = 0;
    _currentSnakeDirection = 'RIGHT';
    _hasStarted = true;
    do {
      _snakeFoodPosition = _random.nextInt(_noOfSquares);
    } while (_snakeSet.contains(_snakeFoodPosition));
    _snakeController = AnimationController(vsync: this, duration: _duration);
    _snakeAnimation = CurvedAnimation(
      curve: Curves.easeInOut,
      parent: _snakeController,
    );
  }

  void _gameStart() {
    // Cancel any prior loop before reassigning. The play/pause FAB always
    // calls this on every tap, so without the cancel a rapid pause→resume
    // (or any second tap) stacks overlapping timers — they all keep firing
    // `_updateSnake` and race on shared state.
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 250), (
      Timer timer,
    ) async {
      await _updateSnake();
      if (_hasStarted) timer.cancel();
    });
  }

  bool _gameOver() {
    for (int i = 0; i < _snake.length - 1; i++) {
      if (_snake.last == _snake[i]) return true;
    }
    return false;
  }

  Future<void> _updateSnake() async {
    if (!_hasStarted) {
      _playerScore = (_snake.length - 4) * 100;
      final int nextHead;
      switch (_currentSnakeDirection) {
        case 'DOWN':
          nextHead = _snake.last + _squareSize >= _noOfSquares
              ? _snake.last + _squareSize - _noOfSquares
              : _snake.last + _squareSize;
          break;
        case 'UP':
          nextHead = _snake.last < _squareSize
              ? _snake.last - _squareSize + _noOfSquares
              : _snake.last - _squareSize;
          break;
        case 'RIGHT':
          nextHead = (_snake.last + 1) % _squareSize == 0
              ? _snake.last + 1 - _squareSize
              : _snake.last + 1;
          break;
        case 'LEFT':
          nextHead = (_snake.last) % _squareSize == 0
              ? _snake.last - 1 + _squareSize
              : _snake.last - 1;
          break;
        default:
          return;
      }
      _snake.add(nextHead);
      // `_snakeSet.add` is a no-op if `nextHead` is already in the snake —
      // that's the self-collision case, which `_gameOver()` will catch on
      // the list (positional duplicates can't be represented in a Set).
      _snakeSet.add(nextHead);

      if (_snake.last != _snakeFoodPosition) {
        final removed = _snake.removeAt(0);
        // Only drop from the set if the tail's cell isn't also occupied by
        // another segment (shouldn't happen on a valid game, but cheap to
        // guard against).
        if (!_snake.contains(removed)) _snakeSet.remove(removed);
      } else {
        do {
          _snakeFoodPosition = _random.nextInt(_noOfSquares);
        } while (_snakeSet.contains(_snakeFoodPosition));
      }

      if (_gameOver()) {
        final currentHighScore = ref.read(userProvider).snakeHighScore;
        if (_playerScore > currentHighScore) {
          await ref
              .read(userProvider.notifier)
              .updateSnakeHighScore(_playerScore);
        }
        if (!mounted) return;
        setState(() {
          _hasStarted = !_hasStarted;
        });

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameOver(score: _playerScore),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileCount = _noOfSquares;
    final cols = _squareSize;
    final rows = (tileCount / cols).ceil();
    final tileWidth = MediaQuery.of(context).size.width / cols;
    final gridHeight = tileWidth * rows;
    // `_snakeSet` is maintained alongside `_snake` (see _updateSnake) so the
    // grid's itemBuilder can do O(1) membership checks without re-allocating
    // a Set on every build (4 Hz tick → 500 cells = ~2000 ops/sec).
    final snakeHead = _snake.isEmpty ? -1 : _snake.last;

    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        title: Text(
          'Snake Game',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accentColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        label: Text(
          _hasStarted ? 'START GAME' : 'PAUSE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        onPressed: () {
          if (!mounted) return;
          setState(() {
            if (_hasStarted) {
              _snakeController.forward();
            } else {
              _snakeController.reverse();
            }
            _hasStarted = !_hasStarted;
            _gameStart();
          });
        },
        icon: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _snakeAnimation,
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onVerticalDragUpdate: (drag) {
                        if (drag.delta.dy > 0 &&
                            _currentSnakeDirection != 'UP') {
                          _currentSnakeDirection = 'DOWN';
                        } else if (drag.delta.dy < 0 &&
                            _currentSnakeDirection != 'DOWN') {
                          _currentSnakeDirection = 'UP';
                        }
                      },
                      onHorizontalDragUpdate: (drag) {
                        if (drag.delta.dx > 0 &&
                            _currentSnakeDirection != 'LEFT') {
                          _currentSnakeDirection = 'RIGHT';
                        } else if (drag.delta.dx < 0 &&
                            _currentSnakeDirection != 'RIGHT') {
                          _currentSnakeDirection = 'LEFT';
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: gridHeight,
                        color: _backgroundColor,
                        child: GridView.builder(
                          itemCount: _noOfSquares,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _squareSize,
                              ),
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _gridColor.withAlpha(
                                    (0.2 * 255).round(),
                                  ),
                                  width: 0.5,
                                ),
                              ),
                              child: Center(
                                child:
                                    _snakeSet.contains(index)
                                        ? Container(
                                          decoration: BoxDecoration(
                                            color:
                                                index == snakeHead
                                                    ? _snakeHeadColor
                                                    : _snakeBodyColor,
                                            borderRadius: BorderRadius.circular(
                                              index == snakeHead ? 6 : 4,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color.fromRGBO(
                                                  0,
                                                  0,
                                                  0,
                                                  0.1,
                                                ),
                                                blurRadius: 3,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        )
                                        : index == _snakeFoodPosition
                                        ? Container(
                                          decoration: BoxDecoration(
                                            color: _foodColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _foodColor.withAlpha(
                                                  (0.5 * 255).round(),
                                                ),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        )
                                        : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScoreCard('SCORE', '$_playerScore'),
                      _buildScoreCard(
                        'HIGH SCORE',
                        '${ref.watch(userProvider.select((u) => u.snakeHighScore))}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreCard(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.8),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _snakeController.dispose();
    super.dispose();
  }
}

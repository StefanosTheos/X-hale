import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/providers/user_provider.dart';
import 'mycolor.dart';
import 'tile.dart';
import 'grid.dart';
import 'game.dart';

class Custom2048Page extends ConsumerStatefulWidget {
  const Custom2048Page({super.key});

  @override
  ConsumerState<Custom2048Page> createState() => _Custom2048PageState();
}

class _Custom2048PageState extends ConsumerState<Custom2048Page> {
  List<List<int>> grid = blankGrid();
  int score = 0;
  bool isGameOverFlag = false;
  bool isGameWonFlag = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    grid = blankGrid();
    grid = addNumber(grid);
    grid = addNumber(grid);
    setState(() => isLoading = false);
  }

  List<Widget> buildGridTiles(double width, double height) {
    List<Widget> tiles = [];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final int value = grid[i][j];
        final String text = value == 0 ? "" : "$value";
        Color color;

        if (value == 0) {
          color = MyColor.emptyGridBackground;
        } else if (value == 2 || value == 4) {
          color = MyColor.gridColorTwoFour;
        } else if ([8, 64, 256].contains(value)) {
          color = MyColor.gridColorEightSixtyFourTwoFiftySix;
        } else if ([16, 32, 1024].contains(value)) {
          color = MyColor.gridColorSixteenThirtyTwoOneZeroTwoFour;
        } else if ([128, 512].contains(value)) {
          color = MyColor.gridColorOneTwentyEightFiveOneTwo;
        } else {
          color = MyColor.gridColorWin;
        }

        double fontSize = 40.0;
        switch (text.length) {
          case 3:
            fontSize = 30.0;
            break;
          case 4:
            fontSize = 20.0;
            break;
        }

        tiles.add(Tile(text, width, height, color, fontSize));
      }
    }
    return tiles;
  }

  Future<void> handleGesture(int direction) async {
    // Lock the board once the game ends. Without this, swipes would keep
    // mutating the grid (and re-firing high-score sync at line 113) while
    // the "Game Over!" / "You Won!" overlay sat on top of it.
    if (isGameOverFlag || isGameWonFlag) return;
    bool flipped = false;
    bool rotated = false;

    final oldGrid = copyGrid(grid);
    final prevGameOverFlag = isGameOverFlag;
    final prevGameWonFlag = isGameWonFlag;

    if (direction == 0) {
      grid = transposeGrid(grid);
      grid = flipGrid(grid);
      flipped = true;
      rotated = true;
    } else if (direction == 1) {
      grid = transposeGrid(grid);
      rotated = true;
    } else if (direction == 3) {
      grid = flipGrid(grid);
      flipped = true;
    }

    for (int i = 0; i < 4; i++) {
      var result = operate(grid[i], score);
      score = result[0] as int;
      grid[i] = result[1] as List<int>;
    }

    if (flipped) grid = flipGrid(grid);
    if (rotated) grid = transposeGrid(grid);

    if (compare(oldGrid, grid)) {
      grid = addNumber(grid);
    }

    if (isGameOver(grid)) isGameOverFlag = true;
    if (isGameWon(grid)) isGameWonFlag = true;

    // Skip the 16-tile rebuild on a completely no-op swipe (grid unchanged,
    // no end-state flag flipped). Previously `setState(() {})` fired on
    // every gesture regardless of outcome — a blocked swipe on a full board
    // walked all 16 `Tile` widgets through `build` for nothing.
    final gridChanged = !compare(oldGrid, grid);
    final flagsChanged = isGameOverFlag != prevGameOverFlag ||
        isGameWonFlag != prevGameWonFlag;
    if (gridChanged || flagsChanged) {
      setState(() {});
    }
    final currentHighScore = ref.read(userProvider).high2048Score;
    if (score > currentHighScore) {
      await ref.read(userProvider.notifier).update2048HighScore(score);
    }
  }

  void resetGame() {
    setState(() {
      grid = blankGrid();
      grid = addNumber(grid);
      grid = addNumber(grid);
      score = 0;
      isGameOverFlag = false;
      isGameWonFlag = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tileSize = (width - 80) / 4;
    final gridHeight = tileSize * 4 + 40;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '2048',
          style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
        ),
        backgroundColor: MyColor.gridBackground,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.fromARGB(0, 255, 255, 255), Color(0xFFa2917d)],
              ),
            ),
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        width: 200.0,
                        height: 82.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: MyColor.gridBackground,
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 10.0, bottom: 2.0),
                              child: Text(
                                'Score',
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '$score',
                              style: const TextStyle(
                                fontSize: 20.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: gridHeight,
                      color: MyColor.gridBackground,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: GestureDetector(
                              onVerticalDragUpdate: (details) {
                                if (details.delta.dy < -10) {
                                  handleGesture(0); // up
                                }
                                if (details.delta.dy > 10) {
                                  handleGesture(1); // down
                                }
                              },
                              onHorizontalDragUpdate: (details) {
                                if (details.delta.dx < -10) {
                                  handleGesture(3); // left
                                }
                                if (details.delta.dx > 10) {
                                  handleGesture(2); // right
                                }
                              },
                              child: GridView.count(
                                crossAxisCount: 4,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                children: buildGridTiles(tileSize, tileSize),
                              ),
                            ),
                          ),
                          if (isGameOverFlag)
                            Container(
                              height: gridHeight,
                              color: MyColor.transparentWhite,
                              child: Center(
                                child: Text(
                                  'Game Over!',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: MyColor.gridBackground,
                                  ),
                                ),
                              ),
                            ),
                          if (isGameWonFlag)
                            Container(
                              height: gridHeight,
                              color: MyColor.transparentWhite,
                              child: Center(
                                child: Text(
                                  'You Won!',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: MyColor.gridBackground,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: MyColor.gridBackground,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white70,
                              ),
                              iconSize: 35.0,
                              onPressed: resetGame,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: MyColor.gridBackground,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'High Score',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${ref.watch(userProvider.select((u) => u.high2048Score))}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:get/get.dart';

import '../dash_game_controller.dart';
import '../flappy_dash_game.dart';

class ObstacleGenerator extends Component with HasGameReference<FlappyDash> {
  DashGameController dashGameController = Get.find();

  final intervalBetweenNextObstacle = 150.0;
  late Vector2 spawnPosition;
  final double spawnPositionOffset = 200;

  List<double> distanceBetweenTwoObstacle = [170.0, 180.0, 190.0, 200.0];
  late List<SpriteComponent> obstacles;
  // Flame's `removeFromParent` is queued, so on subsequent frames before the
  // removal completes this generator's `update` keeps running. Without this
  // latch, every still-onscreen obstacle in this pair re-triggers the
  // `< -100` branch and re-increments `userScore` — meaning each passed
  // pipe pair counted 2-3 times. The "Flappy 15"/"Flappy 30" achievements
  // were therefore awarded at ~half the intended pipe count.
  bool _scored = false;
  // Same idea for the game-over teardown path: `removeFromParent` is queued,
  // and without this latch every generator's `update` keeps re-queueing the
  // removal on every tick until it actually completes.
  bool _removed = false;

  @override
  FutureOr<void> onLoad() async {
    spawnPosition = Vector2(game.size.x + spawnPositionOffset, 0);

    obstacles = await generateObstacle();
    addAll(obstacles);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (dashGameController.gameState == GameState.GAME_STARTED) {
      for (var obstacle in obstacles) {
        obstacle.x -= intervalBetweenNextObstacle * dt;
      }
      _maybeScore();
    } else if (dashGameController.gameState == GameState.GAME_OVER &&
        !_removed) {
      // Final score reconciliation before teardown. If the bird passed the
      // pipe pair on the same frame it crashed (or fell off-screen), the
      // GAME_STARTED branch above didn't run on this last tick — without
      // this catch-up the just-cleared pipe wouldn't be credited.
      _maybeScore();
      _removed = true;
      removeFromParent();
    }
    super.update(dt);
  }

  /// Increment the score the instant the bird has fully cleared this pipe
  /// pair. Dash sits at `game.size.x / 4` (its left edge with default
  /// `Anchor.topLeft`); the pipe pair's visible right edge is at
  /// `topObstacle.x` (the top pipe is rotated `pi` around its top-left
  /// anchor, so its anchor coincides with the visible right edge, and the
  /// bottom pipe is positioned `-pipeWidth` so it aligns horizontally with
  /// the top). `.every` waits for *both* pipes in the list — the limiting
  /// condition resolves to `topObstacle.x < birdX`, i.e. the moment the
  /// rightmost edge of the pair crosses behind the bird's left edge.
  ///
  /// High-score persistence lives in the Riverpod path in
  /// `menus/game_over.dart` (calls `updateFlappyHighScore` once when the
  /// game ends). The previous in-loop `prefSetBestScore` was a
  /// SharedPreferences shadow with no consumers — see #417.
  void _maybeScore() {
    if (_scored) return;
    final birdX = game.size.x / 4;
    if (obstacles.every((o) => o.x < birdX)) {
      _scored = true;
      dashGameController.userScore++;
    }
  }

  Future<List<SpriteComponent>> generateObstacle() async {
    List<SpriteComponent> obstacles = [];

    Vector2 spriteSize = Vector2(60, game.size.y / 2);
    double offset = Random().nextDouble() * 100;

    Sprite sprite = await Sprite.load("pipe-green.png");
    final topObstacle = SpriteComponent(sprite: sprite, size: spriteSize);
    topObstacle.position = Vector2(
      spawnPosition.x,
      (spriteSize.y / 1.5) + offset,
    );
    topObstacle.angle = pi;
    topObstacle.add(RectangleHitbox());
    obstacles.add(topObstacle);

    final bottomObstacle = SpriteComponent(sprite: sprite, size: spriteSize);
    bottomObstacle.position = Vector2(
      topObstacle.x - spriteSize.x,
      topObstacle.position.y +
          distanceBetweenTwoObstacle[Random().nextInt(
            distanceBetweenTwoObstacle.length,
          )] +
          offset,
    );
    bottomObstacle.add(RectangleHitbox());
    obstacles.add(bottomObstacle);

    return obstacles;
  }
}

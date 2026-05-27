import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smoking/mini_games/flappy_bird/player/base_platform.dart';
import 'package:smoking/mini_games/flappy_bird/player/dash.dart';
import 'package:smoking/mini_games/flappy_bird/player/obstacle_generator.dart';
import 'package:smoking/mini_games/flappy_bird/utils/audio_controller.dart';
import 'package:smoking/mini_games/flappy_bird/utils/user_preferences.dart';
import 'package:smoking/mini_games/flappy_bird/world/parallax_background.dart';

import 'dash_game_controller.dart';

// ignore: constant_identifier_names
enum GameState { GAME_STARTED, GAME_OVER, GAME_LAUNCH, GAME_PAUSE }

class FlappyDash extends FlameGame
    with TapDetector, KeyboardEvents, HasCollisionDetection {
  @override
  bool get debugMode => false;

  final DashGameController dashGameController = Get.put(DashGameController());
  late Dash player;
  Timer obstacleGeneratorTimer = Timer(2, repeat: true);

  late final UserPreferences userPreferences;
  late AudioController audioController;

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();
    // Await the SharedPreferences resolve before reading it — see
    // `UserPreferences.create` for the rationale.
    userPreferences = await UserPreferences.create();
    audioController = AudioController(
      isAudioEnabled: userPreferences.prefGetAudioEnabled(),
    );

    player = Dash();

    add(ParallaxBackground());
    add(ObstacleGenerator());
    add(player);

    add(BasePlatform(platformPosition: Vector2(0, size.y)));
    add(BasePlatform(platformPosition: Vector2(0, -20)));

    obstacleGeneratorTimer.onTick = () {
      if (dashGameController.gameState == GameState.GAME_STARTED) {
        add(ObstacleGenerator());
      }
    };

    return super.onLoad();
  }

  @override
  void onRemove() {
    // Release the two `AudioPlayer` instances when the game is torn down —
    // popping the route would otherwise leak them past the player's exit.
    audioController.dispose();
    super.onRemove();
  }

  @override
  void update(double dt) {
    if (dashGameController.gameState == GameState.GAME_STARTED) {
      obstacleGeneratorTimer.update(dt);
    }
    super.update(dt);
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (dashGameController.gameState == GameState.GAME_STARTED) {
      player.jump();
    }
    super.onTap();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      if (dashGameController.gameState == GameState.GAME_STARTED) {
        player.jump();
      } else if (dashGameController.gameState == GameState.GAME_OVER) {
        player.retryGame();
      } else {
        player.startGame();
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }
}

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:smoking/mini_games/flappy_bird/flappy_dash_game.dart';
import 'package:smoking/mini_games/flappy_bird/menus/game_intro.dart';
import 'package:smoking/mini_games/flappy_bird/menus/game_over.dart';
import 'package:smoking/mini_games/flappy_bird/menus/game_score.dart';
import 'package:smoking/mini_games/flappy_bird/utils/consts.dart';

class FlappyBird2GamePage extends StatelessWidget {
  const FlappyBird2GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget.controlled(
        gameFactory: FlappyDash.new,
        overlayBuilderMap: {
          keyGameStarted: (context, FlappyDash game) => GameScore(game: game),
          keyGameIntro: (context, FlappyDash game) => GameIntro(game: game),
          keyGameOver: (context, FlappyDash game) => GameOver(game: game),
        },
        initialActiveOverlays: const [keyGameIntro],
        // Replaces the default black frame while Flame loads sprites/audio.
        loadingBuilder: (_) => const _GameLoading(),
      ),
    );
  }
}

class _GameLoading extends StatelessWidget {
  const _GameLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF87CEEB),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

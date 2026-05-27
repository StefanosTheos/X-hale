import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smoking/mini_games/2048/home2048.dart';
import 'package:smoking/mini_games/flappy_bird/flappy_bird2_game_page.dart';
import 'package:smoking/mini_games/snake/game_page.dart';
import 'package:smoking/mini_games/tic_tac_toe/ttt_homepage.dart';

class MiniGamesPage extends StatelessWidget {
  MiniGamesPage({super.key});

  final List<Map<String, dynamic>> games = [
    {
      'title': 'Snake',
      'icon': 'assets/icons/snake.png',
      'page': GamePage(),
      'description': 'Classic snake game. Eat and grow!',
    },
    {
      'title': 'Flappy Bird',
      'icon': 'assets/icons/flappy_bird.jpg',
      'page': FlappyBird2GamePage(),
      'description': 'Tap to fly between pipes!',
    },
    {
      'title': '2048',
      'icon': 'assets/icons/2048.png',
      'page': Custom2048Page(),
      'description': 'Swipe to merge tiles to 2048!',
    },
    {
      'title': 'Tic Tac Toe',
      'icon': 'assets/icons/tic_tac_toe.png',
      'page': TicHomePage(),
      'description': 'Play X vs O with a friend!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1C),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Color(0xff00B4D8), Color(0xff48CAE4)],
            ).createShader(bounds);
          },
          child: const Text(
            '🎮 Mini Games',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF121212), Color(0xFF1E1E2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: GridView.builder(
            itemCount: games.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) {
              final game = games[index];
              return _buildGameCard(context, game);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, Map<String, dynamic> game) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => game['page']),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(),
            ),
            Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        game['icon'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      game['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        game['description'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color.fromRGBO(255, 255, 255, 0.7),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.cyanAccent.shade100,
                      size: 36,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

void showInfoDialogue(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          backgroundColor: const Color.fromARGB(221, 16, 15, 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Image.asset(
                "assets/images/auto_run_instruction.png",
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 12),
              const Text(
                "Flappy Dash",
                style: TextStyle(
                  fontFamily: 'Comfortaa',
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              "Flappy Dash is a fun and addictive mini-game inspired by the classic Flappy Bird. "
              "Built using the Flame game engine and Flutter, it offers smooth animations, vibrant graphics, and challenging obstacle-based gameplay.\n\n"
              "Tap the screen to keep the bird in the air and dodge incoming pipes. The longer you survive, the higher your score climbs. "
              "It's simple, fast-paced, and perfect for quick gaming sessions!",
              style: TextStyle(
                fontFamily: 'Comfortaa',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontFamily: 'Comfortaa',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
  );
}

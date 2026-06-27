import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/extensions/widget_ref_theme.dart';
import 'package:smoking/pages/utils/back_app_bar.dart';
import 'package:smoking/pages/utils/themes.dart';

class HelpPage extends ConsumerWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDark;

    final backgroundGradient =
        isDark ? AppThemes.darkGradient : AppThemes.lightGradient;
    final cardColor =
        isDark ? AppThemes.darkCardColor : AppThemes.lightCardColor;
    final textColor =
        isDark ? AppThemes.darkTextColor : const Color(0xff023E8A);
    final bodyTextColor =
        isDark ? AppThemes.darkSubtitleColor : AppThemes.lightSubtitleColor;

    return Scaffold(
      appBar: const BackAppBar(title: 'Seek Help'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: backgroundGradient),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(isDark ? 40 : 25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withAlpha(isDark ? 100 : 70),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🆘  If you are in crisis',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.red[300] : Colors.red[800],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Please contact a crisis line immediately:\n'
                              '• 988 — US & Canada (call or text)\n'
                              '• 116 123 — Samaritans, UK & Ireland (free, 24/7)\n'
                              '• 1018 — KLIMAKA, Greece (24/7)',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: isDark ? Colors.red[200] : Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You are NOT alone',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Quitting smoking is one of the bravest decisions you can make. '
                        'It\'s a journey filled with challenges, but also with small victories each day.\n\n'
                        'If today is tough, remember: every craving resisted makes you stronger. '
                        'You have the strength to push through — one step at a time.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: bodyTextColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '📞 Smoking Quitlines:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '• USA: 1-800-QUIT-NOW (free, 24/7)',
                        style: TextStyle(color: bodyTextColor),
                      ),
                      Text(
                        '• UK: 0300 123 1044 (Mon–Fri 9am–8pm, Sat–Sun 11am–4pm)',
                        style: TextStyle(color: bodyTextColor),
                      ),
                      Text(
                        '• Canada: 1-866-366-3667 (free)',
                        style: TextStyle(color: bodyTextColor),
                      ),
                      Text(
                        '• Australia: 13 7848 — free callback at quit.org.au',
                        style: TextStyle(color: bodyTextColor),
                      ),
                      Text(
                        '• Greece: 1135 (ΕΟΔΥ, Mon–Fri 9am–4pm)',
                        style: TextStyle(color: bodyTextColor),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Need someone to talk to?\n\n'
                        'You don\'t have to do this alone. Support is always available.\n'
                        'Call a quitline, speak to a friend, or open the app — we\'re here for you.\n',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: bodyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

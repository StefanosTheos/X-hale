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
    final crisisHeadingColor =
        isDark ? Colors.red[300]! : Colors.red[800]!;
    final crisisBodyColor =
        isDark ? Colors.red[200]! : Colors.red[900]!;

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
                      // ── Crisis banner ───────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(isDark ? 40 : 22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withAlpha(isDark ? 110 : 80),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.emergency_rounded,
                                  size: 16,
                                  color: crisisHeadingColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'If you are in crisis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.2,
                                    color: crisisHeadingColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _CrisisLine(
                              number: '988',
                              label: 'US & Canada — call or text',
                              color: crisisBodyColor,
                            ),
                            _CrisisLine(
                              number: '116 123',
                              label: 'Samaritans, UK & Ireland — free, 24/7',
                              color: crisisBodyColor,
                            ),
                            _CrisisLine(
                              number: '1018',
                              label: 'KLIMAKA, Greece — 24/7',
                              color: crisisBodyColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Heading ─────────────────────────────────────────
                      Text(
                        'You are not alone',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Quitting smoking is one of the bravest decisions you can make. '
                        'Every craving you resist is a victory — and you don\'t have to do this alone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: bodyTextColor,
                        ),
                      ),

                      const SizedBox(height: 28),
                      Divider(color: (bodyTextColor ?? Colors.grey).withAlpha(60)),
                      const SizedBox(height: 20),

                      // ── Quitlines ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_outlined, size: 18, color: textColor),
                          const SizedBox(width: 8),
                          Text(
                            'Smoking Quitlines',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _QuitlineRow(
                        flag: '🇺🇸',
                        country: 'USA',
                        number: '1-800-QUIT-NOW',
                        note: 'free · 24/7',
                        bodyColor: bodyTextColor,
                        textColor: textColor,
                      ),
                      _QuitlineRow(
                        flag: '🇬🇧',
                        country: 'UK',
                        number: '0300 123 1044',
                        note: 'Mon–Fri 9am–8pm · Sat–Sun 11am–4pm',
                        bodyColor: bodyTextColor,
                        textColor: textColor,
                      ),
                      _QuitlineRow(
                        flag: '🇨🇦',
                        country: 'Canada',
                        number: '1-866-366-3667',
                        note: 'free',
                        bodyColor: bodyTextColor,
                        textColor: textColor,
                      ),
                      _QuitlineRow(
                        flag: '🇦🇺',
                        country: 'Australia',
                        number: '13 7848',
                        note: 'free callback at quit.org.au',
                        bodyColor: bodyTextColor,
                        textColor: textColor,
                      ),
                      _QuitlineRow(
                        flag: '🇬🇷',
                        country: 'Greece',
                        number: '1135',
                        note: 'ΕΟΔΥ · Mon–Fri 9am–4pm',
                        bodyColor: bodyTextColor,
                        textColor: textColor,
                      ),

                      const SizedBox(height: 28),
                      Divider(color: (bodyTextColor ?? Colors.grey).withAlpha(60)),
                      const SizedBox(height: 20),

                      // ── Closing ─────────────────────────────────────────
                      Text(
                        'Support is always available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Call a quitline, speak to a friend, or open the app — we\'re here for you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CrisisLine extends StatelessWidget {
  const _CrisisLine({
    required this.number,
    required this.label,
    required this.color,
  });

  final String number;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuitlineRow extends StatelessWidget {
  const _QuitlineRow({
    required this.flag,
    required this.country,
    required this.number,
    required this.note,
    required this.bodyColor,
    required this.textColor,
  });

  final String flag;
  final String country;
  final String number;
  final String note;
  final Color? bodyColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      country,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      number,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 12,
                    color: bodyColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

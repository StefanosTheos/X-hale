import 'package:flutter/material.dart';

/// Single tip card used by the explore-pages tip lists. Theme-agnostic — the
/// card colors come from each tip entry, so this widget stays outside the
/// `isDark` rebuild graph. The seven tip pages used to inline this body
/// inside `ListView.separated.itemBuilder`, which made the whole list
/// re-allocate widgets on every theme flip even though the tip data is
/// `const`.
class TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  // Two pages (`sleep_matters`, `nutritional_tips`) used `Colors.black54` for
  // the icon while the others used `Colors.black87`. Optional override
  // preserves that visual nuance without forcing a single style.
  final Color iconColor;

  const TipCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.iconColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
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

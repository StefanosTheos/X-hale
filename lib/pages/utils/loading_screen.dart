import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/pages/utils/themes.dart';

class GradientLoadingScreen extends StatelessWidget {
  final bool isDark;

  const GradientLoadingScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppThemes.darkGradient : AppThemes.lightGradient,
      ),
      child: const Center(child: _LoadingIndicator()),
    );
  }
}

class _LoadingIndicator extends ConsumerWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CircularProgressIndicator(
      color: isDark ? AppThemes.darkAppBarColor : AppThemes.lightAppBarColor,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/pages/explore_pages/distractions_draw.dart';
import 'package:smoking/pages/explore_pages/distractions_sounds.dart';
import 'package:smoking/pages/explore_pages/distractions_stretching.dart';
import 'package:smoking/pages/explore_pages/distractions_wheel.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';
class DistractionsPage extends ConsumerStatefulWidget {
  const DistractionsPage({super.key});

  @override
  ConsumerState<DistractionsPage> createState() => _DistractionsPageState();
}

class _DistractionsPageState extends ConsumerState<DistractionsPage> {
  final List<String> options = [
    '🎵 Listen to Sounds',
    '🎲 Spin the Wheel',
    '✏️ Draw a Doodle',
    '🧘 Stretch Routine',
  ];

  String selectedOption = '🎵 Listen to Sounds';

  Widget _buildOptionContent() {
    switch (selectedOption) {
      case '🎵 Listen to Sounds':
        return const SoundPlayerWidget();
      case '🎲 Spin the Wheel':
        return const SpinTheWheelPage();
      case '✏️ Draw a Doodle':
        return const DrawDoodlePage();
      case '🧘 Stretch Routine':
        return const StretchRoutinePage();
      default:
        return const SizedBox();
    }
  }

  InputDecoration _dropdownDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? AppThemes.darkCardColor : const Color(0xffe0f7fa),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Distractions',
          style: TextStyle(
            color: isDark ? AppThemes.darkTextColor : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isDark ? AppThemes.darkAppBarColor : const Color(0xff48CAE4),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? AppThemes.darkIconColor : Colors.black87,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppThemes.motivationGradient(isDark),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedOption,
                  items:
                      options
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(
                                option,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppThemes.darkTextColor
                                          : Colors.black87,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedOption = value);
                    }
                  },
                  dropdownColor:
                      isDark ? AppThemes.darkCardColor : Colors.white,
                  decoration: _dropdownDecoration(isDark),
                  style: TextStyle(
                    color: isDark ? AppThemes.darkTextColor : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildOptionContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

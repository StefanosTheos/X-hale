import 'package:flutter/material.dart';

class AppThemes {
  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
  );

  static const lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xffB5EAEA)],
  );

  static const darkDialogGradient = LinearGradient(
    colors: [Color(0xFF2A2A2D), Color(0xFF3A3A3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const lightDialogGradient = LinearGradient(
    colors: [Color(0xffcaf0f8), Color(0xffade8f4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkCardColor = Color(0xFF2A2A2D);
  static const lightCardColor = Colors.white;

  static const darkTextColor = Colors.white;
  static const lightTextColor = Colors.black;

  static final darkSubtitleColor = Colors.grey[300];
  static const lightSubtitleColor = Colors.black87;

  static const darkIconColor = Colors.white70;
  static const lightIconColor = Colors.black;

  static const darkAppBarColor = Color(0xFF0A84FF);
  static const lightAppBarColor = Color(0xff48CAE4);

  static const activeColor = Color(0xFF0A84FF);

  static Color elevatedButtonBackground(bool isDark) =>
      isDark ? const Color(0xFF444444) : Colors.grey[300]!;

  static Color counterColor(bool isDark) =>
      isDark ? Colors.grey[300]! : Colors.black;

  static Color inputBorderColor(bool isDark) =>
      isDark ? Colors.white : Colors.black;

  static TextStyle inputHintStyle(bool isDark) => TextStyle(
    color:
        isDark
            ? Color.fromRGBO(255, 255, 255, 0.6)
            : Color.fromRGBO(0, 0, 0, 0.6),
  );

  static const lightMotivationGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE6F7FF), Color(0xFFB5EAEA)],
  );

  static const darkMotivationGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121212), Color(0xFF1F1F1F)],
  );

  /// Default `dark ↔ light motivation` gradient used by the explore /
  /// distractions / home backdrops. Was open-coded as
  /// `isDark ? darkGradient : lightMotivationGradient` in five+ pages.
  /// Note: the dark branch is `darkGradient` (not `darkMotivationGradient`)
  /// to preserve the existing visual — those pages historically pair the
  /// app-wide dark gradient with the lighter motivation gradient.
  static Gradient motivationGradient(bool isDark) =>
      isDark ? darkGradient : lightMotivationGradient;

  static const lightPinnedCardColor = Color(0xFFE3F2FD);
  static const darkPinnedCardColor = Color(0xFF2A3A4D);

  static const lightDeleteDialogGradient = LinearGradient(
    colors: [Color(0xffffe5ec), Color(0xffffcad4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkDeleteDialogGradient = LinearGradient(
    colors: [Color(0xFF3A2A2D), Color(0xFF4A3A3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const lightDeleteButtonColor = Color(0xfff28482);
  static const darkDeleteButtonColor = Color(0xFFD32F2F);

  static const lightDiaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE6F7FF), Color(0xFFB5EAEA)],
  );

  static const darkDiaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121212), Color(0xFF1F1F1F)],
  );

  static const lightDiaryCardColor = Color.fromRGBO(255, 255, 255, 0.9);
  static const darkDiaryCardColor = Color(0xFF2A2A2D);

  /// Brand primary blue — used as title color, diary accent, friend/forum
  /// border accent, and dialog title. Was previously a `Color(0xFF0077B6)`
  /// literal repeated 11 times across the UI and three near-duplicate
  /// constants (`lightDiaryTextColor`, `lightTitleColor`, `lightDialogTitleColor`).
  /// Those three constants are kept below as semantic aliases.
  static const primaryBlue = Color(0xFF0077B6);

  static const lightDiaryTextColor = primaryBlue;
  static const darkDiaryTextColor = Color(0xFF64B5F6);

  static const lightTagColor = Color(0xFFE6F7FF);
  static const darkTagColor = Color(0xFF2A3A4D);

  static const lightTagBorderColor = Color(0xFF48CAE4);
  static const darkTagBorderColor = Color(0xFF64B5F6);

  static const lightSelectedTagColor = Color(0xFF48CAE4);
  static const darkSelectedTagColor = Color(0xFF64B5F6);

  static const lightMilestoneGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE6F7FF), Color(0xFFB5EAEA)],
  );

  static const darkMilestoneGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121212), Color(0xFF1F1F1F)],
  );

  static const lightMilestoneCard = Color(0xFFDFF0D8);
  static const darkMilestoneCard = Color(0xFF2D4D2D);

  static const lightEligibleCard = Colors.white;
  static const darkEligibleCard = Color(0xFF2A2A2D);

  static const lightIneligibleCard = Color(0xFFEEEEEE);
  static const darkIneligibleCard = Color(0xFF1E1E1E);

  static const lightCompletedIcon = Color(0xFF5CB85C);
  static const darkCompletedIcon = Color(0xFF4CAF50);

  static const lightEligibleIcon = Color(0xFF5BC0DE);
  static const darkEligibleIcon = Color(0xFF2196F3);

  static const lightTitleColor = primaryBlue;
  static const darkTitleColor = Color(0xFF64B5F6);

  static const lightDialogTitleColor = primaryBlue;
  static const darkDialogTitleColor = Color(0xFF0A84FF);

  static const lightDialogButtonColor = Color(0xFF5CB85C);
  static const darkDialogButtonColor = Color(0xFF4CAF50);

  static const lightCloseButtonColor = Color(0xff48CAE4);
  static const darkCloseButtonColor = Color(0xFF0A84FF);

  static const darkExploreGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromARGB(255, 37, 37, 37), Color.fromARGB(255, 60, 60, 60)],
  );

  static const darkCardOverlay = Color(0x0DFFFFFF);

  static const withdrawalGradient = LinearGradient(
    colors: [Color(0xFFF1F8E9), Color.fromARGB(255, 198, 237, 154)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const sleepGradient = LinearGradient(
    colors: [Color(0xFFF1F8E9), Color.fromARGB(255, 198, 237, 154)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const nutritionGradient = LinearGradient(
    colors: [Color(0xFFFFF8E1), Color.fromARGB(255, 254, 217, 161)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const mentalPrepGradient = LinearGradient(
    colors: [Color(0xFFFFEBEE), Color.fromARGB(255, 254, 149, 160)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const exerciseGradient = LinearGradient(
    colors: [Color(0xFFFFEBEE), Color.fromARGB(255, 254, 149, 160)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const breakhabitsGradient = LinearGradient(
    colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const nonsmokerGradient = LinearGradient(
    colors: [Color.fromARGB(255, 234, 212, 237), Color(0xFFA986E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkBackgroundColor = Color(0xFF1C1C1E);
  static const lightBackgroundColor = Colors.white;

  static const darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2A2D), Color(0xFF3A3A3E)],
  );

  static const lightCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFE6F7FF)],
  );
}

import 'package:flutter/material.dart';

/// 2048 board palette. Previously declared as mutable `static int` hex codes
/// that every call site wrapped in `Color(...)`; now `static const Color`
/// so each value is allocated once and the wrapping at call sites is gone.
class MyColor {
  static const Color gridBackground = Color(0xFFa2917d);
  static const Color gridColorTwoFour = Color(0xFFeee4da);
  static const Color fontColorTwoFour = Color(0xFF766c62);
  static const Color emptyGridBackground = Color(0xFFbfafa0);
  static const Color gridColorEightSixtyFourTwoFiftySix = Color(0xFFf5b27e);
  static const Color gridColorOneTwentyEightFiveOneTwo = Color(0xFFf77b5f);
  static const Color gridColorSixteenThirtyTwoOneZeroTwoFour = Color(0xFFecc402);
  static const Color gridColorWin = Color(0xFF60d992);
  static const Color transparentWhite = Color(0x80FFFFFF);
}

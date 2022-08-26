import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myst/data/util.dart';

Map dark = {
  "colors": {
    "logo": [255, 255, 255],
    "background": [13, 17, 21],
    "maintext": [240, 240, 240],
    "secondarytext": [175, 177, 180],
    "inputbackground": [23, 27, 31],
    "cursor": [175, 177, 180],
    "button": [103, 110, 117],
    "curves": [255, 255, 255],
    "errortext": [150, 0, 0],
    "passwordstrength": [18, 22, 26],
    "passwordgradientstart": [50, 50, 50],
    "passwordgradientend": [255, 255, 255],
  },
  "fonts": {
    "mainfont": 0,
  }
};

Map light = {
  "colors": {
    "logo": [0, 0, 0],
    "background": [220, 220, 220],
    "maintext": [13, 17, 21],
    "secondarytext": [33, 37, 41],
    "inputbackground": [205, 207, 210],
    "cursor": [33, 37, 41],
    "button": [133, 140, 147],
    "curves": [0, 0, 0],
    "errortext": [220, 0, 0],
    "passwordstrength": [210, 210, 210],
    "passwordgradientstart": [170, 170, 170],
    "passwordgradientend": [50, 50, 50],
  },
  "fonts": {
    "mainfont": 0,
  }
};

Map? currentTheme;
Map? nextTheme;
double themeSwitchProgress = 0;

Color getColor(String name) {
  currentTheme ??= dark;
  nextTheme ??= light;
  List<double> colors = interpolateBetween(
    currentTheme!["colors"][name][0],
    currentTheme!["colors"][name][1],
    currentTheme!["colors"][name][2],
    nextTheme!["colors"][name][0],
    nextTheme!["colors"][name][1],
    nextTheme!["colors"][name][2],
    themeSwitchProgress,
  );
  return Color.fromARGB(
    255,
    colors[0].round(),
    colors[1].round(),
    colors[2].round(),
  );
}

TextStyle Function({
  Paint? background,
  Color? backgroundColor,
  Color? color,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
  List<FontFeature>? fontFeatures,
  double? fontSize,
  FontStyle? fontStyle,
  FontWeight? fontWeight,
  Paint? foreground,
  double? height,
  double? letterSpacing,
  Locale? locale,
  List<Shadow>? shadows,
  TextBaseline? textBaseline,
  TextStyle? textStyle,
  double? wordSpacing,
}) getFont(String name) {
  currentTheme ??= dark;
  int num = currentTheme!["fonts"][name];

  return GoogleFonts.poppins;
}

// Theme switching:
// 
// Timer.periodic(const Duration(milliseconds = 10), (timer) {
//   setState(() {
//     themeSwitchProgress += 0.04;
//   });
//   if (themeSwitchProgress >= 1) {
//     Map? s = currentTheme;
//     currentTheme = nextTheme;
//     nextTheme = s;
//     themeSwitchProgress = 0;
//     timer.cancel();
//   }
// });
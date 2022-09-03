import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myst/data/util.dart';

Map dark = {
  "name": "Dark",
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
    "highlight": [206, 212, 218],
    "background2": [23, 27, 31],
    "background3": [21, 25, 29],
    "button2": [40, 46, 56],
  },
  "fonts": {
    "mainfont": 0,
  }
};

Map light = {
  "name": "Light",
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
    "highlight": [73, 80, 87],
    "background2": [200, 200, 200],
    "background3": [210, 210, 210],
    "button2": [166, 171, 179],
  },
  "fonts": {
    "mainfont": 0,
  }
};

Map? currentTheme;
Map? nextTheme;
double themeSwitchProgress = 0;

Color getColor(String name, {Map? theme}) {
  if (theme != null) {
    return Color.fromARGB(
      255,
      theme["colors"][name][0].round(),
      theme["colors"][name][0].round(),
      theme["colors"][name][0].round(),
    );
  }
  currentTheme ??= dark;
  nextTheme ??= light;
  //currentTheme = light;
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
  int num = currentTheme!["fonts"][name] ?? 0;

  return GoogleFonts.poppins;
}

import 'package:flutter/material.dart';
import 'package:myst/data/util.dart';

Map dark = {
  "colors": {
    "logo": [255, 255, 255],
    "background": [13, 17, 21],
  }
};

Map light = {
  "colors": {
    "logo": [0, 0, 0],
    "background": [220, 220, 220],
  }
};

Map? currentTheme;
Map? nextTheme;
double themeSwitchProgress = 0;

Color getColor(String name) {
  currentTheme ??= light;
  nextTheme ??= dark;
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
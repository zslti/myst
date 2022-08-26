import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

List<double> interpolateBetween(
    int r1, int g1, int b1, int r2, int g2, int b2, double progress) {
  double r, g, b;
  progress = min(progress, 1);
  r = r1 + (r2 - r1) * progress;
  g = g1 + (g2 - g1) * progress;
  b = b1 + (b2 - b1) * progress;
  return [r, g, b];
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class CustomClipPath extends CustomClipper<Path> {
  double p;

  @override
  Path getClip(Size size) {
    double w = size.width;
    double h = size.height;

    final path = Path();
    path.lineTo(0, h - 150);
    path.quadraticBezierTo(w * p, h, w, h - 150);
    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }

  CustomClipPath(this.p);
}

bool increasing = false;
Curve curve = Curves.ease;

void pushReplacement(BuildContext context, Widget widget) {
  increasing = true;
  Timer(const Duration(milliseconds: 2500), () {
    increasing = false;
  });
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      // ignore: prefer_const_constructors
      pageBuilder: (c, a1, a2) => widget,
      transitionsBuilder: (c, anim, a2, child) => ScaleTransition(
        scale: AlwaysStoppedAnimation<double>(
          (increasing) ? (curve.transform(anim.value) / 5) + 0.80 : 1,
        ),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
      transitionDuration: const Duration(
        milliseconds: 250,
      ),
    ),
  );
}

void push(BuildContext context, Widget widget) {
  increasing = true;
  Timer(const Duration(milliseconds: 2500), () {
    increasing = false;
  });
  Navigator.push(
    context,
    PageRouteBuilder(
      // ignore: prefer_const_constructors
      pageBuilder: (c, a1, a2) => widget,
      transitionsBuilder: (c, anim, a2, child) => ScaleTransition(
        scale: AlwaysStoppedAnimation<double>(
          (increasing) ? (curve.transform(anim.value) / 5) + 0.80 : 1,
        ),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
      transitionDuration: const Duration(
        milliseconds: 250,
      ),
    ),
  );
}

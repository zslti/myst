import 'dart:math';

List<double> interpolateBetween(
    int r1, int g1, int b1, int r2, int g2, int b2, double progress) {
  double r, g, b;
  progress = min(progress, 1);
  r = r1 + (r2 - r1) * progress;
  g = g1 + (g2 - g1) * progress;
  b = b1 + (b2 - b1) * progress;
  return [r, g, b];
}

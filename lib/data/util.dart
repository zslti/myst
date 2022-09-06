import 'dart:async';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';

import '../main.dart';
import '../ui/mainscreen.dart';
import 'translation.dart';

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
Curve curve = Curves.easeOut;

void pushReplacement(BuildContext context, Widget widget) {
  //increasing = true;
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
  //increasing = true;
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

const double bleedWidth = 20;

enum RevealSide { left, right, main }

RevealSide currentSide = RevealSide.main;
RevealSide swipeDirection = RevealSide.main;

class OverlappingPanels extends StatefulWidget {
  final Widget? left;
  final Widget main;
  final Widget? right;

  final double restWidth;

  final ValueChanged<RevealSide>? onSideChange;

  const OverlappingPanels({
    this.left,
    required this.main,
    this.right,
    this.restWidth = 50,
    this.onSideChange,
    Key? key,
  }) : super(key: key);

  static OverlappingPanelsState? of(BuildContext context) {
    return context.findAncestorStateOfType<OverlappingPanelsState>();
  }

  @override
  State<StatefulWidget> createState() {
    return OverlappingPanelsState();
  }
}

class OverlappingPanelsState extends State<OverlappingPanels>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 15), () {
      onTranslate(400);
      _onApplyTranslation();
      isSliding = true;
    });
  }

  AnimationController? controller;
  double translate = 0;

  double _calculateGoal(double width, int multiplier) {
    return (multiplier * width) + (-multiplier * widget.restWidth);
  }

  void _onApplyTranslation() {
    final mediaWidth = MediaQuery.of(context).size.width;

    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onSideChange != null) {
          widget.onSideChange!(
            translate == 0
                ? RevealSide.main
                : (translate > 0 ? RevealSide.left : RevealSide.right),
          );
        }
        animationController.dispose();
      }
    });

    final currentSide = translate == 0
        ? RevealSide.main
        : (translate > 0 ? RevealSide.left : RevealSide.right);
    bool currentlyOnMain = currentSide == swipeDirection;
    final divider = currentlyOnMain ? 16 : 1.2;
    isSliding = currentlyOnMain;
    if (translate.abs() >= mediaWidth / divider) {
      final multiplier = (translate > 0 ? 1 : -1);
      final goal = _calculateGoal(mediaWidth, multiplier);
      final Tween<double> tween = Tween(begin: translate, end: goal);

      final animation = tween.animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      );

      animation.addListener(() {
        setState(() {
          translate = animation.value;
        });
      });
    } else {
      final animation = Tween<double>(begin: translate, end: 0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      );

      animation.addListener(() {
        setState(() {
          translate = animation.value;
        });
      });
    }

    animationController.forward();
  }

  void reveal(RevealSide direction) {
    if (translate != 0) {
      return;
    }

    final mediaWidth = MediaQuery.of(context).size.width;

    final multiplier = (direction == RevealSide.left ? 1 : -1);
    final goal = _calculateGoal(mediaWidth, multiplier);

    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onApplyTranslation();
        animationController.dispose();
      }
    });

    final animation = Tween<double>(begin: translate, end: goal).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    animation.addListener(() {
      setState(() {
        translate = animation.value;
      });
    });

    animationController.forward();
  }

  void onTranslate(double delta, {bool shouldApplyTransition = false}) {
    setState(() {
      final translate = this.translate + delta;
      if (translate < 0 && widget.right != null ||
          translate > 0 && widget.left != null) {
        this.translate = translate;
      }
      if (shouldApplyTransition) {
        _onApplyTranslation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Offstage(
        offstage: translate < 0,
        child: widget.left,
      ),
      Offstage(
        offstage: translate > 0,
        child: widget.right,
      ),
      Transform.translate(
        offset: Offset(translate, 0),
        child: widget.main,
      ),
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) {
          isSliding = true;
          onTranslate(details.delta.dx);
          if (details.delta.dx > 0) {
            swipeDirection = RevealSide.left;
          } else {
            swipeDirection = RevealSide.right;
          }
        },
        onHorizontalDragEnd: (details) {
          isSliding = false;
          _onApplyTranslation();
        },
      ),
    ]);
  }
}

extension StringExtension on String {
  double textHeight(TextStyle style, double textWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: this, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    final countLines = (textPainter.size.width / textWidth).ceil();
    final height = countLines * textPainter.size.height;
    return height;
  }
}

final key = encrypt.Key.fromBase64('yE9tgqNxWcYDTSPNM+EGQw==');
final iv = encrypt.IV.fromBase64('8PzGKSMLuqSm0MVbviaWHA==');

String encryptText(String text) {
  return encrypt.Encrypter(encrypt.AES(key)).encrypt(text, iv: iv).base64;
}

String decryptText(String text) {
  return encrypt.Encrypter(encrypt.AES(key)).decrypt64(text, iv: iv);
}

String hourMinuteFormat(int hour, int minute) {
  if (currentLanguage == "en") {
    String suffix = "AM";
    if (hour >= 12) {
      suffix = "PM";
      hour -= 12;
    }
    String minuteString = minute.toString();
    if (minuteString.length == 1) {
      minuteString = "0$minuteString";
    }

    return "$hour:$minuteString $suffix";
  } else {
    String minuteString = minute.toString();
    if (minuteString.length == 1) {
      minuteString = "0$minuteString";
    }
    String hourString = hour.toString();
    if (hourString.length == 1) {
      hourString = "0$hourString";
    }
    return "$hourString:$minuteString";
  }
}

String timestampToDate(int timestamp, {bool showOnlyDate = false}) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  DateTime now = DateTime.now();
  String daySuffix = "";
  if (currentLanguage == "en") {
    if (date.day == 1 || date.day == 21 || date.day == 31) {
      daySuffix = "st";
    } else if (date.day == 2 || date.day == 22) {
      daySuffix = "nd";
    } else if (date.day == 3 || date.day == 23) {
      daySuffix = "rd";
    } else {
      daySuffix = "th";
    }
  } else {
    daySuffix = ".";
  }
  String theDate =
      "${translation[currentLanguage]['monthprefix${date.month}']}${date.day}$daySuffix ${translation[currentLanguage]['monthsuffix${date.month}']}";
  if (showOnlyDate) {
    if (currentLanguage == "en") {
      return "$theDate, ${date.year}";
    } else {
      return "${date.year} $theDate";
    }
  }
  if (date.day == now.day && date.month == now.month && date.year == now.year) {
    return "${translation[currentLanguage]['todayat']} ${hourMinuteFormat(date.hour, date.minute)}${translation[currentLanguage]['todayat2']}";
  }
  if (date.day == now.day - 1 &&
      date.month == now.month &&
      date.year == now.year) {
    return "${translation[currentLanguage]['yesterdayat']} ${hourMinuteFormat(date.hour, date.minute)}${translation[currentLanguage]['yesterdayat2']}";
  }

  if (date.year == now.year) {
    if (currentLanguage == "en") {
      return "${hourMinuteFormat(date.hour, date.minute)}, $theDate";
    } else {
      return "$theDate${hourMinuteFormat(date.hour, date.minute)}";
    }
  }
  if (currentLanguage == "en") {
    return "${hourMinuteFormat(date.hour, date.minute)}, $theDate, ${date.year}";
  } else {
    return "${date.year} $theDate${hourMinuteFormat(date.hour, date.minute)}";
  }
}

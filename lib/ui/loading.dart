import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';

import '../main.dart';

List<double> opacity = [0, 0, 0, 0, 0];

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({
    Key? key,
    this.sizeMul,
    this.stopAfterFirstCycle,
  }) : super(key: key);
  final double? sizeMul;
  final bool? stopAfterFirstCycle;

  @override
  State<AnimatedLogo> createState() => AnimatedLogoState();
}

class AnimatedLogoState extends State<AnimatedLogo> {
  @override
  void initState() {
    super.initState();
    opacity = [0, 0, 0, 0, 0];
    if (widget.stopAfterFirstCycle ?? false) {
      for (int i = 0; i < 5; i++) {
        Timer(Duration(milliseconds: 300 * (i + 1)), () {
          if (mounted) {
            setState(() {
              opacity[i] = 1;
            });
          }
        });
      }
    } else {
      for (int i = 0; i < 5; i++) {
        setState(() {});
        Timer(Duration(milliseconds: 200 * (i + 1)), () {
          if (mounted) {
            setState(() {
              opacity[i] = 1;
            });
          }
        });
      }
      Timer(const Duration(milliseconds: 3000), () {
        for (int i = 0; i < 5; i++) {
          if (mounted) {
            setState(() {});
            Timer(Duration(milliseconds: 200 * (i + 1)), () {
              if (mounted) {
                setState(() {
                  opacity[i] = 0;
                });
              }
            });
          }
        }
      });

      Timer.periodic(const Duration(milliseconds: 6000), (timer) {
        for (int i = 0; i < 5; i++) {
          if (mounted) {
            setState(() {});
            Timer(Duration(milliseconds: 200 * (i + 1)), () {
              if (mounted) {
                setState(() {
                  opacity[i] = 1;
                });
              }
            });
          }
        }
      });
      Timer(const Duration(milliseconds: 3000), () {
        Timer.periodic(const Duration(milliseconds: 6000), (timer) {
          for (int i = 0; i < 5; i++) {
            if (mounted) {
              setState(() {});
              Timer(Duration(milliseconds: 200 * (i + 1)), () {
                if (mounted) {
                  setState(() {
                    opacity[i] = 0;
                  });
                }
              });
            }
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 10 * (widget.sizeMul ?? 1)),
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 40 * (widget.sizeMul ?? 1), top: 45 * (widget.sizeMul ?? 1)),
              child: SizedBox(
                width: 60 * (widget.sizeMul ?? 1),
                height: 60 * (widget.sizeMul ?? 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: opacity[4],
                  child: Image(
                    image: const AssetImage("assets/logopart.png"),
                    color: getColor("logo"),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 51.8 * (widget.sizeMul ?? 1), top: 6 * (widget.sizeMul ?? 1)),
              child: SizedBox(
                width: 60 * (widget.sizeMul ?? 1),
                height: 60 * (widget.sizeMul ?? 1),
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(284 / 360),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: opacity[0],
                    child: Image(
                      image: const AssetImage("assets/logopart.png"),
                      color: getColor("logo"),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -17 * (widget.sizeMul ?? 1),
              left: 19 * (widget.sizeMul ?? 1),
              child: SizedBox(
                width: 60 * (widget.sizeMul ?? 1),
                height: 60 * (widget.sizeMul ?? 1),
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(212 / 360),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: opacity[1],
                    child: Image(
                      image: const AssetImage("assets/logopart.png"),
                      color: getColor("logo"),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -13 * (widget.sizeMul ?? 1),
              top: 7 * (widget.sizeMul ?? 1),
              child: SizedBox(
                width: 60 * (widget.sizeMul ?? 1),
                height: 60 * (widget.sizeMul ?? 1),
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(142.5 / 360),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: opacity[2],
                    child: Image(
                      image: const AssetImage("assets/logopart.png"),
                      color: getColor("logo"),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -1 * (widget.sizeMul ?? 1),
              top: 44 * (widget.sizeMul ?? 1),
              child: SizedBox(
                width: 60 * (widget.sizeMul ?? 1),
                height: 60 * (widget.sizeMul ?? 1),
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(71 / 360),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: opacity[3],
                    child: Image(
                      image: const AssetImage("assets/logopart.png"),
                      color: getColor("logo"),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class LoadingView extends StatefulWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> {
  @override
  Widget build(BuildContext context) {
    final themeData = prefs?.getString("theme") ?? "";
    if (themeData.isNotEmpty && jsonDecode(themeData) != null) {
      currentTheme = jsonDecode(themeData);
    } else {
      currentTheme = dark;
    }
    return Scaffold(
      backgroundColor: getColor("background"),
      body: const Center(
        child: AnimatedLogo(sizeMul: 1.1),
      ),
    );
  }
}

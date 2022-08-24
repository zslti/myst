import 'dart:async';

import 'package:flutter/material.dart';

List<double> opacity = [0, 0, 0, 0, 0];
double sizeMul = 1;
bool stopAfterFirstCycle = false;

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
    sizeMul = widget.sizeMul ?? 1;
    stopAfterFirstCycle = widget.stopAfterFirstCycle ?? false;
    if (stopAfterFirstCycle) {
      for (int i = 0; i < 5; i++) {
        Timer(Duration(milliseconds: 300 * (i + 1)), () {
          setState(() {
            opacity[i] = 1;
          });
        });
      }
    } else {
      for (int i = 0; i < 5; i++) {
        setState(() {});
        Timer(Duration(milliseconds: 200 * (i + 1)), () {
          setState(() {
            opacity[i] = 1;
          });
        });
      }
      Timer(const Duration(milliseconds: 3000), () {
        for (int i = 0; i < 5; i++) {
          setState(() {});
          Timer(Duration(milliseconds: 200 * (i + 1)), () {
            setState(() {
              opacity[i] = 0;
            });
          });
        }
      });

      Timer.periodic(const Duration(milliseconds: 6000), (timer) {
        for (int i = 0; i < 5; i++) {
          setState(() {});
          Timer(Duration(milliseconds: 200 * (i + 1)), () {
            setState(() {
              opacity[i] = 1;
            });
          });
        }
      });
      Timer(const Duration(milliseconds: 3000), () {
        Timer.periodic(const Duration(milliseconds: 6000), (timer) {
          for (int i = 0; i < 5; i++) {
            setState(() {});
            Timer(Duration(milliseconds: 200 * (i + 1)), () {
              setState(() {
                opacity[i] = 0;
              });
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 40 * sizeMul, top: 45 * sizeMul),
          child: SizedBox(
            width: 60 * sizeMul,
            height: 60 * sizeMul,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: opacity[4],
              child: const Image(
                image: AssetImage("assets/logopart.png"),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 51.8 * sizeMul, top: 6 * sizeMul),
          child: SizedBox(
            width: 60 * sizeMul,
            height: 60 * sizeMul,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(284 / 360),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: opacity[0],
                child: const Image(
                  image: AssetImage("assets/logopart.png"),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -17 * sizeMul,
          left: 19 * sizeMul,
          child: SizedBox(
            width: 60 * sizeMul,
            height: 60 * sizeMul,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(212 / 360),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: opacity[1],
                child: const Image(
                  image: AssetImage("assets/logopart.png"),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -13 * sizeMul,
          top: 7 * sizeMul,
          child: SizedBox(
            width: 60 * sizeMul,
            height: 60 * sizeMul,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(142.5 / 360),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: opacity[2],
                child: const Image(
                  image: AssetImage("assets/logopart.png"),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -1 * sizeMul,
          top: 44 * sizeMul,
          child: SizedBox(
            width: 60 * sizeMul,
            height: 60 * sizeMul,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(71 / 360),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: opacity[3],
                child: const Image(
                  image: AssetImage("assets/logopart.png"),
                ),
              ),
            ),
          ),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: const [
          SizedBox(
            height: 100,
          ),
          AnimatedLogo(
            stopAfterFirstCycle: false,
            sizeMul: 2,
          ),
        ],
      ),
    );
  }
}

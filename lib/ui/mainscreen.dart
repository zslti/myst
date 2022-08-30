import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/util.dart';
import 'package:myst/ui/messages.dart';

bool isSliding = true, t = false;

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  @override
  Widget build(BuildContext context) {
    Timer(const Duration(milliseconds: 15), () {
      setState(() {});
    });
    if (!t) {
      Timer(const Duration(milliseconds: 50), () {
        t = true;
      });
    }
    return OverlappingPanels(
      main: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: t ? 1 : 0,
            child: Padding(
              padding: const EdgeInsets.only(top: 35),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    Scaffold(
                      backgroundColor: getColor("background2"),
                    ),
                    IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: isSliding ? 0.05 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Scaffold(
                          backgroundColor: Color.fromARGB(255, 78, 78, 78),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // ignore: prefer_const_constructors
      left: MessagesView(),
      right: Scaffold(
        backgroundColor: getColor("background"),
      ),
    );
  }
}

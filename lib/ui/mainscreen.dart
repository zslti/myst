import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/util.dart';
import 'package:myst/ui/conversations.dart';
import 'package:myst/ui/messages.dart';

bool isSliding = true, t = false;
GlobalKey<OverlappingPanelsState> _myKey = GlobalKey();
var gkey = _myKey;
RevealSide actualSide = RevealSide.left;

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
      onSideChange: (value) {
        actualSide = value;
      },
      key: _myKey,
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
                    // ignore: prefer_const_constructors
                    MessagesView(),
                    IgnorePointer(
                      ignoring: actualSide == RevealSide.main,
                      child: AnimatedOpacity(
                        opacity: isSliding ? 0.05 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: () {
                            if (actualSide == RevealSide.left) {
                              swipeDirection = RevealSide.right;
                              gkey.currentState?.onTranslate(
                                -50 * MediaQuery.of(context).size.width / 400,
                                shouldApplyTransition: true,
                              );
                            } else {
                              swipeDirection = RevealSide.left;
                              gkey.currentState?.onTranslate(
                                50 * MediaQuery.of(context).size.width / 400,
                                shouldApplyTransition: true,
                              );
                            }
                          },
                          child: const Scaffold(
                            backgroundColor: Color.fromARGB(255, 78, 78, 78),
                          ),
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
      left: ConversationsView(),
      right: Scaffold(
        backgroundColor: getColor("background"),
      ),
    );
  }
}

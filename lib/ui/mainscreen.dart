import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/userdata.dart';
import 'package:myst/data/util.dart';
import 'package:myst/ui/conversations.dart';
import 'package:myst/ui/loading.dart';
import 'package:myst/ui/messages.dart';

import 'friends.dart';

bool isSliding = true, t = false;
GlobalKey<OverlappingPanelsState> _myKey = GlobalKey();
var gkey = _myKey;
RevealSide actualSide = RevealSide.left;
bool shouldRebuild = true;
int selectedIndex = 0;
int lastNotificationAmountRequest = 0;
int friendRequestAmount = 0;

void slideToCenter() {
  swipeDirection = RevealSide.right;
  gkey.currentState?.onTranslate(
    -80,
    shouldApplyTransition: true,
  );
}

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  void getFriendRequestAmount() async {
    if (DateTime.now().millisecondsSinceEpoch - lastNotificationAmountRequest >
        1000) {
      lastNotificationAmountRequest = DateTime.now().millisecondsSinceEpoch;
      friendRequestAmount = (await getSentFriendRequests()).length +
          (await getFriendRequests()).length;
    }
  }

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(milliseconds: 50), () {
      if (shouldRebuild) {
        setState(() {});
      } else {
        Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
    if (!t) {
      Timer(const Duration(milliseconds: 50), () {
        t = true;
      });
    }
    getFriendRequestAmount();
    return Stack(
      children: [
        OverlappingPanels(
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
                                    -50 *
                                        MediaQuery.of(context).size.width /
                                        400,
                                    shouldApplyTransition: true,
                                  );
                                } else {
                                  swipeDirection = RevealSide.left;
                                  gkey.currentState?.onTranslate(
                                    50 *
                                        MediaQuery.of(context).size.width /
                                        400,
                                    shouldApplyTransition: true,
                                  );
                                }
                              },
                              child: const Scaffold(
                                backgroundColor:
                                    Color.fromARGB(255, 78, 78, 78),
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
        ),
        AnimatedAlign(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: actualSide == RevealSide.left && isSliding
              ? Alignment.bottomCenter
              : Alignment(0, 1.1 * MediaQuery.of(context).size.width / 300),
          child: Container(
            decoration: BoxDecoration(
              color: getColor("background"),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(
                    0,
                    -3,
                  ),
                ),
              ],
            ),
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    style: const ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    onPressed: () {
                      if (selectedIndex == 0) return;
                      selectedIndex = 0;
                      //push(context, const MainView());
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: selectedIndex == 0 ? 1 : 0.5,
                      // ignore: prefer_const_constructors
                      child: AnimatedLogo(
                        sizeMul: 0.3,
                        stopAfterFirstCycle: true,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: const ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    onPressed: () {
                      if (selectedIndex == 1) return;
                      selectedIndex = 1;
                      pushReplacement(context, const FriendsView());
                    },
                    child: Stack(
                      children: [
                        Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: selectedIndex == 1 ? 1 : 0.5,
                            child: Image.asset(
                              "assets/friends.png",
                              color: getColor("logo"),
                              height: 37,
                              width: 37,
                            ),
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0.1, 1),
                          child: NotificationBubble(
                            amount: friendRequestAmount,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class NotificationBubble extends StatefulWidget {
  const NotificationBubble({
    Key? key,
    this.size,
    this.fontSize,
    required this.amount,
  }) : super(key: key);
  final double? size;
  final int amount;
  final double? fontSize;

  @override
  State<NotificationBubble> createState() => _NotificationBubbleState();
}

class _NotificationBubbleState extends State<NotificationBubble> {
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.amount != 0 ? 1 : 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(50),
        ),
        child: Container(
          color: getColor("notification"),
          width: widget.size ?? 13,
          height: widget.size ?? 13,
          alignment: Alignment.center,
          child: Text(
            widget.amount.toString().length > 2
                ? "99+"
                : widget.amount.toString(),
            textAlign: TextAlign.center,
            style: getFont("mainfont")(
              color: getColor("secondarytext"),
              fontSize: widget.fontSize ?? 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

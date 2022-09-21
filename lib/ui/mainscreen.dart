import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/userdata.dart';
import 'package:myst/data/util.dart';
import 'package:myst/ui/conversations.dart';
import 'package:myst/ui/loading.dart';
import 'package:myst/ui/messages.dart';

import '../data/translation.dart';
import '../main.dart';
import 'friends.dart';
import 'selectlanguage.dart';
import 'selecttheme.dart';

bool isSliding = true, t = false;
GlobalKey<OverlappingPanelsState> _myKey = GlobalKey();
var gkey = _myKey;
RevealSide actualSide = RevealSide.left;
bool shouldRebuild = true;
int selectedIndex = 0;
int lastNotificationAmountRequest = 0;
int friendRequestAmount = 0;
String myStatus = "online", myProfilePicture = "", myDisplayName = "";
DraggableScrollableController scrollController =
    DraggableScrollableController();
double scrollSize = 0;
bool isScrolling = false;

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
  Future<void> getMyProfilePicture() async {
    myProfilePicture = await getProfilePicture(
      FirebaseAuth.instance.currentUser?.email ?? "",
    );
  }

  void getData() async {
    if (DateTime.now().millisecondsSinceEpoch - lastNotificationAmountRequest >
        1000) {
      lastNotificationAmountRequest = DateTime.now().millisecondsSinceEpoch;
      friendRequestAmount = (await getSentFriendRequests()).length +
          (await getFriendRequests()).length;
      myStatus = await getStatus(
        FirebaseAuth.instance.currentUser?.email ?? "",
      );

      myDisplayName = await getDisplayName(
        FirebaseAuth.instance.currentUser?.email ?? "",
      );
      getMyProfilePicture();
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
    if (scrollController.isAttached) {
      scrollSize = scrollController.size;
      if (scrollController.size < 0.3 &&
          scrollController.size > 0.01 &&
          !isScrolling) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    }
    getData();

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          },
          child: OverlappingPanels(
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
                      child: Builder(builder: (context) {
                        Timer(const Duration(milliseconds: 10), () {
                          setState(() {});
                        });
                        return const AnimatedLogo(
                          sizeMul: 0.3,
                          stopAfterFirstCycle: true,
                        );
                      }),
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
                          alignment: const Alignment(0.2, 1),
                          child: NotificationBubble(
                            amount: friendRequestAmount,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: const ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    onPressed: () {
                      //if (selectedIndex == 2) return;
                      //selectedIndex = 2;
                      //push(context, const MainView());
                      scrollController.animateTo(
                        0.5,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.ease,
                      );
                      isScrolling = true;
                      Timer(const Duration(milliseconds: 400), () {
                        isScrolling = false;
                      });
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: selectedIndex == 2 ? 1 : 0.5,
                      // ignore: prefer_const_constructors
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: ProfileImage(
                                url: myProfilePicture,
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: StatusIndicator(status: myStatus),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DraggableScrollableSheet(
          minChildSize: 0,
          initialChildSize: scrollSize,
          controller: scrollController,
          builder: (context, scrollController) {
            return SettingsView(
              scrollController: scrollController,
            );
          },
        )
      ],
    );
  }
}

bool isEditingUsername = false;
TextEditingController usernameController = TextEditingController();

class SettingsView extends StatefulWidget {
  const SettingsView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);
  final ScrollController scrollController;
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: getColor("background"),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(
                0,
                3,
              ),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Scaffold(
            backgroundColor: getColor("background"),
            body: ScrollConfiguration(
              behavior: MyBehavior(),
              child: Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.zero,
                    //shrinkWrap: true,
                    controller: widget.scrollController,
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          //color: getColor("background2"),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              spreadRadius: 3,
                              blurRadius: 10,
                              offset: const Offset(
                                0,
                                -5,
                              ),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    color: const Color.fromARGB(255, 0, 70, 75),
                                    child: const Center(
                                      child: Text("banner here"),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    color: getColor("background2"),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        height: 90,
                                        width: 90,
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              child: ProfileImage(
                                                url: myProfilePicture,
                                              ),
                                            ),
                                            Align(
                                              alignment:
                                                  const Alignment(0.85, 0.85),
                                              child: StatusIndicator(
                                                status: myStatus,
                                                size: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          updateProfilePicture(
                                            ImageSource.camera,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4.0,
                                            right: 4.0,
                                          ),
                                          child: Icon(
                                            Icons.camera_outlined,
                                            color: getColor("secondarytext"),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          updateProfilePicture(
                                            ImageSource.gallery,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4.0,
                                            right: 4.0,
                                          ),
                                          child: Icon(
                                            Icons.image_outlined,
                                            color: getColor("secondarytext"),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6.0,
                                      bottom: 8.0,
                                    ),
                                    child: Builder(builder: (context) {
                                      if (isEditingUsername) {
                                        return TextField(
                                          keyboardType:
                                              TextInputType.visiblePassword,
                                          textAlignVertical:
                                              const TextAlignVertical(
                                            y: -1,
                                          ),
                                          controller: usernameController,
                                          cursorColor: getColor("cursor"),
                                          cursorRadius:
                                              const Radius.circular(4),
                                          style: getFont("mainfont")(
                                            color: getColor("secondarytext"),
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            suffixIconConstraints:
                                                const BoxConstraints(
                                              maxWidth: 35,
                                            ),
                                            suffixIcon: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  myDisplayName =
                                                      usernameController.text
                                                          .trim();
                                                  isEditingUsername = false;
                                                });
                                                changeUsername(
                                                  FirebaseAuth.instance
                                                          .currentUser?.email ??
                                                      "",
                                                  myDisplayName,
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: Icon(
                                                  Icons.done,
                                                  color: getColor(
                                                    "secondarytext",
                                                  ),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            isDense: true,
                                            fillColor: getColor("background"),
                                            filled: true,
                                            hintText:
                                                translation[currentLanguage]
                                                    ["username"],
                                            hintStyle: getFont("mainfont")(
                                              color: getColor("secondarytext"),
                                              fontSize: 14,
                                              height: 1.3,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                        );
                                      }
                                      return RichText(
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(children: [
                                          TextSpan(
                                            text: myDisplayName.length > 25
                                                ? "${myDisplayName.substring(
                                                      0,
                                                      25,
                                                    ).trimRight()}..."
                                                : myDisplayName,
                                            style: getFont("mainfont")(
                                              color: getColor("maintext"),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          WidgetSpan(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  usernameController.text =
                                                      myDisplayName;
                                                  isEditingUsername = true;
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 4.0,
                                                ),
                                                child: Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                  color:
                                                      getColor("secondarytext"),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                      );
                                    }),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 8,
                        ),
                        child: Text(
                          translation[currentLanguage]["appsettings"],
                          style: getFont("mainfont")(
                            color: getColor("secondarytext"),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SettingButton(
                        icon: Image.asset(
                          "assets/language.png",
                          width: 20,
                          height: 20,
                          color: getColor("secondarytext"),
                        ),
                        text: translation[currentLanguage]["changelanguage"],
                        rightText: translation[currentLanguage]["languagename"],
                        onTap: () {
                          push(
                            context,
                            const SelectLanguageView(
                              shouldPop: true,
                            ),
                          );
                        },
                      ),
                      SettingButton(
                        icon: Image.asset(
                          "assets/language.png",
                          width: 20,
                          height: 20,
                          color: getColor("secondarytext"),
                        ),
                        text: translation[currentLanguage]["changetheme"],
                        rightText: currentTheme?["name"] ?? "",
                        onTap: () {
                          push(
                            context,
                            const SelectThemeView(
                              shouldPop: true,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 4,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: getColor("secondarytext").withOpacity(0.25),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingButton extends StatefulWidget {
  const SettingButton({
    Key? key,
    required this.icon,
    required this.text,
    this.rightText = "",
    required this.onTap,
  }) : super(key: key);
  final Widget icon;
  final String text;
  final String rightText;
  final Function onTap;
  @override
  State<SettingButton> createState() => _SettingButtonState();
}

class _SettingButtonState extends State<SettingButton> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: widget.onTap as void Function(),
      style: const ButtonStyle(
        splashFactory: NoSplash.splashFactory,
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: widget.icon,
          ),
          Text(
            widget.text,
            style: getFont("mainfont")(
              color: getColor("maintext"),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.rightText,
                  style: getFont("mainfont")(
                    color: getColor("secondarytext"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 2),
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: getColor("secondarytext"),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

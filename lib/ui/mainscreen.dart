// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/userdata.dart';
import 'package:myst/data/util.dart';
import 'package:myst/ui/conversations.dart';
import 'package:myst/ui/deleteaccount.dart';
import 'package:myst/ui/loading.dart';
import 'package:myst/ui/login.dart';
import 'package:myst/ui/messages.dart';
import 'package:myst/ui/passwordreset.dart';
import 'package:myst/ui/searchinconversation.dart';

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
String myStatus = "online", myProfilePicture = "", myDisplayName = "", myCustomStatus = "";
String bottomSheetProfileStatus = "online";
String bottomSheetProfileCustomStatus = "";
String bottomSheetProfileRealName = "";
List bottomSheetProfileMutualFriends = [];
DraggableScrollableController scrollController = DraggableScrollableController();
double scrollSize = 0;
bool isScrolling = false;
TextEditingController statusController = TextEditingController();
int lastSnackbarTime = 0;

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
    myProfilePicture = await getPicture(
      FirebaseAuth.instance.currentUser?.email ?? "",
    );
  }

  void getData() async {
    if (DateTime.now().millisecondsSinceEpoch - lastNotificationAmountRequest > 1000) {
      lastNotificationAmountRequest = DateTime.now().millisecondsSinceEpoch;
      friendRequestAmount = (await getSentFriendRequests()).length + (await getFriendRequests()).length;
      myStatus = await getStatus(
        FirebaseAuth.instance.currentUser?.email ?? "",
      );
      if (bottomSheetData["email"] != null && scrollSize != 0) {
        bottomSheetProfileStatus = await getStatus(bottomSheetData["email"]!);
        bottomSheetProfileCustomStatus = await getCustomStatus(bottomSheetData["email"]!);
        if (nicknameExists(bottomSheetData["email"])) {
          bottomSheetProfileRealName = await getDisplayName(bottomSheetData["email"]!, allowNickname: false);
        }
      }

      myDisplayName = await getDisplayName(
        FirebaseAuth.instance.currentUser?.email ?? "",
      );
      myCustomStatus = await getCustomStatus(
        FirebaseAuth.instance.currentUser?.email ?? "",
      );
      if (statusController.text.isEmpty) {
        statusController.text = myCustomStatus;
      }
      //statusController.text = myCustomStatus;
      getMyProfilePicture();
      List mutualFriends = await getMutualFriends(bottomSheetData["email"] ?? "");
      for (int i = 0; i < mutualFriends.length; i++) {
        mutualFriends[i] = {
          "email": mutualFriends[i],
          "displayname": await getDisplayName(mutualFriends[i]),
          "picture": await getPicture(mutualFriends[i]),
        };
      }
      bottomSheetProfileMutualFriends = mutualFriends;
    }
  }

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(milliseconds: 250), () {
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
      if (scrollController.size < 0.3 && scrollController.size > 0.01 && !isScrolling) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 275),
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
              duration: const Duration(milliseconds: 275),
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
                          MessagesView(),
                          IgnorePointer(
                            ignoring: actualSide == RevealSide.main,
                            child: AnimatedOpacity(
                              opacity: isSliding ? 0.015 : 0,
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
                                  backgroundColor: Color.fromARGB(255, 139, 139, 139),
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
            left: ConversationsView(),
            right: SearchInConversationView(),
          ),
        ),
        AnimatedAlign(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: (actualSide == RevealSide.left || actualSide == RevealSide.right) && isSliding
              ? Alignment.bottomCenter
              : Alignment(
                  0,
                  1.1 * MediaQuery.of(context).size.width / 300,
                ),
          child: Container(
            decoration: BoxDecoration(
              color: getColor("background"),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, -3),
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
                      // Navigator.of(context).pop();
                      // push(context, const FriendsView());
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
                      bottomSheetData = {};
                      scrollController.animateTo(
                        0.5,
                        duration: const Duration(milliseconds: 275),
                        curve: Curves.ease,
                      );
                      isScrolling = true;
                      Timer(const Duration(milliseconds: 275), () {
                        isScrolling = false;
                      });
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: selectedIndex == 2 ? 1 : 0.5,
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
Map bottomSheetData = {};
int bottomSheetFriendType = 0;

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
  Future<void> getBanner(String email) async {
    await getPicture(email, folder: "banners");
  }

  Future<void> getBottomSheetFriendType() async {
    if (bottomSheetData.isEmpty) return;
    List f = await getFriends(
      FirebaseAuth.instance.currentUser?.email ?? "",
    );
    if (f.contains(bottomSheetData["email"])) {
      bottomSheetFriendType = 1;
      return;
    }
    List requests = await getSentFriendRequests();
    if (requests.toString().contains(bottomSheetData["email"] ?? "")) {
      bottomSheetFriendType = 2;
      return;
    }
    bottomSheetFriendType = 0;
  }

  @override
  Widget build(BuildContext context) {
    bool isProfile = bottomSheetData["email"] != null;
    getBanner(isProfile ? bottomSheetData["email"] : FirebaseAuth.instance.currentUser?.email ?? "");
    getBottomSheetFriendType();
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
              offset: const Offset(0, 3),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Stack(
                                        children: [
                                          ProfileImage(
                                            url:
                                                bannerDownloadURLs[isProfile ? bottomSheetData["email"] : FirebaseAuth.instance.currentUser?.email] ??
                                                    "",
                                            type: "banners",
                                            username: bottomSheetData["email"] ?? "",
                                          ),
                                          Builder(builder: (context) {
                                            if (isProfile) return const SizedBox();
                                            return Align(
                                              alignment: Alignment.bottomRight,
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Opacity(
                                                  opacity: 0.5,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          updatePicture(
                                                            ImageSource.camera,
                                                            folder: "banners",
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
                                                          updatePicture(
                                                            ImageSource.gallery,
                                                            folder: "banners",
                                                          );
                                                        },
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(
                                                            left: 4.0,
                                                            right: 4.0,
                                                          ),
                                                          child: Icon(
                                                            Icons.image_outlined,
                                                            color: getColor(
                                                              "secondarytext",
                                                            ),
                                                            size: 24,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          })
                                        ],
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
                                  padding: const EdgeInsets.only(left: 16, right: 16),
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
                                                  borderRadius: BorderRadius.circular(50),
                                                  child: ProfileImage(
                                                    url: isProfile ? bottomSheetData["image"] : myProfilePicture,
                                                  ),
                                                ),
                                                Align(
                                                  alignment: const Alignment(0.85, 0.85),
                                                  child: StatusIndicator(
                                                    status: isProfile ? bottomSheetProfileStatus : myStatus,
                                                    size: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Builder(builder: (context) {
                                            if (isProfile) return const SizedBox();
                                            return Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    updatePicture(
                                                      ImageSource.camera,
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                                                    child: Icon(
                                                      Icons.camera_outlined,
                                                      color: getColor("secondarytext"),
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    updatePicture(
                                                      ImageSource.gallery,
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                                                    child: Icon(
                                                      Icons.image_outlined,
                                                      color: getColor("secondarytext"),
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
                                        child: Builder(builder: (context) {
                                          if (isEditingUsername) {
                                            return TextField(
                                              keyboardType: TextInputType.visiblePassword,
                                              textAlignVertical: const TextAlignVertical(y: -1),
                                              controller: usernameController,
                                              cursorColor: getColor("cursor"),
                                              cursorRadius: const Radius.circular(4),
                                              style: getFont("mainfont")(
                                                color: getColor("secondarytext"),
                                                fontSize: 14,
                                              ),
                                              decoration: InputDecoration(
                                                suffixIconConstraints: const BoxConstraints(
                                                  maxWidth: 35,
                                                ),
                                                suffixIcon: GestureDetector(
                                                  onTap: () {
                                                    String text = usernameController.text.trim();
                                                    if (bottomSheetData["email"] == null) {
                                                      setState(() {
                                                        myDisplayName = text;
                                                        isEditingUsername = false;
                                                      });
                                                      changeUsername(
                                                        FirebaseAuth.instance.currentUser?.email ?? "",
                                                        myDisplayName,
                                                      );
                                                    } else {
                                                      setState(() {
                                                        prefs?.setString('nicknameof${bottomSheetData["email"]}', text);
                                                        if (text.isNotEmpty) {
                                                          bottomSheetData["displayname"] = text;
                                                        } else {
                                                          bottomSheetData["displayname"] = bottomSheetProfileRealName;
                                                        }
                                                        isEditingUsername = false;
                                                      });
                                                    }
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      Icons.done,
                                                      color: getColor("secondarytext"),
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                                isDense: true,
                                                fillColor: getColor("background"),
                                                filled: true,
                                                hintText: translation[currentLanguage]["username"],
                                                hintStyle: getFont("mainfont")(
                                                  color: getColor("secondarytext"),
                                                  fontSize: 14,
                                                  height: 1.3,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                            );
                                          }
                                          String displayName = isProfile ? bottomSheetData["displayname"] : myDisplayName;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                overflow: TextOverflow.ellipsis,
                                                text: TextSpan(children: [
                                                  TextSpan(
                                                    text: displayName.length > 25 ? "${displayName.substring(0, 25).trimRight()}..." : displayName,
                                                    style: getFont("mainfont")(
                                                      color: getColor("maintext"),
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: isProfile &&
                                                            bottomSheetProfileRealName.isNotEmpty &&
                                                            bottomSheetProfileRealName != bottomSheetData["displayname"]
                                                        ? " AKA $bottomSheetProfileRealName"
                                                        : "",
                                                    style: getFont("mainfont")(
                                                      color: getColor("secondarytext"),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  WidgetSpan(
                                                    child: Builder(builder: (context) {
                                                      if (isProfile) {
                                                        return const SizedBox();
                                                      }
                                                      return GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            usernameController.text = myDisplayName;
                                                            isEditingUsername = true;
                                                          });
                                                        },
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(left: 4.0),
                                                          child: Icon(
                                                            Icons.edit,
                                                            size: 20,
                                                            color: getColor("secondarytext"),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                ]),
                                              ),
                                              Builder(builder: (context) {
                                                if (!isProfile || bottomSheetData["email"] == FirebaseAuth.instance.currentUser?.email) {
                                                  return const SizedBox();
                                                }
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      usernameController.text = bottomSheetData["displayname"];
                                                      isEditingUsername = true;
                                                    });
                                                  },
                                                  child: Text(
                                                    translation[currentLanguage]["setnickname"],
                                                    style: getFont("mainfont")(
                                                      color: getColor("secondarytext"),
                                                    ),
                                                  ),
                                                );
                                              })
                                            ],
                                          );
                                        }),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Builder(builder: (context) {
                            if (bottomSheetProfileCustomStatus.isEmpty || !isProfile) {
                              return const SizedBox();
                            }
                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: getColor("background2"),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
                                child: Text(
                                  //bottomSheetProfileCustomStatus.substring(0, min(bottomSheetProfileCustomStatus.length, 200)),
                                  bottomSheetProfileCustomStatus.length > 200
                                      ? "${bottomSheetProfileCustomStatus.substring(0, 200).trim()}..."
                                      : bottomSheetProfileCustomStatus,
                                  style: getFont("mainfont")(
                                    color: getColor("secondarytext"),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          })
                        ],
                      ),
                      Builder(builder: (context) {
                        if (isProfile) {
                          return Builder(builder: (context) {
                            if (bottomSheetData["email"] == FirebaseAuth.instance.currentUser?.email) {
                              return const SizedBox();
                            }
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    //color: getColor("background"),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        spreadRadius: 5,
                                        blurRadius: 7,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            currentConversation = {
                                              "email": bottomSheetData["email"],
                                              "displayname": bottomSheetData["displayname"],
                                              "status": bottomSheetProfileStatus,
                                            };
                                            selectedIndex = 0;
                                            if (scrollController.isAttached) {
                                              scrollController.animateTo(
                                                0,
                                                duration: const Duration(milliseconds: 275),
                                                curve: Curves.ease,
                                              );
                                            }
                                            if (scrollController2.isAttached) {
                                              scrollController2.animateTo(
                                                0,
                                                duration: const Duration(milliseconds: 275),
                                                curve: Curves.ease,
                                              );
                                            }
                                            if (!(bottomSheetData["needslide"] ?? true)) {
                                              return;
                                            }
                                            Timer(const Duration(milliseconds: 500), () {
                                              slideToCenter();
                                            });
                                            if ((bottomSheetData["currentpage"] ?? "") == "main") {
                                              return;
                                            }
                                            pushReplacement(
                                              context,
                                              const MainView(),
                                            );
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            height: 70,
                                            color: getColor("background3"),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.messenger_outline,
                                                  color: getColor("secondarytext"),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  translation[currentLanguage]["sendmessage"],
                                                  style: getFont("mainfont")(
                                                    color: getColor("secondarytext"),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Builder(builder: (context) {
                                          if (bottomSheetFriendType == 0) {
                                            return GestureDetector(
                                              onTap: () {
                                                sendFriendRequest(
                                                  bottomSheetData["email"],
                                                );
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                height: 70,
                                                color: getColor("background3"),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.person_add_alt_1_outlined,
                                                      color: getColor("secondarytext"),
                                                    ),
                                                    SizedBox(height: 2),
                                                    Text(
                                                      translation[currentLanguage]["sendfriendrequest"],
                                                      style: getFont("mainfont")(
                                                        color: getColor("secondarytext"),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          } else if (bottomSheetFriendType == 1) {
                                            return GestureDetector(
                                              onTap: () {
                                                removeFriend(bottomSheetData["email"]);
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                height: 70,
                                                color: getColor("background3"),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.person_remove_alt_1_outlined,
                                                      color: getColor("secondarytext"),
                                                    ),
                                                    SizedBox(height: 2),
                                                    Text(
                                                      translation[currentLanguage]["removefriend"],
                                                      style: getFont("mainfont")(
                                                        color: getColor("secondarytext"),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                          return Container(
                                            width: double.infinity,
                                            height: 70,
                                            color: getColor("background3"),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  "assets/friendadded.png",
                                                  width: 21,
                                                  height: 21,
                                                  color: getColor("secondarytext"),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  translation[currentLanguage]["friendrequestsent"],
                                                  style: getFont("mainfont")(
                                                    color: getColor("secondarytext"),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                SettingButton(
                                  icon: Image.asset(
                                    "assets/friends.png",
                                    width: 24,
                                    height: 24,
                                    color: getColor("secondarytext"),
                                  ),
                                  text: translation[currentLanguage]["mutualfriends"],
                                  padding: EdgeInsets.only(left: 10, right: 8),
                                  isOpenable: true,
                                  openableWidgetId: 3,
                                  openedWidgets: [
                                    Builder(builder: (context) {
                                      if (bottomSheetProfileMutualFriends.isNotEmpty) {
                                        return const SizedBox();
                                      }
                                      return Opacity(
                                        opacity: 0.5,
                                        child: Text(
                                          translation[currentLanguage]["nomutualfriends"],
                                          style: getFont("mainfont")(
                                            color: getColor("secondarytext"),
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }),
                                    for (final friend in bottomSheetProfileMutualFriends)
                                      SettingButton(
                                        icon: ClipRRect(
                                          borderRadius: BorderRadius.circular(100),
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: ProfileImage(url: friend["picture"] ?? ""),
                                          ),
                                        ),
                                        text: friend["displayname"],
                                        onTap: () {
                                          // bottomSheetData = {
                                          //   "email": friend["email"],
                                          //   "displayname": friend["displayname"],
                                          //   "image": friend["picture"],
                                          // };
                                          bottomSheetData["email"] = friend["email"];
                                          bottomSheetData["displayname"] = friend["displayname"];
                                          bottomSheetData["image"] = friend["picture"];
                                          bottomSheetProfileCustomStatus = bottomSheetProfileRealName = "";
                                          bottomSheetProfileMutualFriends = [];
                                          openableWidgetStates[3]["state"] = false;
                                        },
                                      )
                                  ],
                                ),
                              ],
                            );
                          });
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SettingButton(
                              icon: Image.asset(
                                "assets/status.png",
                                width: 20,
                                height: 20,
                                color: getColor("secondarytext"),
                              ),
                              text: translation[currentLanguage]["setstatus"],
                              rightText: translation[currentLanguage][prefs?.getString("status") ?? "online"],
                              isOpenable: true,
                              openableWidgetId: 0,
                              // ignore: prefer_const_literals_to_create_immutables
                              openedWidgets: [
                                ChangeStatusButton(status: "online"),
                                ChangeStatusButton(status: "away"),
                                ChangeStatusButton(status: "busy"),
                                ChangeStatusButton(status: "invisible"),
                                Padding(
                                  padding: const EdgeInsets.only(left: 6.0),
                                  child: TextField(
                                    onChanged: (value) {
                                      setCustomStatus(value);
                                    },
                                    textAlignVertical: const TextAlignVertical(y: -1),
                                    controller: statusController,
                                    cursorColor: getColor("cursor"),
                                    cursorRadius: const Radius.circular(4),
                                    style: getFont("mainfont")(
                                      color: getColor("secondarytext"),
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      suffixIconConstraints: const BoxConstraints(
                                        maxWidth: 35,
                                      ),
                                      isDense: true,
                                      fillColor: getColor("background"),
                                      filled: true,
                                      hintText: translation[currentLanguage]["setcustomstatus"],
                                      hintStyle: getFont("mainfont")(
                                        color: getColor("secondarytext"),
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 18.0),
                                  child: RichText(
                                    text: TextSpan(children: [
                                      TextSpan(
                                        text: translation[currentLanguage]["setcustomstatustext"],
                                        style: getFont("mainfont")(
                                          color: getColor("secondarytext"),
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' ${translation[currentLanguage]["setcustomstatustext2"]}',
                                        style: getFont("mainfont")(
                                          color: getColor("maintext"),
                                          fontSize: 12,
                                          //fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            String quote = (await getRandomQuote())[0];
                                            if (quote.isEmpty) {
                                              if (DateTime.now().millisecondsSinceEpoch - lastSnackbarTime < 5000) {
                                                return;
                                              }
                                              lastSnackbarTime = DateTime.now().millisecondsSinceEpoch;
                                              // ignore: use_build_context_synchronously
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: getColor("background"),
                                                  content: Text(
                                                    translation[currentLanguage]["toomanyrequests"],
                                                    style: getFont("mainfont")(
                                                      color: getColor("maintext"),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              statusController.text = quote;
                                              setCustomStatus(quote);
                                            }
                                          },
                                      ),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                            SettingButton(
                              icon: Icon(
                                Icons.person_outline,
                                color: getColor("secondarytext"),
                              ),
                              padding: const EdgeInsets.only(left: 6.0, right: 8.0),
                              text: translation[currentLanguage]["accountsettings"],
                              isOpenable: true,
                              openableWidgetId: 1,
                              // ignore: prefer_const_literals_to_create_immutables
                              openedWidgets: [
                                SettingButton(
                                  padding: EdgeInsets.only(left: 8),
                                  icon: SizedBox(),
                                  text: translation[currentLanguage]["username"],
                                  showArrow: false,
                                  rightText: myDisplayName,
                                ),
                                SettingButton(
                                  padding: EdgeInsets.only(left: 8),
                                  icon: SizedBox(),
                                  text: translation[currentLanguage]["email"],
                                  showArrow: false,
                                  rightText: FirebaseAuth.instance.currentUser?.email ?? "",
                                ),
                                SettingButton(
                                  padding: EdgeInsets.only(left: 8),
                                  icon: SizedBox(),
                                  text: translation[currentLanguage]["resetpassword"],
                                  onTap: () {
                                    push(context, PasswordResetView(textType: "2"));
                                  },
                                ),
                                SettingButton(
                                  padding: EdgeInsets.only(left: 8),
                                  icon: SizedBox(),
                                  text: translation[currentLanguage]["signout"],
                                  onTap: () {
                                    showCustomDialog(
                                      context,
                                      translation[currentLanguage]["signout"],
                                      translation[currentLanguage]["signouttext"],
                                      [
                                        TextButton(
                                          child: Text(
                                            translation[currentLanguage]["signout"],
                                            style: getFont("mainfont")(
                                              fontSize: 14,
                                              color: getColor("secondarytext"),
                                            ),
                                          ),
                                          onPressed: () {
                                            FirebaseAuth.instance.signOut();
                                            prefs?.setString("user", "");
                                            Navigator.pop(context);
                                            pushReplacement(
                                              context,
                                              LoginView(),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                SettingButton(
                                  padding: EdgeInsets.only(left: 8),
                                  icon: SizedBox(),
                                  text: translation[currentLanguage]["deleteaccount"],
                                  onTap: () {
                                    push(context, DeleteAccountView());
                                  },
                                ),
                              ],
                            ),
                            SettingButton(
                              icon: Icon(
                                Icons.devices,
                                color: getColor("secondarytext"),
                                size: 20,
                              ),
                              text: translation[currentLanguage]["devices"],
                              isOpenable: true,
                              openableWidgetId: 2,
                              // ignore: prefer_const_literals_to_create_immutables
                              openedWidgets: [
                                FutureBuilder(
                                    future: getSignedinDevices(),
                                    builder: (context, snapshot) {
                                      if (signedinDevices.isEmpty) {
                                        return const SizedBox();
                                      }
                                      return Column(
                                        children: [
                                          SettingButton(
                                            icon: Image.asset(
                                              "assets/phone.png",
                                              width: 22,
                                              height: 22,
                                              color: getColor("secondarytext"),
                                            ),
                                            text:
                                                '${signedinDevices["currentDevice"]["phonename"]} - ${signedinDevices["currentDevice"]["platform"]}',
                                            secondaryText: translation[currentLanguage]["thisdevice"],
                                            showArrow: false,
                                          ),
                                          for (final device in signedinDevices["otherDevices"] ?? [])
                                            Builder(builder: (context) {
                                              if (device["forcelogout"] ?? false) {
                                                return const SizedBox();
                                              }
                                              return SettingButton(
                                                icon: Image.asset(
                                                  "assets/phone.png",
                                                  width: 22,
                                                  height: 22,
                                                  color: getColor("secondarytext"),
                                                ),
                                                text: '${device["phonename"]} - ${device["platform"]}',
                                                secondaryText:
                                                    '${translation[currentLanguage]["lastseen"]} ${timestampToDate(device["lastlogin"])}\n${device["location"]}',
                                                showArrow: false,
                                              );
                                            }),
                                          Builder(builder: (context) {
                                            bool devicesAlreadyLoggedOut = false;
                                            for (int i = 0; i < (signedinDevices["otherDevices"] ?? []).length; i++) {
                                              if (signedinDevices["otherDevices"][i]["forcelogout"] ?? false) {
                                                devicesAlreadyLoggedOut = true;
                                                break;
                                              }
                                            }
                                            if (devicesAlreadyLoggedOut) {
                                              return const SizedBox();
                                            }
                                            return SettingButton(
                                              icon: Icon(
                                                Icons.logout,
                                                color: getColor("secondarytext"),
                                                size: 22,
                                              ),
                                              text: translation[currentLanguage]["signoutdevices"],
                                              padding: EdgeInsets.only(left: 10, right: 8),
                                              onTap: () {
                                                showCustomDialog(
                                                  context,
                                                  translation[currentLanguage]["signoutdevices"],
                                                  translation[currentLanguage]["signoutdevicestext"],
                                                  [
                                                    TextButton(
                                                      child: Text(
                                                        translation[currentLanguage]["signout"],
                                                        style: getFont("mainfont")(
                                                          fontSize: 14,
                                                          color: getColor("secondarytext"),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        logoutAllDevices();
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          })
                                        ],
                                      );
                                    }),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
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
                                push(context, const SelectLanguageView(shouldPop: true));
                              },
                            ),
                            SettingButton(
                              icon: Image.asset(
                                "assets/theme.png",
                                width: 20,
                                height: 20,
                                color: getColor("secondarytext"),
                              ),
                              text: translation[currentLanguage]["changetheme"],
                              rightText: currentTheme?["name"] ?? "",
                              onTap: () {
                                push(context, const SelectThemeView(shouldPop: true));
                              },
                            ),
                          ],
                        );
                      }),
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

class ChangeStatusButton extends StatefulWidget {
  const ChangeStatusButton({
    Key? key,
    required this.status,
  }) : super(key: key);
  final String status;
  @override
  State<ChangeStatusButton> createState() => _ChangeStatusButtonState();
}

class _ChangeStatusButtonState extends State<ChangeStatusButton> {
  @override
  Widget build(BuildContext context) {
    return SettingButton(
      icon: StatusIndicator(
        status: widget.status,
        size: 12,
      ),
      text: translation[currentLanguage][widget.status],
      showArrow: false,
      onTap: () {
        prefs?.setString("status", widget.status);
        updateStatus();
        openableWidgetStates[0]["state"] = false;
      },
    );
  }
}

Map openableWidgetStates = {};

class SettingButton extends StatefulWidget {
  const SettingButton({
    Key? key,
    required this.icon,
    required this.text,
    this.secondaryText = "",
    this.rightText = "",
    this.onTap,
    this.isOpenable = false,
    this.openedWidgets = const [],
    this.openableWidgetId = -1,
    this.showArrow = true,
    this.padding = const EdgeInsets.only(left: 8, right: 8),
    this.hasShaderMask = true,
    this.openSpeed = 0.05,
  }) : super(key: key);
  final Widget icon;
  final String text;
  final String secondaryText;
  final String rightText;
  final Function? onTap;
  final bool isOpenable;
  final List<Widget> openedWidgets;
  final int openableWidgetId;
  final bool showArrow;
  final EdgeInsets padding;
  final bool hasShaderMask;
  final double openSpeed;
  @override
  State<SettingButton> createState() => _SettingButtonState();
}

class _SettingButtonState extends State<SettingButton> {
  @override
  Widget build(BuildContext context) {
    if (widget.isOpenable) {
      Timer(const Duration(milliseconds: 10), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
    openableWidgetStates[widget.openableWidgetId] ??= {"state": false, "progress": 0};
    double progressModifier = widget.openSpeed * (openableWidgetStates[widget.openableWidgetId]?["state"] ?? false ? 1 : -1);
    openableWidgetStates[widget.openableWidgetId]["progress"] = (openableWidgetStates[widget.openableWidgetId]["progress"] ?? 0) + progressModifier;
    if (openableWidgetStates[widget.openableWidgetId]["progress"] >= 1) {
      openableWidgetStates[widget.openableWidgetId]["progress"] = 1;
    } else if (openableWidgetStates[widget.openableWidgetId]["progress"] <= 0) {
      openableWidgetStates[widget.openableWidgetId]["progress"] = 0;
    }
    double progress = Curves.easeInOut.transform(
      openableWidgetStates[widget.openableWidgetId]["progress"] * 1.0,
    );
    return Column(
      children: [
        TextButton(
          onPressed: widget.onTap != null && !widget.isOpenable
              ? widget.onTap as void Function()
              : () {
                  openableWidgetStates[widget.openableWidgetId]["state"] = !(openableWidgetStates[widget.openableWidgetId]["state"] ?? false);
                },
          style: const ButtonStyle(
            splashFactory: NoSplash.splashFactory,
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            children: [
              Padding(
                padding: widget.padding,
                child: widget.icon,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 165,
                    ),
                    child: Text(
                      widget.text,
                      overflow: TextOverflow.ellipsis,
                      style: getFont("mainfont")(
                        color: getColor("maintext"),
                      ),
                    ),
                  ),
                  Builder(builder: (context) {
                    if (widget.secondaryText.isEmpty) {
                      return const SizedBox();
                    }
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 160,
                      ),
                      child: Text(
                        widget.secondaryText,
                        overflow: TextOverflow.ellipsis,
                        style: getFont("mainfont")(
                          color: getColor("secondarytext"),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              SizedBox(width: 40),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          widget.rightText,
                          overflow: TextOverflow.ellipsis,
                          style: getFont("mainfont")(
                            color: getColor("secondarytext"),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, right: 2),
                      child: Builder(builder: (context) {
                        if (!widget.showArrow) {
                          return const SizedBox();
                        }
                        return RotationTransition(
                          turns: widget.isOpenable ? AlwaysStoppedAnimation(90 * progress / 360) : const AlwaysStoppedAnimation(0),
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: getColor("secondarytext"),
                              size: 16,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (Rect rect) {
            if (!widget.hasShaderMask) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ).createShader(rect);
            }
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(220),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withAlpha(220),
              ],
              stops: const [0.0, 0.15, 0.85, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstOut,
          child: SizeTransition(
            sizeFactor: AlwaysStoppedAnimation(progress),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ...widget.openedWidgets
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(left: 28, right: 8),
                        child: e,
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
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
            widget.amount.toString().length > 2 ? "99+" : widget.amount.toString(),
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

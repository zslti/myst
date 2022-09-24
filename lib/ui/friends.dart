import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/userdata.dart';
import 'package:myst/ui/conversations.dart';

import '../data/translation.dart';
import '../data/util.dart';
import '../main.dart';
import 'addfriends.dart';
import 'loading.dart';
import 'mainscreen.dart';
import 'messages.dart';

List outgoingRequests = [];
List incomingRequests = [];
Map displayNames = {};
Map statuses = {};
Map profilePictures = {};
List friends = [];
int unreadMessages = 0;
DraggableScrollableController scrollController =
    DraggableScrollableController();
DraggableScrollableController scrollController2 =
    DraggableScrollableController();
double scrollSize = 0;
bool isScrolling = false;

class FriendsView extends StatefulWidget {
  const FriendsView({Key? key}) : super(key: key);

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

//LsUdPipRPnXuntsWHbPg9g==
//1662660194535
//{{fulop.zsolt.2004@gmail.com}, {sndffsdfds}}

class _FriendsViewState extends State<FriendsView> {
  void getData() async {
    incomingRequests = await getFriendRequests();
    outgoingRequests = await getSentFriendRequests();

    List f = await getFriends(FirebaseAuth.instance.currentUser?.email ?? "");
    friends = f.toSet().toList();
    for (final friend in friends) {
      displayNames[friend] = await getDisplayName(friend);
      statuses[friend] = await getStatus(friend);
      profilePictures[friend] = await getPicture(friend);
    }

    unreadMessages = await getUnreadMessages();
    myStatus = await getStatus(FirebaseAuth.instance.currentUser?.email ?? "");
    if (bottomSheetData["email"] != null && scrollSize != 0) {
      bottomSheetProfileStatus = await getStatus(bottomSheetData["email"]!);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {});
      }
    });
    getData();
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: getColor("background2"),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 80,
              bottom: 50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FriendRequestButton(
                  text: translation[currentLanguage]["incomingrequests"],
                  requests: incomingRequests,
                  options: const [
                    FriendRequestOption.accept,
                    FriendRequestOption.decline
                  ],
                ),
                FriendRequestButton(
                  text: translation[currentLanguage]["outgoingrequests"],
                  requests: outgoingRequests,
                  options: const [
                    FriendRequestOption.cancel,
                  ],
                ),
                ScrollConfiguration(
                  behavior: MyBehavior(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 263,
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: ShaderMask(
                        shaderCallback: (Rect rect) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(220),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withAlpha(220),
                            ],
                            stops: const [0.0, 0.06, 0.875, 1.0],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstOut,
                        child: Builder(builder: (context) {
                          List onlineFriends = friends;
                          List offlineFriends = friends;
                          onlineFriends = onlineFriends
                              .where(
                                (element) => statuses[element] != "offline",
                              )
                              .toList();
                          offlineFriends = offlineFriends
                              .where(
                                (element) => statuses[element] == "offline",
                              )
                              .toList();
                          return ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${translation[currentLanguage]["online"]} - ${onlineFriends.length}',
                                  style: getFont("mainfont")(
                                    color: getColor("secondarytext"),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              for (final friend in onlineFriends)
                                Friend(
                                  friend: friend,
                                ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${translation[currentLanguage]["offline"]} - ${offlineFriends.length}',
                                  style: getFont("mainfont")(
                                    color: getColor("secondarytext"),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              for (final friend in offlineFriends)
                                Friend(
                                  friend: friend,
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 73,
            decoration: BoxDecoration(
              color: getColor("background3"),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(
                    0,
                    3,
                  ),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: const Alignment(0, 0.6),
                    child: Text(
                      translation[currentLanguage]["friends"],
                      style: getFont("mainfont")(
                        color: getColor("maintext"),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: const Alignment(1, 0.6),
                      child: GestureDetector(
                        onTap: () {
                          push(context, const AddFriendsView());
                        },
                        child: Icon(
                          Icons.person_add_alt_1_outlined,
                          color: getColor("secondarytext"),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
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
                        push(context, const MainView());
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
                        //pushReplacement(context, const FriendsView());
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
                        bottomSheetData = {};
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
          ),
        ],
      ),
    );
  }
}

class Friend extends StatefulWidget {
  const Friend({
    Key? key,
    required this.friend,
  }) : super(key: key);
  final String friend;

  @override
  State<Friend> createState() => _FriendState();
}

class _FriendState extends State<Friend> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onLongPress: () {
        bottomSheetData = {
          "email": widget.friend,
          "displayname": displayNames[widget.friend],
          "image": profilePictures[widget.friend] ?? "",
        };
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
      onPressed: () {
        currentConversation = {
          "email": widget.friend,
          "displayname": displayNames[widget.friend],
          "status": statuses[widget.friend],
        };
        Timer(
          const Duration(milliseconds: 500),
          () {
            slideToCenter();
          },
        );
        selectedIndex = 0;
        pushReplacement(
          context,
          const MainView(),
        );
      },
      style: const ButtonStyle(
        splashFactory: NoSplash.splashFactory,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  50,
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: ProfileImage(
                    url: profilePictures[widget.friend] ?? "",
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.bottomRight,
                child: StatusIndicator(
                  status: statuses[widget.friend] ?? "offline",
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              displayNames[widget.friend] ?? "",
              overflow: TextOverflow.ellipsis,
              style: getFont("mainfont")(
                color: getColor("secondarytext"),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class FriendRequestButton extends StatefulWidget {
  const FriendRequestButton({
    Key? key,
    required this.text,
    required this.requests,
    required this.options,
  }) : super(key: key);
  final String text;
  final List requests;
  final List<FriendRequestOption> options;

  @override
  State<FriendRequestButton> createState() => _FriendRequestButtonState();
}

class _FriendRequestButtonState extends State<FriendRequestButton> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      child: TextButton(
        onPressed: () {
          push(
            context,
            FriendRequestsView(
              text: widget.text,
              requests: widget.requests,
              options: widget.options,
            ),
          );
        },
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          backgroundColor: getColor("background"),
        ),
        child: Row(
          children: [
            Text(
              widget.text,
              style: getFont("mainfont")(
                color: getColor("secondarytext"),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: NotificationBubble(
                  amount: widget.requests.length,
                  fontSize: 9.5,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class FriendRequestsView extends StatefulWidget {
  FriendRequestsView({
    Key? key,
    required this.text,
    required this.requests,
    required this.options,
  }) : super(key: key);
  final String text;
  List requests;
  final List<FriendRequestOption> options;

  @override
  State<FriendRequestsView> createState() => _FriendRequestsViewState();
}

class _FriendRequestsViewState extends State<FriendRequestsView> {
  @override
  Widget build(BuildContext context) {
    Timer(const Duration(milliseconds: 100), () {
      widget.requests =
          widget.text == translation[currentLanguage]["incomingrequests"]
              ? incomingRequests
              : outgoingRequests;
      if (mounted) {
        setState(() {});
      }
    });
    if (scrollController2.isAttached) {
      scrollSize = scrollController2.size;
      if (scrollController2.size < 0.3 &&
          scrollController2.size > 0.01 &&
          !isScrolling) {
        scrollController2.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    }
    return Scaffold(
      backgroundColor: getColor("background2"),
      body: ScrollConfiguration(
        behavior: MyBehavior(),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                scrollController2.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.ease,
                );
              },
              child: Builder(builder: (context) {
                if (widget.requests.isEmpty) {
                  return Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        widget.text ==
                                translation[currentLanguage]["incomingrequests"]
                            ? translation[currentLanguage]["noincomingrequests"]
                            : translation[currentLanguage]
                                ["nooutgoingrequests"],
                        style: getFont("mainfont")(
                          color: getColor("secondarytext"),
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 55),
                  child: ListView(
                    children: [
                      for (final request in widget.requests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FriendRequest(
                            request: request,
                            options: widget.options,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 73,
              decoration: BoxDecoration(
                color: getColor("background3"),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(
                      0,
                      3,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Align(
                          alignment: const Alignment(0, 0.525),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: getColor("secondarytext"),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.6),
                      child: Text(
                        widget.text,
                        style: getFont("mainfont")(
                          color: getColor("maintext"),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
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
                          push(context, const MainView());
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
                          //pushReplacement(context, const FriendsView());
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
                          bottomSheetData = {};
                          scrollController2.animateTo(
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
              controller: scrollController2,
              builder: (context, scrollController) {
                return SettingsView(
                  scrollController: scrollController,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum FriendRequestOption { accept, decline, cancel }

class FriendRequest extends StatefulWidget {
  const FriendRequest({Key? key, required this.request, required this.options})
      : super(key: key);
  final Map request;
  final List<FriendRequestOption> options;

  @override
  State<FriendRequest> createState() => _FriendRequestState();
}

class _FriendRequestState extends State<FriendRequest> {
  Future<String> getRequestDisplayName() async {
    List users = [widget.request["sender"], widget.request["receiver"]];
    users.removeWhere(
        (element) => element == FirebaseAuth.instance.currentUser?.email);
    String name = await getDisplayName(users[0]);
    displayNames[users[0]] = name;
    profilePictures[users[0]] = await getPicture(users[0]);
    if (bottomSheetData["email"] != null && scrollSize != 0) {
      bottomSheetProfileStatus = await getStatus(bottomSheetData["email"]!);
    }
    if (mounted) {
      setState(() {});
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    getRequestDisplayName();
    return GestureDetector(
      onLongPress: () {
        bottomSheetData = {
          "email": widget.options.contains(FriendRequestOption.accept)
              ? widget.request['sender'] ?? ""
              : widget.request['receiver'] ?? "",
          "displayname": widget.options.contains(FriendRequestOption.accept)
              ? displayNames[widget.request["sender"]] ?? ""
              : displayNames[widget.request["receiver"]] ?? "",
          "image": widget.options.contains(FriendRequestOption.accept)
              ? profilePictures[widget.request['sender']] ?? ""
              : profilePictures[widget.request['receiver']] ?? "",
        };
        scrollController2.animateTo(
          0.5,
          duration: const Duration(milliseconds: 400),
          curve: Curves.ease,
        );
        isScrolling = true;
        Timer(const Duration(milliseconds: 400), () {
          isScrolling = false;
        });
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              50,
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: ProfileImage(
                url: widget.options.contains(FriendRequestOption.accept)
                    ? profilePictures[widget.request['sender']] ?? ""
                    : profilePictures[widget.request['receiver']] ?? "",
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Stack(
              children: [
                Text(
                  widget.options.contains(FriendRequestOption.accept)
                      ? displayNames[widget.request["sender"]] ?? ""
                      : displayNames[widget.request["receiver"]] ?? "",
                  overflow: TextOverflow.ellipsis,
                  style: getFont("mainfont")(
                    color: getColor(
                      "secondarytext",
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              for (final option in widget.options)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: GestureDetector(
                    onTap: () async {
                      if (option == FriendRequestOption.accept) {
                        await acceptFriendRequest(widget.request);
                        incomingRequests.remove(widget.request);
                        setState(() {});
                      } else {
                        await rejectFriendRequest(widget.request);
                        incomingRequests.remove(widget.request);
                        setState(() {});
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: getColor("background"),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: (option == FriendRequestOption.accept
                                    ? getColor("positive")
                                    : getColor("negative"))
                                .withOpacity(0.7),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(
                              0,
                              0,
                            ),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          option == FriendRequestOption.accept
                              ? Icons.check
                              : Icons.close,
                          color: option == FriendRequestOption.accept
                              ? getColor("positive")
                              : getColor("negative"),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }
}

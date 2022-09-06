import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/userdata.dart';

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
List friends = [];

class FriendsView extends StatefulWidget {
  const FriendsView({Key? key}) : super(key: key);

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  void getData() async {
    incomingRequests = await getFriendRequests();
    outgoingRequests = await getSentFriendRequests();

    List f = await getFriends(FirebaseAuth.instance.currentUser?.email ?? "");
    friends = f.toSet().toList();
    for (final friend in friends) {
      displayNames[friend] = await getDisplayName(friend);
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
      setState(() {});
    });
    getData();
    return Scaffold(
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${translation[currentLanguage]["friends"]} - ${friends.length}',
                    style: getFont("mainfont")(
                      color: getColor("secondarytext"),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                            stops: const [
                              0.0,
                              0.06,
                              0.875,
                              1.0
                            ], // 10% purple, 80% transparent, 10% purple
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstOut,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final friend in friends)
                              TextButton(
                                onPressed: () {
                                  currentConversation = {
                                    "email": friend,
                                    "displayname": displayNames[friend]
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
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        50,
                                      ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        color: getColor(
                                          "button",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Text(
                                        displayNames[friend] ?? "",
                                        overflow: TextOverflow.ellipsis,
                                        style: getFont("mainfont")(
                                          color: getColor("secondarytext"),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                          ],
                        ),
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
                        pushReplacement(context, const MainView());
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
                        //pushReplacement(context, const FriendsView());
                      },
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
                  ),
                ],
              ),
            ),
          ),
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
                options: widget.options),
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
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.requests.isEmpty ? 0 : 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(50),
                    ),
                    child: Container(
                      color: getColor("notification"),
                      width: 19,
                      height: 19,
                      alignment: Alignment.center,
                      child: Text(
                        widget.requests.length.toString().length > 2
                            ? "99+"
                            : widget.requests.length.toString(),
                        textAlign: TextAlign.center,
                        style: getFont("mainfont")(
                          color: getColor("secondarytext"),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
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
  FriendRequestsView(
      {Key? key,
      required this.text,
      required this.requests,
      required this.options})
      : super(key: key);
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
      //WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
      //});
    });
    return Scaffold(
      backgroundColor: getColor("background2"),
      body: ScrollConfiguration(
        behavior: MyBehavior(),
        child: Stack(
          children: [
            Builder(builder: (context) {
              if (widget.requests.isEmpty) {
                return Center(
                  child: Opacity(
                    opacity: 0.5,
                    child: Text(
                      widget.text ==
                              translation[currentLanguage]["incomingrequests"]
                          ? translation[currentLanguage]["noincomingrequests"]
                          : translation[currentLanguage]["nooutgoingrequests"],
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
                          pushReplacement(context, const MainView());
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
                          //pushReplacement(context, const FriendsView());
                        },
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
                    ),
                  ],
                ),
              ),
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
    if (mounted) {
      setState(() {});
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    getRequestDisplayName();
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            50,
          ),
          child: Container(
            width: 32,
            height: 32,
            color: getColor(
              "button",
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
    );
  }
}

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

List outgoingRequests = [];
List incomingRequests = [];

class FriendsView extends StatefulWidget {
  const FriendsView({Key? key}) : super(key: key);

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  void getData() async {
    incomingRequests = await getFriendRequests();
    outgoingRequests = await getSentFriendRequests();
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
            padding: const EdgeInsets.only(left: 12, right: 12, top: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FriendRequestsButton(
                  text: translation[currentLanguage]["incomingrequests"],
                  requests: incomingRequests,
                ),
                FriendRequestsButton(
                  text: translation[currentLanguage]["outgoingrequests"],
                  requests: outgoingRequests,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    translation[currentLanguage]["friends"],
                    style: getFont("mainfont")(
                      color: getColor("secondarytext"),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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

class FriendRequestsButton extends StatefulWidget {
  const FriendRequestsButton({
    Key? key,
    required this.text,
    required this.requests,
  }) : super(key: key);
  final String text;
  final List requests;

  @override
  State<FriendRequestsButton> createState() => _FriendRequestsButtonState();
}

class _FriendRequestsButtonState extends State<FriendRequestsButton> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      child: TextButton(
        onPressed: () {
          push(
            context,
            FriendRequestsView(text: widget.text, requests: widget.requests),
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

class FriendRequestsView extends StatefulWidget {
  const FriendRequestsView(
      {Key? key, required this.text, required this.requests})
      : super(key: key);
  final String text;
  final List requests;

  @override
  State<FriendRequestsView> createState() => _FriendRequestsViewState();
}

class _FriendRequestsViewState extends State<FriendRequestsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getColor("background2"),
      body: ScrollConfiguration(
        behavior: MyBehavior(),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 80),
              child: ListView(
                children: [
                  for (final request in widget.requests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FriendRequest(
                        request: request,
                      ),
                    ),
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

class FriendRequest extends StatefulWidget {
  const FriendRequest({Key? key, required this.request}) : super(key: key);
  final Map request;

  @override
  State<FriendRequest> createState() => _FriendRequestState();
}

class _FriendRequestState extends State<FriendRequest> {
  Future<String> getRequestDisplayName() async {
    List users = [widget.request["sender"], widget.request["receiver"]];
    users.removeWhere(
        (element) => element == FirebaseAuth.instance.currentUser?.email);
    return await getDisplayName(users[0]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getRequestDisplayName(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
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
                        snapshot.data.toString(),
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
              ],
            );
          default:
            return Container();
        }
      },
    );
  }
}

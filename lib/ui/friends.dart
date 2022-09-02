import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';

import '../data/translation.dart';
import '../data/util.dart';
import '../main.dart';
import 'addfriends.dart';
import 'loading.dart';
import 'mainscreen.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({Key? key}) : super(key: key);

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getColor("background2"),
      body: Stack(
        children: [
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
          )
        ],
      ),
    );
  }
}

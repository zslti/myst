import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/userdata.dart';
import 'package:myst/data/util.dart';
import 'package:myst/ui/conversations.dart';
import 'package:myst/ui/messages.dart';

import '../data/translation.dart';
import '../main.dart';
import 'loading.dart';
import 'mainscreen.dart';

TextEditingController nameController = TextEditingController();
List users = [];
List addedUsers = [];

class AddFriendsView extends StatefulWidget {
  const AddFriendsView({Key? key}) : super(key: key);

  @override
  State<AddFriendsView> createState() => _AddFriendsViewState();
}

class _AddFriendsViewState extends State<AddFriendsView> {
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: getColor("background2"),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 90,
                left: 16,
                right: 16,
                bottom: 50,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5),
                    ),
                    child: Container(
                      height: 35,
                      alignment: Alignment.center,
                      child: TextField(
                        onChanged: (str) async {
                          users = await getUsersNamed(str);
                          users.removeWhere(
                            (element) =>
                                element["email"] ==
                                (FirebaseAuth.instance.currentUser?.email ??
                                    ""),
                          );
                          setState(() {});
                        },
                        keyboardType: TextInputType.visiblePassword,
                        textAlignVertical: const TextAlignVertical(
                          y: -1,
                        ),
                        controller: nameController,
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
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.search,
                              color: getColor("secondarytext"),
                              size: 20,
                            ),
                          ),
                          isDense: true,
                          fillColor: getColor("background"),
                          filled: true,
                          hintText: translation[currentLanguage]["findfriend"],
                          hintStyle: getFont("mainfont")(
                            color: getColor("secondarytext"),
                            fontSize: 14,
                            height: 1.3,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final user in users)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
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
                                Text(
                                  user["username"],
                                  style: getFont("main")(
                                    color: getColor("secondarytext"),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        user["displayname"] = user["username"];
                                        conversations.add(user);
                                        addedUsers.add(user);
                                        currentConversation = user;
                                        pushReplacement(
                                          context,
                                          const MainView(),
                                        );
                                      },
                                      child: Icon(
                                        Icons.messenger_outline,
                                        color: getColor("secondarytext"),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                      ],
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
                padding: const EdgeInsets.only(left: 12, right: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Align(
                          alignment: const Alignment(0, 0.5),
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
                        translation[currentLanguage]["addfriend"],
                        style: getFont("mainfont")(
                          color: getColor("maintext"),
                          fontSize: 20,
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
            )
          ],
        ),
      ),
    );
  }
}

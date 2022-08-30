import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:myst/data/translation.dart';
import 'package:myst/data/util.dart';
import 'package:myst/main.dart';

import '../data/theme.dart';
import '../data/userdata.dart';

bool t = false;
List conversations = [];
TextEditingController searchController = TextEditingController();

class MessagesView extends StatefulWidget {
  const MessagesView({Key? key}) : super(key: key);

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  void getData() async {
    conversations = await getConversations();
    for (int i = 0; i < conversations.length; i++) {
      conversations[i] = {
        "email": conversations[i],
        "displayname": await getDisplayName(conversations[i]),
      };
    }
    //setState(() {});
  }

  @override
  void initState() {
    super.initState();
    //getData();
  }

  @override
  Widget build(BuildContext context) {
    if (!t) {
      Timer(const Duration(milliseconds: 50), () {
        t = true;
      });
    }
    return Scaffold(
      backgroundColor: getColor("background"),
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: t ? 1 : 0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 50,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 7,
              top: 35,
            ),
            child: KeyboardVisibilityBuilder(
                builder: (context, isKeyboardVisible) {
              return ClipRRect(
                //borderRadius: BorderRadius.circular(15),
                borderRadius: BorderRadius.only(
                  topRight: const Radius.circular(15),
                  bottomRight:
                      Radius.circular(15 * (isKeyboardVisible ? 0 : 1)),
                  topLeft: const Radius.circular(15),
                  bottomLeft: Radius.circular(15 * (isKeyboardVisible ? 0 : 1)),
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: getColor("background2"),
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 12, left: 16, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translation[currentLanguage]["messages"],
                          style: getFont("mainfont")(
                            color: getColor("maintext"),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Stack(
                          children: [
                            ScrollConfiguration(
                              behavior: MyBehavior(),
                              child: Builder(builder: (context) {
                                try {
                                  return ListView(
                                    shrinkWrap: true,
                                    children: [
                                      for (final conversation in conversations)
                                        TextButton(
                                          onPressed: () {},
                                          child: Text(
                                            conversation["displayname"],
                                            style: getFont("mainfont")(
                                              color: getColor("secondarytext"),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                } catch (e) {
                                  return Text(
                                    "No conversations",
                                    style: getFont("mainfont")(
                                      color: getColor("secondarytext"),
                                    ),
                                  );
                                }
                              }),
                            ),
                            ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(5),
                              ),
                              child: Container(
                                height: 35,
                                alignment: Alignment.center,
                                child: TextField(
                                  keyboardType: TextInputType.visiblePassword,
                                  textAlignVertical:
                                      const TextAlignVertical(y: -1),
                                  controller: searchController,
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
                                    hintText: translation[currentLanguage]
                                        ["findconversation"],
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/translation.dart';
import 'package:myst/data/userdata.dart';
import 'package:myst/data/util.dart';

import '../main.dart';
import 'mainscreen.dart';

dynamic currentConversation;
List currentMessages = [];
int lastRequestTime = 0;
Map displayNames = {};
TextEditingController messageController = TextEditingController();
double currentBarHeight = 50, currentFieldHeight = 35;
double targetBarHeight = 50, targetFieldHeight = 35;
double transitionProgress = 0;

void startTransition() {
  if (transitionProgress != 0 ||
      targetBarHeight > 134 ||
      targetFieldHeight > 119) return;
  double startBarHeight = currentBarHeight;
  double startFieldHeight = currentFieldHeight;
  Timer.periodic(const Duration(milliseconds: 15), (timer) {
    currentBarHeight = lerpDouble(startBarHeight, targetBarHeight,
        Curves.easeOut.transform(transitionProgress))!;
    currentFieldHeight = lerpDouble(startFieldHeight, targetFieldHeight,
        Curves.easeOut.transform(transitionProgress))!;
    transitionProgress += 0.2;
    if (transitionProgress >= 1) {
      transitionProgress = 0;
      timer.cancel();
    }
  });
}

class Message extends StatefulWidget {
  const Message({Key? key, required this.message}) : super(key: key);
  final Map message;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
          child: ClipRRect(
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
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayNames[widget.message['sender']] ?? "",
              style: getFont("mainfont")(
                color: getColor("secondarytext"),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 60,
              child: Text(
                widget.message['message'] ?? "",
                style: getFont("mainfont")(
                  color: getColor("maintext"),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MessagesView extends StatefulWidget {
  const MessagesView({Key? key}) : super(key: key);

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  Future<void> refreshMessages() async {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastRequestTime < 100) {
      return;
    }
    lastRequestTime = now;
    currentMessages = await getMessages(currentConversation["email"]);

    try {
      int startIndex = currentMessages[0]["users"].toString().lastIndexOf('}');
      String users = currentMessages[0]["users"]
          .toString()
          .replaceAll("{", '"')
          .replaceAll("}", '"')
          .replaceFirst('"', '[')
          .replaceFirst('"', "]", startIndex);
      Map names = {};
      for (int i = 0; i < jsonDecode(users).length; i++) {
        String email = jsonDecode(users)[i];
        names[email] = await getDisplayName(email);
      }
      if (names.isNotEmpty) {
        displayNames = names;
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (currentConversation == null) {
      return Scaffold(
        backgroundColor: getColor("background2"),
        body: Center(
          child: Opacity(
            opacity: 0.5,
            child: Text(
              translation[currentLanguage]["nomessages"],
              style: getFont("mainfont")(
                color: getColor("secondarytext"),
              ),
            ),
          ),
        ),
      );
    }
    refreshMessages();
    try {
      return Scaffold(
        backgroundColor: getColor("background2"),
        body: ScrollConfiguration(
          behavior: MyBehavior(),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 25, bottom: 52),
                child: ListView(
                  reverse: true,
                  scrollDirection: Axis.vertical,
                  children: [
                    for (final message in currentMessages)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Message(message: message),
                      ),
                  ],
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 60,
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
                  padding: const EdgeInsets.only(left: 16, right: 10),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () {
                        if (actualSide != RevealSide.main) {
                          return;
                        }
                        swipeDirection = RevealSide.left;
                        gkey.currentState?.onTranslate(
                          50 * MediaQuery.of(context).size.width / 400,
                          shouldApplyTransition: true,
                        );
                      },
                      child: Icon(
                        Icons.messenger_outline,
                        color: getColor("secondarytext"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 4),
                      child: Image.asset(
                        "assets/at.png",
                        width: 15,
                        height: 15,
                        color: getColor("secondarytext"),
                      ),
                    ),
                    Text(
                      displayNames[currentConversation["email"]] ?? "",
                      style: getFont("mainfont")(
                        color: getColor("maintext"),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            if (actualSide != RevealSide.main) {
                              return;
                            }
                            swipeDirection = RevealSide.right;
                            gkey.currentState?.onTranslate(
                              -50 * MediaQuery.of(context).size.width / 400,
                              shouldApplyTransition: true,
                            );
                          },
                          child: Image.asset(
                            "assets/more.png",
                            width: 35,
                            height: 35,
                            color: getColor("secondarytext"),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: currentBarHeight,
                  decoration: BoxDecoration(
                    color: getColor("background3"),
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
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Container(
                      height: currentFieldHeight,
                      //height: 20,
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: SizedBox(
                          height: currentFieldHeight,
                          child: TextField(
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            onChanged: (str) {
                              print(currentBarHeight.toString() +
                                  currentFieldHeight.toString());
                              targetFieldHeight = max(
                                35,
                                14 +
                                    messageController.text.textHeight(
                                      getFont("mainfont")(
                                        color: getColor("secondarytext"),
                                        fontSize: 14,
                                      ),
                                      MediaQuery.of(context).size.width - 32,
                                    ),
                              );
                              targetBarHeight = max(
                                50,
                                29 +
                                    messageController.text.textHeight(
                                      getFont("mainfont")(
                                        color: getColor("secondarytext"),
                                        fontSize: 14,
                                      ),
                                      MediaQuery.of(context).size.width - 32,
                                    ),
                              );
                              startTransition();
                            },
                            textAlignVertical: const TextAlignVertical(
                              y: -1,
                            ),
                            controller: messageController,
                            cursorColor: getColor("cursor"),
                            cursorRadius: const Radius.circular(4),
                            style: getFont("mainfont")(
                              color: getColor("secondarytext"),
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              fillColor: getColor("background"),
                              filled: true,
                              hintText: translation[currentLanguage]["message"],
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } on RangeError {
      return Scaffold(
        backgroundColor: getColor("background2"),
        body: Text(
          "baj",
          style: getFont("mainfont")(
            color: getColor("secondarytext"),
          ),
        ),
      );
    }
  }
}

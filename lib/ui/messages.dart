import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/translation.dart';
import 'package:myst/data/userdata.dart';
import 'package:myst/data/util.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../main.dart';
import 'mainscreen.dart';

dynamic currentConversation;
List currentMessages = [];
int lastRequestTime = 0;
Map displayNames = {};
TextEditingController messageController = TextEditingController();
ItemScrollController _scrollController = ItemScrollController();
ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
double currentBarHeight = 50, currentFieldHeight = 35;
double targetBarHeight = 50, targetFieldHeight = 35;
double transitionProgress = 0;
int messageCount = 0;
bool done = false;
bool built = false;

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
    transitionProgress += 0.1;
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //Expanded(
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width / 2.5,
                  ),
                  child: Text(
                    displayNames[widget.message['sender']] ?? "",
                    overflow: TextOverflow.ellipsis,
                    style: getFont("mainfont")(
                      color: getColor("secondarytext"),
                    ),
                  ),
                ),
                //),
                const SizedBox(
                  width: 5,
                ),
                Opacity(
                  opacity: 0.5,
                  child: Text(
                    timestampToDate(widget.message['timestamp']),
                    style: getFont("mainfont")(
                      color: getColor("secondarytext"),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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
    if (currentConversation == null) {
      Timer(const Duration(milliseconds: 500), () {
        refreshMessages();
      });
      return;
    }
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastRequestTime < 100) {
      return;
    }
    shouldRebuild = false;
    lastRequestTime = now;

    currentMessages = await getMessages(currentConversation["email"]);
    built = true;
    done = false;

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
        if (currentMessages.length > messageCount &&
                !done &&
                currentMessages.length >
                    1 /* &&
            _itemPositionsListener.itemPositions.value
                .any((element) => element.index <= 5)*/
            ) {
          done = true;
          messageCount = currentMessages.length;
          _scrollController.jumpTo(index: 1);
          Timer(const Duration(milliseconds: 20), () {
            _scrollController.scrollTo(
              index: 0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
            shouldRebuild = true;
          });
        }
      }
      if (names.isNotEmpty) {
        displayNames = names;
      }
    } catch (e) {
      shouldRebuild = true;
    }
  }

  @override
  void initState() {
    super.initState();
    refreshMessages();
  }

  @override
  Widget build(BuildContext context) {
    shouldRebuild = false;
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
    Timer(const Duration(milliseconds: 50), () {
      refreshMessages();
    });

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!built) {
          Timer(const Duration(milliseconds: 1000), () {
            built = true;
          });
        }
      });
      return Scaffold(
        backgroundColor: getColor("background2"),
        body: ScrollConfiguration(
          behavior: MyBehavior(),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 50, bottom: currentBarHeight),
                child: AnimatedOpacity(
                  opacity: built ? 1 : 0,
                  duration: Duration(milliseconds: 300 * (built ? 1 : 0)),
                  child: ScrollablePositionedList.builder(
                      itemPositionsListener: _itemPositionsListener,
                      itemScrollController: _scrollController,
                      itemCount: currentMessages.length,
                      reverse: true,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (context, index) {
                        try {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Message(message: currentMessages[index]),
                          );
                        } catch (e) {
                          return Container();
                        }
                      }),
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
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: built &&
                                currentConversation["displayname"]
                                    .toString()
                                    .isNotEmpty
                            ? 1
                            : 0,
                        duration: Duration(
                            milliseconds: 300 *
                                (built &&
                                        currentConversation["displayname"]
                                            .toString()
                                            .isNotEmpty
                                    ? 1
                                    : 0)),
                        child: Text(
                          currentConversation["displayname"],
                          overflow: TextOverflow.ellipsis,
                          style: getFont("mainfont")(
                            color: getColor("maintext"),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Align(
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
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: SizedBox(
                                height: currentFieldHeight,
                                child: TextField(
                                  maxLines: 5,
                                  //keyboardType: TextInputType.multiline,
                                  onChanged: (str) {
                                    targetFieldHeight = max(
                                      35,
                                      14 +
                                          messageController.text.textHeight(
                                            getFont("mainfont")(
                                              color: getColor("secondarytext"),
                                              fontSize: 14,
                                            ),
                                            MediaQuery.of(context).size.width -
                                                70,
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
                                            MediaQuery.of(context).size.width -
                                                70,
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
                                    hintText: translation[currentLanguage]
                                        ["message"],
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
                          GestureDetector(
                            onTap: () {
                              if (messageController.text.isEmpty) {
                                return;
                              }
                              sendMessage(
                                messageController.text,
                                currentConversation["email"],
                              );
                              messageController.clear();
                              targetFieldHeight = 35;
                              targetBarHeight = 50;
                              startTransition();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  color: getColor("button2"),
                                  width: 35,
                                  height: 35,
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    right: 6.0,
                                    top: 2.0,
                                    bottom: 2.0,
                                  ),
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: getColor("maintext"),
                                    size: 20,
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

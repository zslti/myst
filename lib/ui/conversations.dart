import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:myst/data/translation.dart';
import 'package:myst/data/util.dart';
import 'package:myst/ui/mainscreen.dart';
import 'package:myst/main.dart';
import 'package:myst/ui/messages.dart';

import '../data/theme.dart';
import '../data/userdata.dart';

bool t = false, isSearching = false;
List conversations = [];
TextEditingController searchController = TextEditingController();
String searchText = "";
int lastSearchTime = 0, searchApplyTime = 0;
bool searchApplied = false;
int lastRequestTime = 0;
Map profilePictures = {};
Map forwardedTo = {};

void applySearchTerm(String str) {
  isSearching = true;
  int diff = DateTime.now().millisecondsSinceEpoch - lastSearchTime;
  if (diff < 200) {
    Timer(Duration(milliseconds: diff), () {
      searchText = str;
      isSearching = false;
    });
  }
  Timer(const Duration(milliseconds: 200), () {
    searchText = str;
    isSearching = false;
  });
  lastSearchTime = DateTime.now().millisecondsSinceEpoch;
}

class ConversationsView extends StatefulWidget {
  const ConversationsView({
    Key? key,
    this.isForwarding = false,
    this.forwardedMessage,
  }) : super(key: key);

  final bool isForwarding;
  final Map? forwardedMessage;
  @override
  State<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<ConversationsView> {
  Future<void> getProfilePictures() async {
    for (int i = 0; i < conversations.length; i++) {
      profilePictures[conversations[i]["email"]] = await getPicture(
        conversations[i]["email"],
      );
    }
  }

  void getData() async {
    if (DateTime.now().millisecondsSinceEpoch - lastRequestTime < 100) {
      return;
    }
    List c = await getConversations();
    for (int i = 0; i < c.length; i++) {
      c[i] = {
        "email": c[i],
        "displayname": await getDisplayName(c[i]),
        "status": await getStatus(c[i]),
        "customstatus": await getCustomStatus(c[i]),
      };
    }
    conversations = c;
    getProfilePictures();
    lastRequestTime = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    getData();
    if (!t) {
      Timer(const Duration(milliseconds: 50), () {
        t = true;
      });
    }
    if (widget.isForwarding) {
      Timer(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
    return Scaffold(
      backgroundColor: getColor("background"),
      resizeToAvoidBottomInset: false,
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: t ? 1 : 0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - (widget.isForwarding ? 0 : 50),
          child: Padding(
            padding: EdgeInsets.only(
              right: widget.isForwarding ? 0 : 7,
              top: 35,
            ),
            child: KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) {
                if (DateTime.now().millisecondsSinceEpoch - searchApplyTime > 250 && !searchApplied) {
                  applySearchTerm(searchController.text);
                  searchApplied = true;
                }
                return ClipRRect(
                  //borderRadius: BorderRadius.circular(15),
                  borderRadius: BorderRadius.only(
                    topRight: const Radius.circular(15),
                    bottomRight: Radius.circular(
                      15 * (isKeyboardVisible ? 0 : 1),
                    ),
                    topLeft: const Radius.circular(15),
                    bottomLeft: Radius.circular(
                      15 * (isKeyboardVisible ? 0 : 1),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: getColor("background2"),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Builder(builder: (context) {
                                if (!widget.isForwarding) {
                                  return const SizedBox();
                                }
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(
                                    Icons.arrow_back_ios,
                                    color: getColor("secondarytext"),
                                    size: 20,
                                  ),
                                );
                              }),
                              Text(
                                translation[currentLanguage][widget.isForwarding ? "forwardmessage" : "messages"],
                                style: getFont("mainfont")(
                                  color: getColor("maintext"),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Stack(
                            children: [
                              ScrollConfiguration(
                                behavior: MyBehavior(),
                                child: Builder(builder: (context) {
                                  try {
                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: MediaQuery.of(context).size.height - 90,
                                      ),
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: [
                                          const SizedBox(height: 10),
                                          for (final conversation in conversations)
                                            Builder(builder: (context) {
                                              return AnimatedOpacity(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                opacity: isSearching ? 0 : 1,
                                                child: SizedBox(
                                                  height: 53 * (!conversation["displayname"].toString().contains(searchText) ? 0 : 1),
                                                  child: TextButton(
                                                    onLongPress: () {
                                                      bottomSheetData = {
                                                        "email": conversation["email"],
                                                        "displayname": conversation["displayname"],
                                                        "image": profilePictures[conversation["email"]] ?? "",
                                                        "currentpage": "main",
                                                      };
                                                      bottomSheetProfileCustomStatus = bottomSheetProfileRealName = "";
                                                      bottomSheetProfileMutualFriends = [];
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
                                                    onPressed: () {
                                                      if (scrollController.isAttached) {
                                                        scrollController.animateTo(
                                                          0,
                                                          duration: const Duration(
                                                            milliseconds: 275,
                                                          ),
                                                          curve: Curves.ease,
                                                        );
                                                      }
                                                      swipeDirection = RevealSide.right;
                                                      gkey.currentState?.onTranslate(
                                                        -50 * MediaQuery.of(context).size.width / 400,
                                                        shouldApplyTransition: true,
                                                      );
                                                      currentConversation = conversation;
                                                      built = false;
                                                      messageCount = 0;
                                                    },
                                                    style: const ButtonStyle(
                                                      splashFactory: NoSplash.splashFactory,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Stack(
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius: BorderRadius.circular(50),
                                                              child: SizedBox(
                                                                width: 32,
                                                                height: 32,
                                                                child: ProfileImage(
                                                                  url: profilePictures[conversation["email"]] ?? "",
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 32,
                                                              height: 32,
                                                              alignment: Alignment.bottomRight,
                                                              child: StatusIndicator(
                                                                status: conversation["status"] ?? "offline",
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Stack(
                                                                children: [
                                                                  Text(
                                                                    conversation["displayname"],
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: getFont("mainfont")(
                                                                      color: getColor(
                                                                        "secondarytext",
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  AnimatedOpacity(
                                                                    duration: const Duration(
                                                                      milliseconds: 200,
                                                                    ),
                                                                    opacity: currentConversation?["email"] == conversation["email"] ? 1 : 0,
                                                                    child: Text(
                                                                      conversation["displayname"],
                                                                      overflow: TextOverflow.ellipsis,
                                                                      style: getFont("mainfont")(
                                                                        color: getColor(
                                                                          "maintext",
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                              Builder(builder: (context) {
                                                                String customStatus = conversation["customstatus"] ?? "";
                                                                if (customStatus.isEmpty) {
                                                                  return const SizedBox();
                                                                }
                                                                return Opacity(
                                                                  opacity: 0.75,
                                                                  child: Text(
                                                                    customStatus,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: getFont("mainfont")(
                                                                      color: getColor(
                                                                        "secondarytext",
                                                                      ),
                                                                      fontSize: 11,
                                                                    ),
                                                                  ),
                                                                );
                                                              }),
                                                            ],
                                                          ),
                                                        ),
                                                        Builder(builder: (context) {
                                                          if (!widget.isForwarding) {
                                                            return const SizedBox();
                                                          }
                                                          return GestureDetector(
                                                            onTap: (() async {
                                                              if (forwardedTo.containsKey(conversation["email"])) {
                                                                try {
                                                                  deleteMessage(forwardedTo[conversation["email"]]);
                                                                  forwardedTo.remove(conversation["email"]);
                                                                  // ignore: empty_catches
                                                                } catch (e) {}
                                                              } else {
                                                                forwardedTo[conversation["email"]] = await forwardMessage(
                                                                  widget.forwardedMessage!,
                                                                  conversation["email"],
                                                                );
                                                              }
                                                            }),
                                                            child: Padding(
                                                              padding: const EdgeInsets.only(left: 8.0),
                                                              child: Builder(builder: (context) {
                                                                return ClipRRect(
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  child: Container(
                                                                    color: getColor("background"),
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                      child: Text(
                                                                        translation[currentLanguage]
                                                                            [forwardedTo.containsKey(conversation["email"]) ? "undo" : "send"],
                                                                        style: getFont("mainfont")(color: getColor("maintext")),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              }),
                                                            ),
                                                          );
                                                        })
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    return SizedBox(
                                      height: MediaQuery.of(context).size.height - 100,
                                      child: Center(
                                        child: Opacity(
                                          opacity: 0.5,
                                          child: Text(
                                            translation[currentLanguage]["noconversations"],
                                            style: getFont("mainfont")(
                                              color: getColor("secondarytext"),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }),
                              ),
                              ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(5)),
                                child: Container(
                                  height: 35,
                                  alignment: Alignment.center,
                                  child: TextField(
                                    onChanged: (str) {
                                      searchApplied = false;
                                      searchApplyTime = DateTime.now().millisecondsSinceEpoch + 250;
                                    },
                                    keyboardType: TextInputType.visiblePassword,
                                    textAlignVertical: const TextAlignVertical(y: -1),
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
                                      hintText: translation[currentLanguage]["findconversation"],
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
              },
            ),
          ),
        ),
      ),
    );
  }
}

class StatusIndicator extends StatefulWidget {
  const StatusIndicator({super.key, required this.status, this.size = 10});
  final String status;
  final double size;

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.status == "online"
            ? const Color.fromARGB(255, 0, 180, 0)
            : widget.status == "away"
                ? const Color.fromARGB(255, 230, 157, 0)
                : widget.status == "busy"
                    ? const Color.fromARGB(255, 222, 0, 0)
                    : const Color.fromARGB(255, 109, 109, 109),
        borderRadius: BorderRadius.circular(widget.size),
        border: Border.all(
          color: widget.status == "online"
              ? const Color.fromARGB(255, 0, 143, 0)
              : widget.status == "away"
                  ? const Color.fromARGB(255, 176, 108, 0)
                  : widget.status == "busy"
                      ? const Color.fromARGB(255, 158, 0, 0)
                      : const Color.fromARGB(255, 71, 71, 71),
          width: widget.size / 5,
        ),
      ),
    );
  }
}

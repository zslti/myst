// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:emojis/emoji.dart' as emoji;
import 'package:flutter/services.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:http/http.dart' as http;

//import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/translation.dart';
import 'package:myst/data/userdata.dart';
import 'package:myst/data/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../data/fileextensions.dart';
import '../main.dart';
import 'conversations.dart';
import 'mainscreen.dart';

dynamic currentConversation;
List currentMessages = [];
int lastRequestTime = 0;
Map displayNames = {};
Map profilePictures = {};
TextEditingController messageController = TextEditingController();
ItemScrollController _scrollController = ItemScrollController();
ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
double currentBarHeight = 50, currentFieldHeight = 35;
double targetBarHeight = 50, targetFieldHeight = 35;
double transitionProgress = 0;
int messageCount = 0;
bool done = false;
bool built = false;
bool readMessageShown = false;
double connectionIndicatorProgress = 0;
double sendTransition = 0;
double imageRoundedAmount = 0;
String heroImageUrl = "";
final record = Record();
final player = AudioPlayer();
Map waveForms = {};
String currentAudioMessage = "";
bool isRecording = false;
List<emoji.Emoji> emList = emoji.Emoji.all().toList();
final parser = EmojiParser();
bool isTyping = false;
double typingIndicatorProgress = 0;
double typingIndicatorAnimation = 0;
List recentEmojis = [];
Map replyTo = {};
double replyBarProgress = 0;
String replyingTo = "";
bool editingMessage = false;

void scrollToMessage(Map message, BuildContext context, {String type = "reply"}) {
  int messageIndex = -1;
  if (type == "reply") {
    messageIndex = currentMessages.indexWhere((element) => element["timestamp"] == message["replyto"]["timestamp"]);
  } else if (type == "search") {
    messageIndex = currentMessages.indexWhere((element) => (element["timestamp"] == message["timestamp"] && element["sender"] == message["sender"]));
  }
  if (messageIndex == -1) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: getColor("background"),
        content: Text(
          translation[currentLanguage]["originalmessagedeleted"],
          style: getFont("mainfont")(
            color: getColor("maintext"),
          ),
        ),
      ),
    );
    return;
  }
  _scrollController.scrollTo(
    index: messageIndex,
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeInOut,
  );
}

void updateMessageFieldHeight(BuildContext context) {
  Timer.periodic(const Duration(milliseconds: 10), (timer) {
    if (messageController.text.isEmpty) {
      sendTransition -= 0.075;
    } else {
      sendTransition += 0.075;
    }
    double transition = sendTransition;
    sendTransition = min(1, max(0, sendTransition));
    if (transition != sendTransition) {
      timer.cancel();
    }
  });
  targetFieldHeight = max(
    35,
    14 +
        messageController.text.textHeight(
          getFont("mainfont")(
            color: getColor("secondarytext"),
            fontSize: 14,
          ),
          MediaQuery.of(context).size.width - 110,
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
          MediaQuery.of(context).size.width - 110,
        ),
  );
  startTransition();
}

void startTransition() {
  if (transitionProgress != 0 || targetBarHeight > 134 || targetFieldHeight > 119) return;
  double startBarHeight = currentBarHeight;
  double startFieldHeight = currentFieldHeight;
  Timer.periodic(const Duration(milliseconds: 15), (timer) {
    currentBarHeight = lerpDouble(startBarHeight, targetBarHeight, Curves.easeOut.transform(transitionProgress))!;
    currentFieldHeight = lerpDouble(startFieldHeight, targetFieldHeight, Curves.easeOut.transform(transitionProgress))!;
    transitionProgress += 0.1;
    if (transitionProgress >= 1) {
      transitionProgress = 0;
      timer.cancel();
    }
  });
}

class Message extends StatefulWidget {
  const Message({Key? key, required this.message, this.read, this.hasReducedWidth = false}) : super(key: key);
  final Map message;
  final bool? read;
  final bool hasReducedWidth;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> with AutomaticKeepAliveClientMixin {
  @override
  // ignore: must_call_super
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return MessageActionSelector(message: widget.message);
          },
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              bottomSheetData = {
                "email": widget.message["sender"],
                "displayname": displayNames[widget.message["sender"]],
                "image": profilePictures[widget.message["sender"]],
                "currentpage": "main",
                "needslide": false,
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
            child: Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: ProfileImage(
                    url: profilePictures[widget.message['sender']] ?? "",
                  ),
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
                  GestureDetector(
                    onTap: () {
                      bottomSheetData = {
                        "email": widget.message["sender"],
                        "displayname": displayNames[widget.message["sender"]],
                        "image": profilePictures[widget.message["sender"]],
                        "currentpage": "main",
                        "needslide": false,
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
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width / 2.5 - (widget.hasReducedWidth ? 50 : 0),
                      ),
                      child: Text(
                        displayNames[widget.message['sender']] ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: getFont("mainfont")(
                          color: getColor("secondarytext"),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width / 2.5 - (widget.hasReducedWidth ? 50 : 0),
                    ),
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        timestampToDate(widget.message['timestamp']),
                        overflow: TextOverflow.ellipsis,
                        style: getFont("mainfont")(
                          color: getColor("secondarytext"),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Builder(builder: (context) {
                if (widget.message["type"] == "image") {
                  return GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      context.pushTransparentRoute(
                          ImageView(url: '${sentMedia[widget.message["message"]]}${widget.hasReducedWidth ? "fromsearchview" : ""}'));
                      Timer(const Duration(milliseconds: 200), () {
                        imageRoundedAmount = 0;
                        heroImageUrl = '${sentMedia[widget.message["message"]]}${widget.hasReducedWidth ? "fromsearchview" : ""}';
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10 *
                            (heroImageUrl == '${sentMedia[widget.message["message"]]}${widget.hasReducedWidth ? "fromsearchview" : ""}'
                                ? imageRoundedAmount
                                : 1)),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width / 1.5 - (widget.hasReducedWidth ? 100 : 0),
                            maxHeight: MediaQuery.of(context).size.height / 2,
                          ),
                          child: Hero(
                            tag: '${sentMedia[widget.message["message"]]}${widget.hasReducedWidth ? "fromsearchview" : ""}',
                            child: ProfileImage(
                              url: sentMedia[widget.message["message"]] ?? "",
                              type: "banner",
                              username: "sentimage",
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (widget.message["type"] == "video") {
                  return GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      //context.pushTransparentRoute(FullscreenVideoPlayerView(url: sentMedia[widget.message["message"]] ?? ""));
                      context.pushTransparentRoute(const FullscreenVideoPlayerView(url: "https://i.imgur.com/3fkG0PD.mp4"));
                      Timer(const Duration(milliseconds: 200), () {
                        imageRoundedAmount = 0;
                        //heroImageUrl = sentMedia[widget.message["message"]] ?? "";
                        heroImageUrl = "https://i.imgur.com/3fkG0PD.mp4";
                        //systemchrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10 * (heroImageUrl == sentMedia[widget.message["message"]] ? imageRoundedAmount : 1)),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width / 1.5 - (widget.hasReducedWidth ? 100 : 0),
                            maxHeight: MediaQuery.of(context).size.height / 2,
                          ),
                          child: //Hero(
                              //tag: sentMedia[widget.message["message"]] ?? "",
                              //tag: "https://i.imgur.com/3fkG0PD.mp4$heroImageUrl",
                              //child:
                              Builder(builder: (context) {
                            // if ((sentMedia[widget.message["message"]] ?? "").isEmpty) {
                            //   return Container();
                            // }
                            return const VideoPlayerView(url: "https://i.imgur.com/3fkG0PD.mp4");
                          }),
                        ),
                        //),
                      ),
                    ),
                  );
                }
                if (widget.message["type"] == "audio") {
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (player.state == PlayerState.playing) {
                            player.pause();
                          } else {
                            await player.setSourceUrl(sentMedia[widget.message["message"]]);
                            player.resume();
                            currentAudioMessage = sentMedia[widget.message["message"]];
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color: getColor("background"),
                            child: Row(
                              children: [
                                Icon(
                                  currentAudioMessage == sentMedia[widget.message["message"]]
                                      ? player.state == PlayerState.playing
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded
                                      : Icons.play_arrow_rounded,
                                  color: getColor("secondarytext"),
                                  size: 35,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    translation[currentLanguage]["voicemessage"],
                                    style: getFont("mainfont")(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: getColor("secondarytext"),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Builder(builder: (context) {
                      //   if (waveForms[sentMedia[widget.message["message"]]] == null) return const SizedBox();
                      //   return AudioWaveformWidget(
                      //     waveform: waveForms[sentMedia[widget.message["message"]]].waveform,
                      //     start: Duration.zero,
                      //     duration: waveForms[sentMedia[widget.message["message"]]].waveform.duration,
                      //   );
                      // })
                    ],
                  );

                  //await playerController.preparePlayer();
                  // return GestureDetector(
                  //   onTap: () async {
                  //     //File file = File.fromUri(Uri.parse(widget.message['message']));
                  //     String path = await filePathFromUrl(sentMedia[widget.message["message"]]);
                  //     await playerController.preparePlayer(path);
                  //     playerController.startPlayer();
                  //   },
                  //   child: AudioFileWaveforms(size: const Size.square(100), playerController: playerController),
                  // );
                }
                if (widget.message["type"] == "file") {
                  String fileName = decryptText(widget.message["message"].substring(6)).split("filename=").last;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          launchUrlString(sentMedia[widget.message["message"]], mode: LaunchMode.externalApplication);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color: getColor("background"),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Icon(
                                    Icons.file_download_outlined,
                                    color: getColor("secondarytext"),
                                    size: 25,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                                  child: ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65 - (widget.hasReducedWidth ? 100 : 0)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileName,
                                          style: getFont("mainfont")(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: getColor("secondarytext"),
                                          ),
                                        ),
                                        Opacity(
                                          opacity: 0.5,
                                          child: Text(
                                            getExtensionDescription(fileName.split(".").last),
                                            style: getFont("mainfont")(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                              color: getColor("secondarytext"),
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
                        ),
                      ),
                    ],
                  );
                }
                if (widget.message["type"] == "location") {
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          double latitude = double.parse(widget.message["message"].split(",")[0]);
                          double longitude = double.parse(widget.message["message"].split(",")[1].toString().split("location=").first);
                          String url = "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
                          try {
                            launchUrlString(url, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            launchUrlString(url);
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color: getColor("background"),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: getColor("secondarytext"),
                                    size: 25,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                                  child: ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65 - (widget.hasReducedWidth ? 100 : 0)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          translation[currentLanguage]["sharedlocation"],
                                          style: getFont("mainfont")(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: getColor("secondarytext"),
                                          ),
                                        ),
                                        Opacity(
                                          opacity: 0.5,
                                          child: Text(
                                            widget.message["message"].split("location=").last,
                                            style: getFont("mainfont")(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                              color: getColor("secondarytext"),
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
                        ),
                      ),
                    ],
                  );
                }
                return SizedBox(
                  width: MediaQuery.of(context).size.width - 60 - (widget.hasReducedWidth ? 100 : 0),
                  child: Builder(builder: (context) {
                    String text = widget.message['message'] ?? "";
                    List textSegments = [];
                    RegExp linkRegex = RegExp("[1-z][.][1-z]");
                    bool isEmojiOnly = parser.count(text) == text.replaceAll(" ", "").length / 2;

                    for (String word in text.split(" ")) {
                      if (linkRegex.hasMatch(word)) {
                        try {
                          textSegments[textSegments.length - 1] += " ";
                          // ignore: empty_catches
                        } catch (e) {}
                        textSegments.add(word);
                        textSegments.add("");
                      } else {
                        try {
                          textSegments[textSegments.length - 1] += " $word";
                        } catch (e) {
                          textSegments.add(word);
                        }
                      }
                    }

                    return RichText(
                      text: TextSpan(children: [
                        for (String text in textSegments)
                          TextSpan(
                            text: text,
                            style: getFont("mainfont")(
                              color: getColor("maintext"),
                              decoration: linkRegex.hasMatch(text) ? TextDecoration.underline : TextDecoration.none,
                              fontSize: isEmojiOnly ? 28 : 14,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                if (!linkRegex.hasMatch(text)) return;
                                String url = 'https://${text.trim().replaceAll("http://", "").replaceAll("https://", "").replaceAll("www.", "")}';
                                try {
                                  await launchUrlString(url, mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  await launchUrlString(url);
                                }
                              },
                          ),
                        WidgetSpan(
                          child: Builder(builder: (context) {
                            if (!(widget.read ?? false)) return Container();
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Image.asset(
                                "assets/read.png",
                                color: getColor("secondarytext"),
                                width: 12,
                                height: 12,
                                opacity: const AlwaysStoppedAnimation(0.5),
                              ),
                            );
                          }),
                        ),
                      ]),
                    );
                  }),
                );
              }),
              Builder(builder: (context) {
                if (widget.message["forwarded"] == null || !widget.message["forwarded"]) {
                  return const SizedBox();
                }
                return Opacity(
                  opacity: 0.5,
                  child: Row(
                    children: [
                      RotatedBox(
                        quarterTurns: 2,
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 12,
                          color: getColor("secondarytext"),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        translation[currentLanguage]["forwardedmessage"],
                        style: getFont("mainfont")(
                          color: getColor("secondarytext"),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Builder(builder: (context) {
                if (widget.message["replyto"] == null) {
                  return const SizedBox();
                }
                return Opacity(
                  opacity: 0.5,
                  child: GestureDetector(
                    onTap: () {
                      scrollToMessage(widget.message, context);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply_outlined,
                          size: 14,
                          color: getColor("secondarytext"),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${translation[currentLanguage]["replyingto"]}${displayNames[widget.message["replyto"]["sender"]]}',
                          style: getFont("mainfont")(
                            color: getColor("secondarytext"),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Builder(builder: (context) {
                if (widget.message["edited"] == null || !widget.message["edited"]) {
                  return const SizedBox();
                }
                return Opacity(
                  opacity: 0.5,
                  child: GestureDetector(
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: getColor("secondarytext"),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          translation[currentLanguage]["edited"],
                          style: getFont("mainfont")(
                            color: getColor("secondarytext"),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Builder(builder: (context) {
                if (!widget.message.containsKey("reactions") || widget.message["reactions"].length == 0) return const SizedBox();
                List reactions = widget.message["reactions"];
                Map reactionMap = {};
                for (Map reaction in reactions) {
                  if (!reactionMap.containsKey(reaction["emoji"])) reactionMap[reaction["emoji"]] = [];
                  reactionMap[reaction["emoji"]].add(reaction["email"]);
                }
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return ReactionSheet(reactions: reactionMap);
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Wrap(
                      children: [
                        for (final reaction in reactionMap.keys)
                          Padding(
                            padding: const EdgeInsets.only(right: 2.5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Container(
                                color: getColor("background"),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Row(
                                    children: [
                                      Text(
                                        reaction,
                                      ),
                                      Builder(builder: (context) {
                                        if (reactionMap[reaction].length <= 1) return const SizedBox();
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Text(
                                            reactionMap[reaction].length.toString(),
                                            style: getFont("mainfont")(
                                              color: getColor("secondarytext"),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      }),
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
              })
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class MessageActionSelector extends StatefulWidget {
  const MessageActionSelector({
    Key? key,
    required this.message,
  }) : super(key: key);
  final Map message;

  @override
  State<MessageActionSelector> createState() => _MessageActionSelectorState();
}

class _MessageActionSelectorState extends State<MessageActionSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      color: getColor("background"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (Rect rect) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withAlpha(220),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withAlpha(220),
                        ],
                        stops: const [0.0, 0.1, 0.9, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstOut,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 80),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        children: [
                          const SizedBox(
                            width: 8,
                          ),
                          for (final emoji in recentEmojis.reversed)
                            GestureDetector(
                              onTap: () {
                                addReaction(widget.message, emoji);
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4, right: 4, top: 6, bottom: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    color: getColor("background2"),
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2, left: 1),
                                      child: Text(
                                        emoji.toString(),
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return EmojiSelector(
                            type: "reaction",
                            message: widget.message,
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 40,
                          height: 40,
                          color: getColor("background2"),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_emotions_outlined, color: getColor("secondarytext"), size: 22),
                              Text("+", style: TextStyle(color: getColor("secondarytext"), fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Icon(Icons.close, color: getColor("secondarytext")),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Builder(builder: (context) {
            bool isMyMessage = widget.message["sender"] == FirebaseAuth.instance.currentUser?.email;
            return SizedBox(
              height: MediaQuery.of(context).size.height / 2 - 50,
              child: ScrollConfiguration(
                behavior: MyBehavior(),
                child: ListView(
                  children: [
                    MessageActionButton(
                      showCondition: isMyMessage,
                      widgets: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.delete_outline, color: getColor("secondarytext")),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            translation[currentLanguage]["deletemessage"],
                            style: getFont("mainfont")(color: getColor("secondarytext"), fontSize: 14),
                          ),
                        ),
                      ],
                      onPressed: () {
                        deleteMessage(widget.message);
                        Navigator.pop(context);
                      },
                    ),
                    MessageActionButton(
                      showCondition: widget.message["type"] == null,
                      widgets: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.content_copy_rounded, color: getColor("secondarytext")),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Text(
                            translation[currentLanguage]["copymessage"],
                            style: getFont("mainfont")(color: getColor("secondarytext"), fontSize: 14),
                          ),
                        ),
                      ],
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: widget.message["message"]));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: getColor("background"),
                            content: Text(
                              translation[currentLanguage]["copymessagetext"],
                              style: getFont("mainfont")(
                                color: getColor("maintext"),
                              ),
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                    ),
                    MessageActionButton(
                      widgets: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, right: 6),
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: getColor("secondarytext"),
                              size: 22,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Text(
                            translation[currentLanguage]["forwardmessage"],
                            style: getFont("mainfont")(color: getColor("secondarytext"), fontSize: 14),
                          ),
                        ),
                      ],
                      onPressed: () async {
                        Navigator.pop(context);
                        forwardedTo = {};
                        push(
                          context,
                          ConversationsView(
                            isForwarding: true,
                            forwardedMessage: widget.message,
                          ),
                        );
                      },
                    ),
                    MessageActionButton(
                      //showCondition: widget.message["type"] == null,
                      widgets: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.reply_outlined, color: getColor("secondarytext")),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Text(
                            translation[currentLanguage]["reply"],
                            style: getFont("mainfont")(color: getColor("secondarytext"), fontSize: 14),
                          ),
                        ),
                      ],
                      onPressed: () async {
                        replyTo = widget.message;
                        replyingTo = displayNames[replyTo["sender"]];
                        editingMessage = false;
                        Navigator.pop(context);
                      },
                    ),
                    MessageActionButton(
                      showCondition: widget.message["type"] == "image" ||
                          widget.message["type"] == "video" ||
                          widget.message["type"] == "file" ||
                          widget.message["type"] == "audio",
                      widgets: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.file_download_outlined, color: getColor("secondarytext")),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Text(
                            translation[currentLanguage]["download"],
                            style: getFont("mainfont")(color: getColor("secondarytext"), fontSize: 14),
                          ),
                        ),
                      ],
                      onPressed: () async {
                        launchUrlString(sentMedia[widget.message["message"]], mode: LaunchMode.externalApplication);
                        Navigator.pop(context);
                      },
                    ),
                    MessageActionButton(
                      widgets: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.ios_share, color: getColor("secondarytext")),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Text(
                            translation[currentLanguage]["share"],
                            style: getFont("mainfont")(color: getColor("secondarytext"), fontSize: 14),
                          ),
                        ),
                      ],
                      onPressed: () async {
                        String shareText = "";
                        if (widget.message["type"] == "image" ||
                            widget.message["type"] == "video" ||
                            widget.message["type"] == "file" ||
                            widget.message["type"] == "audio") {
                          shareText = sentMedia[widget.message["message"]];
                        } else if (widget.message["type"] == "location") {
                          double latitude = double.parse(widget.message["message"].split(",")[0]);
                          double longitude = double.parse(widget.message["message"].split(",")[1].toString().split("location=").first);
                          shareText = "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
                        } else {
                          shareText = widget.message["message"];
                        }
                        await Share.share(shareText);
                        Navigator.pop(context);
                      },
                    ),
                    MessageActionButton(
                      showCondition: widget.message["type"] == null && isMyMessage,
                      widgets: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.edit_outlined, color: getColor("secondarytext")),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Text(
                            translation[currentLanguage]["edit"],
                            style: getFont("mainfont")(color: getColor("secondarytext"), fontSize: 14),
                          ),
                        ),
                      ],
                      onPressed: () async {
                        replyTo = widget.message;
                        replyingTo = displayNames[replyTo["sender"]];
                        editingMessage = true;
                        messageController.text = widget.message["message"];
                        updateMessageFieldHeight(context);
                        updateTypingStatus(currentConversation["email"]);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class MessageActionButton extends StatefulWidget {
  const MessageActionButton({
    Key? key,
    this.showCondition = true,
    required this.onPressed,
    required this.widgets,
  }) : super(key: key);

  final bool showCondition;
  final Function onPressed;
  final List<Widget> widgets;

  @override
  State<MessageActionButton> createState() => _MessageActionButtonState();
}

class _MessageActionButtonState extends State<MessageActionButton> {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      if (!widget.showCondition) return const SizedBox();
      return TextButton(
        onPressed: widget.onPressed as void Function(),
        child: Row(
          children: widget.widgets,
        ),
      );
    });
  }
}

class MessagesView extends StatefulWidget {
  const MessagesView({Key? key}) : super(key: key);

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  void readMessage(String user, String message, int timestamp) async {
    if (user != FirebaseAuth.instance.currentUser?.email) {
      setMessageRead(user, message, timestamp);
    }
  }

  Future<void> getProfilePictureOf(String email) async {
    profilePictures[email] = await getPicture(email);
  }

  Future<void> refreshMessages() async {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastRequestTime < 200) {
      return;
    }
    hasNetwork();
    if (currentConversation == null) {
      Timer(const Duration(milliseconds: 500), () {
        refreshMessages();
      });
      return;
    }

    shouldRebuild = false;
    lastRequestTime = now;

    List oldMessages = currentMessages;
    currentMessages = await getMessages(currentConversation["email"]);
    currentConversation["status"] = await getStatus(currentConversation["email"]);
    isTyping = await getTypingStatus(currentConversation["email"]);
    if (oldMessages == currentMessages) {
      return;
    }
    built = true;
    done = false;

    try {
      int startIndex = currentMessages[0]["users"].toString().lastIndexOf('}');
      String users =
          currentMessages[0]["users"].toString().replaceAll("{", '"').replaceAll("}", '"').replaceFirst('"', '[').replaceFirst('"', "]", startIndex);
      Map names = {};
      for (int i = 0; i < jsonDecode(users).length; i++) {
        String email = jsonDecode(users)[i];
        names[email] = await getDisplayName(email);
        //profilePictures[email] = await getProfilePicture(email);
        getProfilePictureOf(email);
        if (currentMessages.length > messageCount && !done && currentMessages.length > 1) {
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
    for (final message in currentMessages) {
      if (message["type"] == "image" || message["type"] == "video" || message["type"] == "audio" || message["type"] == "file") {
        await getSentMedia(message["message"]);
        //if (message["type"] == "audio" && !waveForms.containsKey(message["message"]) && (sentMedia[message["message"]] ?? "").toString().isNotEmpty) {
        // String filepath = await filePathFromUrl(sentMedia[message["message"]]);
        // waveForms[sentMedia[message["message"]]] = JustWaveform.extract(
        //   audioInFile: File(filepath),
        //   waveOutFile: File("$filepath.wave"),
        //   zoom: const WaveformZoom.pixelsPerSecond(100),
        // );
        //}
      }
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
    Timer(const Duration(milliseconds: 200), () {
      refreshMessages();
    });

    double typingIndicatorModifier = 0.05 * (isTyping ? 1 : -1);
    if (typingIndicatorProgress + typingIndicatorModifier > 1) {
      typingIndicatorProgress = 1;
    } else if (typingIndicatorProgress + typingIndicatorModifier < 0) {
      typingIndicatorProgress = 0;
    } else {
      typingIndicatorProgress += typingIndicatorModifier;
    }

    bool isReplyInCurrentConversation = false;
    if (replyTo.isNotEmpty) {
      if (replyTo["users"].contains(currentConversation["email"]) &&
          replyTo["users"].contains(FirebaseAuth.instance.currentUser?.email) &&
          replyTo["users"]
              .toString()
              .replaceAll(currentConversation["email"], "")
              .replaceAll(FirebaseAuth.instance.currentUser?.email ?? "", "")
              .replaceAll(",", "")
              .replaceAll(" ", "")
              .replaceAll("{", "")
              .replaceAll("}", "")
              .isEmpty) {
        isReplyInCurrentConversation = true;
      }
    }
    double replyModifier = 0.05 * (replyTo.isNotEmpty && isReplyInCurrentConversation ? 1 : -1);
    if (replyBarProgress + replyModifier > 1) {
      replyBarProgress = 1;
    } else if (replyBarProgress + replyModifier < 0) {
      replyBarProgress = 0;
    } else {
      replyBarProgress += replyModifier;
    }
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!built) {
          Timer(const Duration(milliseconds: 1000), () {
            built = true;
          });
        }
      });
      readMessageShown = false;
      return Stack(
        children: [
          Scaffold(
            backgroundColor: getColor("background2"),
            body: ScrollConfiguration(
              behavior: MyBehavior(),
              child: Stack(
                children: [
                  Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            top: 50,
                            bottom: currentBarHeight +
                                48 * Curves.easeInOut.transform(typingIndicatorProgress) +
                                20 * Curves.easeInOut.transform(replyBarProgress)),
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
                                  DateTime lastMessageTime = DateTime.fromMillisecondsSinceEpoch(
                                    currentMessages[max(index - 1, 0)]["timestamp"],
                                  );
                                  DateTime thisMessageTime = DateTime.fromMillisecondsSinceEpoch(
                                    currentMessages[index]["timestamp"],
                                  );
                                  if (index == 0 && !(currentMessages[index]["read"] ?? false)) {
                                    readMessage(
                                      currentMessages[index]["sender"],
                                      currentMessages[index]["message"],
                                      currentMessages[index]["timestamp"],
                                    );
                                  }
                                  bool read = false;
                                  if (!readMessageShown &&
                                      ((currentMessages[index]["read"] ?? false) ||
                                          currentMessages[index]["sender"] != FirebaseAuth.instance.currentUser?.email)) {
                                    readMessageShown = true;
                                    read = true;
                                  }
                                  if (lastMessageTime.day != thisMessageTime.day ||
                                      lastMessageTime.month != thisMessageTime.month ||
                                      lastMessageTime.year != thisMessageTime.year) {
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                                          child: Message(
                                            message: currentMessages[index],
                                            read: read,
                                          ),
                                        ),
                                        Opacity(
                                          opacity: 0.5,
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 1,
                                                  color: getColor("secondarytext"),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8, right: 8),
                                                child: Text(
                                                  timestampToDate(
                                                    currentMessages[max(index - 1, 0)]["timestamp"],
                                                    showOnlyDate: true,
                                                  ),
                                                  style: getFont("mainfont")(
                                                    color: getColor("secondarytext"),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 1,
                                                  color: getColor("secondarytext"),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      top: 6.0,
                                      bottom: index == 0 ? 10 : 0,
                                    ),
                                    child: Message(
                                      message: currentMessages[index],
                                      read: read,
                                    ),
                                  );
                                } catch (e) {
                                  return Container();
                                }
                              }),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: currentBarHeight, left: 12),
                          // ignore: prefer_const_constructors
                          child: TypingIndicator(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: currentBarHeight),
                          // ignore: prefer_const_constructors
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
                            height: 20 * Curves.easeInOut.transform(replyBarProgress),
                            width: double.infinity,
                            child: Opacity(
                              opacity: Curves.easeInOut.transform(replyBarProgress),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          editingMessage
                                              ? translation[currentLanguage]["editingmessage"]
                                              : "${translation[currentLanguage]["replyingto"]}$replyingTo",
                                          overflow: TextOverflow.ellipsis,
                                          style: getFont("mainfont")(
                                            color: getColor("secondarytext"),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          replyTo = {};
                                          if (editingMessage) {
                                            messageController.clear();
                                            updateMessageFieldHeight(context);
                                            updateTypingStatus(currentConversation["email"]);
                                            Timer(const Duration(milliseconds: 100), () {
                                              setState(() {
                                                editingMessage = false;
                                              });
                                            });
                                          }
                                        });
                                      },
                                      child: SizedBox(
                                        height: 20 * Curves.easeInOut.transform(replyBarProgress),
                                        width: MediaQuery.of(context).size.width * 0.2,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Icon(
                                            Icons.close,
                                            color: getColor("secondarytext"),
                                            size: 20,
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
                      ),
                    ],
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
                          offset: const Offset(0, 3),
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
                            opacity: built && currentConversation["displayname"].toString().isNotEmpty ? 1 : 0,
                            duration: Duration(milliseconds: 300 * (built && currentConversation["displayname"].toString().isNotEmpty ? 1 : 0)),
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: currentConversation["displayname"],
                                    //overflow: TextOverflow.ellipsis,
                                    style: getFont("mainfont")(
                                      color: getColor("maintext"),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  WidgetSpan(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 2.5),
                                      child: StatusIndicator(
                                        status: currentConversation["status"] ?? "offline",
                                      ),
                                    ),
                                  )
                                ],
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
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(0),
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
                                  offset: const Offset(0, -3),
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
                                    SizedBox(
                                      width: 30 * (1 - Curves.easeInOut.transform(sendTransition)),
                                      child: Opacity(
                                        opacity: 1 - Curves.easeInOut.transform(sendTransition),
                                        child: GestureDetector(
                                          onTap: () async {
                                            Position? position;
                                            String location = "Unknown";
                                            try {
                                              position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                            } catch (e) {
                                              //await Geolocator.openAppSettings();
                                              await Geolocator.openLocationSettings();
                                            }
                                            try {
                                              String response = (await http.get(Uri.parse("http://ip-api.com/json"))).body;
                                              dynamic data = json.decode(response);
                                              location = "${data['city']}, ${data['regionName']}, ${data['country']}";
                                              // ignore: empty_catches
                                            } catch (e) {}
                                            if (position != null) {
                                              sendMessage(
                                                "${position.latitude},${position.longitude}location=$location",
                                                currentConversation["email"],
                                                type: "location",
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: getColor("background"),
                                                  content: Text(
                                                    translation[currentLanguage]["enablelocation"],
                                                    style: getFont("mainfont")(
                                                      color: getColor("maintext"),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            width: 30,
                                            height: 35,
                                            padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                                            child: Icon(
                                              Icons.location_on_outlined,
                                              color: getColor("secondarytext"),
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 35 * (1 - Curves.easeInOut.transform(sendTransition)),
                                      child: Opacity(
                                        opacity: 1 - Curves.easeInOut.transform(sendTransition),
                                        child: GestureDetector(
                                          onTap: () async {
                                            FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
                                            if (result != null) {
                                              List<File> files = result.paths.map((path) => File(path ?? "")).toList();
                                              sendFiles(files, currentConversation["email"]);
                                            }
                                          },
                                          child: Container(
                                            width: 30,
                                            height: 35,
                                            padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                                            child: Icon(
                                              Icons.insert_drive_file_outlined,
                                              color: getColor("secondarytext"),
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 35 * (1 - Curves.easeInOut.transform(sendTransition)),
                                      child: Opacity(
                                        opacity: 1 - Curves.easeInOut.transform(sendTransition),
                                        child: GestureDetector(
                                          onTap: () async {
                                            XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
                                            if (image == null) {
                                              return;
                                            }
                                            await sendImages([image], currentConversation["email"]);
                                          },
                                          onLongPress: () async {
                                            XFile? video = await ImagePicker().pickVideo(source: ImageSource.camera);
                                            if (video == null) {
                                              return;
                                            }
                                            await sendVideos([video], currentConversation["email"]);
                                          },
                                          child: Container(
                                            width: 30,
                                            height: 35,
                                            padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                                            child: Icon(
                                              Icons.camera_outlined,
                                              color: getColor("secondarytext"),
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 35 * (1 - Curves.easeInOut.transform(sendTransition)),
                                      child: Opacity(
                                        opacity: 1 - Curves.easeInOut.transform(sendTransition),
                                        child: GestureDetector(
                                          onTap: () async {
                                            List<XFile> images = await ImagePicker().pickMultiImage() ?? [];
                                            if (images.isEmpty) {
                                              return;
                                            }
                                            await sendImages(images, currentConversation["email"]);
                                          },
                                          onLongPress: () async {
                                            XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                                            if (video == null) {
                                              return;
                                            }
                                            await sendVideos([video], currentConversation["email"]);
                                          },
                                          child: SizedBox(
                                            width: 30,
                                            height: 35,
                                            //padding: const EdgeInsets.only(left: 8.0, right: 6.0, top: 2.0, bottom: 2.0),
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: getColor("secondarytext"),
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 32 * (1 - Curves.easeInOut.transform(sendTransition)),
                                      child: Opacity(
                                        opacity: 1 - Curves.easeInOut.transform(sendTransition),
                                        child: GestureDetector(
                                          onTap: () async {
                                            if (await record.hasPermission()) {
                                              int now = DateTime.now().millisecondsSinceEpoch;
                                              //String email = FirebaseAuth.instance.currentUser?.email ?? "";
                                              //isRecording = await record.isRecording();

                                              String directory = (await getApplicationDocumentsDirectory()).path;
                                              if (!isRecording) {
                                                await record.start(
                                                  path: '$directory/$now.mp4',
                                                  encoder: AudioEncoder.aacLc,
                                                  bitRate: 128000,
                                                );
                                              } else {
                                                String path = await record.stop() ?? "";
                                                File file = File(path);
                                                await sendAudios([file], currentConversation["email"]);
                                              }
                                              isRecording = !isRecording;
                                            }
                                          },
                                          child: Container(
                                            width: 30,
                                            height: 35,
                                            padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                                            child: Center(
                                              child: Stack(
                                                children: [
                                                  Icon(
                                                    Icons.mic_none_sharp,
                                                    color: getColor("secondarytext"),
                                                    size: 26,
                                                  ),
                                                  AnimatedOpacity(
                                                    opacity: isRecording ? 1 : 0,
                                                    duration: const Duration(milliseconds: 200),
                                                    child: const Icon(
                                                      Icons.mic_none_sharp,
                                                      color: Color.fromARGB(255, 189, 13, 0),
                                                      size: 26,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: SizedBox(
                                          height: currentFieldHeight,
                                          child: Builder(builder: (context) {
                                            if (isRecording) {
                                              return Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  translation[currentLanguage]["recording"],
                                                  style: getFont("mainfont")(
                                                    color: getColor("secondarytext"),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              );
                                            }
                                            return TextField(
                                              maxLines: 5,
                                              onChanged: (str) {
                                                updateMessageFieldHeight(context);
                                                updateTypingStatus(currentConversation["email"]);
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
                                                suffixIconConstraints: const BoxConstraints(
                                                  maxHeight: 40,
                                                  maxWidth: 60,
                                                ),
                                                suffixIcon: AnimatedOpacity(
                                                  //opacity: messageController.text.isEmpty ? 1 : 0,
                                                  opacity: 1,
                                                  duration: const Duration(milliseconds: 200),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      //print(emList);
                                                      showModalBottomSheet(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return const EmojiSelector();
                                                        },
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(right: 8.0),
                                                      child: Icon(Icons.emoji_emotions_outlined, color: getColor("secondarytext"), size: 24),
                                                    ),
                                                  ),
                                                ),
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
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40 * Curves.easeInOut.transform(sendTransition),
                                      child: Opacity(
                                        opacity: Curves.easeInOut.transform(sendTransition),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (messageController.text.isEmpty) {
                                              return;
                                            }
                                            bool isReplyInCurrentConversation = false;
                                            if (replyTo.isNotEmpty) {
                                              if (replyTo["users"].contains(currentConversation["email"]) &&
                                                  replyTo["users"].contains(FirebaseAuth.instance.currentUser?.email) &&
                                                  replyTo["users"]
                                                      .toString()
                                                      .replaceAll(currentConversation["email"], "")
                                                      .replaceAll(FirebaseAuth.instance.currentUser?.email ?? "", "")
                                                      .replaceAll(",", "")
                                                      .replaceAll(" ", "")
                                                      .replaceAll("{", "")
                                                      .replaceAll("}", "")
                                                      .isEmpty) {
                                                isReplyInCurrentConversation = true;
                                              }
                                            }
                                            if (editingMessage && isReplyInCurrentConversation) {
                                              editMessage(replyTo, messageController.text);
                                            } else {
                                              sendMessage(
                                                messageController.text,
                                                currentConversation["email"],
                                                replyTo: isReplyInCurrentConversation ? replyTo : null,
                                              );
                                            }

                                            replyTo = {};
                                            messageController.clear();
                                            Timer.periodic(const Duration(milliseconds: 10), (timer) {
                                              if (messageController.text.isEmpty) {
                                                sendTransition -= 0.075;
                                              } else {
                                                sendTransition += 0.075;
                                              }
                                              double transition = sendTransition;
                                              sendTransition = min(1, max(0, sendTransition));
                                              if (transition != sendTransition) {
                                                timer.cancel();
                                              }
                                            });
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
                                                padding: const EdgeInsets.only(left: 8.0, right: 6.0, top: 2.0, bottom: 2.0),
                                                child: Icon(
                                                  Icons.send_rounded,
                                                  color: getColor("maintext"),
                                                  size: 20,
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
                            ),
                          ),
                        ),
                        Builder(builder: (context) {
                          if (connectionIndicatorProgress < 1) {
                            connectionIndicatorProgress += 0.025;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Timer(const Duration(milliseconds: 10), () {
                                if (mounted) {
                                  setState(() {});
                                }
                              });
                            });
                          } else {
                            connectionIndicatorProgress = 0;
                          }
                          connectionIndicatorProgress = min(connectionIndicatorProgress, 1);
                          double size = MediaQuery.of(context).size.width / 2;
                          return AnimatedOpacity(
                            opacity: !hasConnection && connectionIndicatorProgress < 0.8 && connectionIndicatorProgress != 0 ? 1 : 0,
                            duration: const Duration(milliseconds: 125),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: size - (size * Curves.easeIn.transform(connectionIndicatorProgress)),
                              ),
                              child: Container(
                                width: double.infinity,
                                height: 1,
                                color: getColor("secondarytext"),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } on RangeError {
      return Scaffold(
        backgroundColor: getColor("background2"),
        body: const SizedBox(),
      );
    }
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      if (typingIndicatorProgress == 0) {
        return const SizedBox();
      }
      typingIndicatorAnimation += 0.025;
      double typingIndicatorDisplayValue = Curves.easeInOut.transform(typingIndicatorProgress);
      return Opacity(
        opacity: typingIndicatorDisplayValue,
        child: Padding(
          padding: EdgeInsets.only(bottom: 20 * replyBarProgress),
          child: SizedBox(
            height: 48 * typingIndicatorDisplayValue,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 8.0 * typingIndicatorDisplayValue,
                top: 4.0 * typingIndicatorDisplayValue,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: ProfileImage(
                        url: profilePictures[currentConversation['email']] ?? "",
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      color: getColor("background"),
                      width: 50,
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Builder(builder: (context) {
                                double animationValue = typingIndicatorAnimation - typingIndicatorAnimation.floor() + 0.12 * (3 - i);
                                return SizedBox(
                                  height: double.infinity,
                                  child: AnimatedOpacity(
                                    opacity: animationValue > 0.5 && animationValue < 1 - 0.12 * (3 - i) ? 1 : 0.5,
                                    duration: const Duration(milliseconds: 150),
                                    child: AnimatedAlign(
                                      alignment:
                                          animationValue > 0.5 && animationValue < 1 - 0.12 * (3 - i) ? const Alignment(0, -0.6) : Alignment.center,
                                      duration: const Duration(milliseconds: 150),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Container(
                                          width: 5,
                                          height: 5,
                                          color: getColor("logo"),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class EmojiSelector extends StatefulWidget {
  const EmojiSelector({
    Key? key,
    this.type = "text",
    this.message,
  }) : super(key: key);

  final String type;
  final Map? message;
  @override
  State<EmojiSelector> createState() => _EmojiSelectorState();
}

class _EmojiSelectorState extends State<EmojiSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      color: getColor("background"),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children: [
                        Text(
                          translation[currentLanguage][widget.type == "reaction" ? "sendreaction" : "sendemoji"],
                          style: getFont("mainfont")(color: getColor("maintext"), fontSize: 24),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Icon(Icons.close, color: getColor("secondarytext")),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 2 - 100,
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
                        stops: const [0.0, 0.1, 0.9, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstOut,
                    child: SingleChildScrollView(
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            for (final emoji in emList)
                              Builder(builder: (context) {
                                if (!parser.hasEmoji(emoji.toString())) {
                                  return const SizedBox();
                                }
                                return GestureDetector(
                                  onTap: () {
                                    recentEmojis.add(emoji.toString());
                                    recentEmojis = recentEmojis.toSet().toList();
                                    prefs?.setString("recentemojis", jsonEncode(recentEmojis));
                                    if (widget.type == "reaction") {
                                      addReaction(widget.message, emoji.toString());
                                      Navigator.of(context).pop();
                                      return;
                                    }
                                    messageController.text += emoji.toString();
                                    updateMessageFieldHeight(context);
                                    updateTypingStatus(currentConversation["email"]);
                                    setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      emoji.toString(),
                                      style: const TextStyle(fontSize: 30, color: Colors.white),
                                    ),
                                  ),
                                );
                              })
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 150),
                          child: Text(
                            messageController.text,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: getFont("mainfont")(color: getColor("secondarytext"), fontSize: 18),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                try {
                                  if (parser.hasEmoji(messageController.text.characters.last.toString())) {
                                    messageController.text = messageController.text.substring(0, messageController.text.length - 1);
                                  }
                                  messageController.text = messageController.text.substring(0, messageController.text.length - 1);
                                  updateMessageFieldHeight(context);
                                  setState(() {});
                                  // ignore: empty_catches
                                } catch (e) {}
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 35,
                                  width: 35,
                                  color: getColor("button2"),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 2.0),
                                    child: Icon(
                                      Icons.backspace_outlined,
                                      color: getColor("secondarytext"),
                                      size: 20,
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
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ReactionSheet extends StatefulWidget {
  const ReactionSheet({super.key, required this.reactions});

  final Map reactions;
  @override
  State<ReactionSheet> createState() => _ReactionSheetState();
}

class _ReactionSheetState extends State<ReactionSheet> {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.transparent,
            Colors.transparent,
          ],
          stops: [0.0, 0.1, 0.9, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        color: getColor("background"),
        child: ScrollConfiguration(
          behavior: MyBehavior(),
          child: Column(
            children: [
              SizedBox(
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        translation[currentLanguage]["reactions"],
                        style: getFont("mainfont")(color: getColor("maintext"), fontSize: 24),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Icon(Icons.close, color: getColor("secondarytext")),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 2 - 50,
                child: ListView(shrinkWrap: true, children: [
                  for (final reaction in widget.reactions.entries)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            reaction.key,
                            style: getFont("mainfont")(color: getColor("maintext"), fontSize: 24),
                          ),
                          const SizedBox(
                            width: 50,
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Builder(builder: (context) {
                                List reactions = reaction.value as List;
                                String reactionString = "";
                                for (int i = 0; i < min(reactions.length, 3); i++) {
                                  String displayName = displayNames[reactions[i]] ?? "";
                                  if (displayName.length > 12) {
                                    displayName = "${displayName.substring(0, 12).trim()}...";
                                  }
                                  reactionString += " $displayName,";
                                }
                                reactionString = reactionString.substring(0, reactionString.length - 1);
                                if (reactions.length > 3) {
                                  reactionString +=
                                      "${translation[currentLanguage]["andnmore1"]}${reactions.length - 3}${translation[currentLanguage]["andnmore2"]}";
                                }
                                return Text(
                                  reactionString.trim(),
                                  textAlign: TextAlign.right,
                                  style: getFont("mainfont")(color: getColor("secondarytext"), fontSize: 12),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

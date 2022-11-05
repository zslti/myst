import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:myst/data/util.dart';
import 'package:myst/ui/messages.dart';

import '../data/theme.dart';
import '../data/translation.dart';
import '../main.dart';
import 'mainscreen.dart';

TextEditingController searchController = TextEditingController();
List selectedFileTypes = [];
List selectableFileTypes = ["location", "file", "image", "video", "audio", null];

class SearchInConversationView extends StatefulWidget {
  const SearchInConversationView({super.key});

  @override
  State<SearchInConversationView> createState() => _SearchInConversationViewState();
}

class _SearchInConversationViewState extends State<SearchInConversationView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: getColor("background"),
      body: Padding(
        padding: const EdgeInsets.only(left: 57, top: 35),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Scaffold(
            backgroundColor: getColor("background2"),
            body: Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translation[currentLanguage]["search"],
                    style: getFont("mainfont")(
                      color: getColor("maintext"),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    child: Container(
                      height: 35,
                      alignment: Alignment.center,
                      child: TextField(
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
                          hintText: translation[currentLanguage]["searchinconversation"],
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
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
                        if (MediaQuery.of(context).orientation == Orientation.landscape && isKeyboardVisible) {
                          return const SizedBox();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 70,
                              width: double.infinity,
                              alignment: Alignment.center,
                              color: getColor("background"),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                                    child: Text(
                                      translation[currentLanguage]["searchbytype"],
                                      style: getFont("mainfont")(
                                        color: getColor("secondarytext"),
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: const [
                                        FileTypeButton(icon: Icons.location_on_outlined, index: 0),
                                        FileTypeButton(icon: Icons.insert_drive_file_outlined, index: 1),
                                        FileTypeButton(icon: Icons.image_outlined, index: 2),
                                        FileTypeButton(icon: Icons.video_collection_outlined, index: 3),
                                        FileTypeButton(icon: Icons.mic_none_sharp, index: 4),
                                        FileTypeButton(icon: Icons.short_text_rounded, index: 5),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6)
                                ],
                              ),
                            ),
                            Opacity(
                              opacity: 0.5,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4.0, top: 8.0),
                                child: Text(
                                  translation[currentLanguage]["doubleclicktojump"],
                                  style: getFont("mainfont")(
                                    color: getColor("secondarytext"),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  ShaderMask(
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
                        stops: const [0.0, 0.1, 0.85, 0.95],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstOut,
                    child: KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
                      return SizedBox(
                        height: max(0, MediaQuery.of(context).size.height - (isKeyboardVisible ? 514 : 224)),
                        //width: MediaQuery.of(context).size.width - 131,
                        child: ScrollConfiguration(
                          behavior: MyBehavior(),
                          child: SingleChildScrollView(
                            child: Builder(builder: (context) {
                              int messages = 0;
                              List fileTypes = selectedFileTypes;
                              if (fileTypes.isEmpty) {
                                fileTypes = [0, 1, 2, 3, 4, 5];
                              }
                              List fileTypeNames = [];
                              for (int i = 0; i < fileTypes.length; i++) {
                                fileTypeNames.add(selectableFileTypes[fileTypes[i]]);
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                // padding: const EdgeInsets.only(top: 10),
                                // shrinkWrap: true,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  for (final message in currentMessages)
                                    Builder(builder: (context) {
                                      if (!message["message"].contains(searchController.text) && message["type"] == null) return const SizedBox();
                                      if (message["type"] != null && searchController.text.isNotEmpty) return const SizedBox();
                                      if (!fileTypeNames.contains(message["type"])) return const SizedBox();
                                      messages++;
                                      return GestureDetector(
                                        onDoubleTap: () {
                                          scrollToMessage(message, context, type: "search");
                                          swipeDirection = RevealSide.left;
                                          gkey.currentState?.onTranslate(
                                            50 * MediaQuery.of(context).size.width / 400,
                                            shouldApplyTransition: true,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Message(
                                            message: message,
                                            hasReducedWidth: true,
                                          ),
                                        ),
                                      );
                                    }),
                                  Builder(builder: (context) {
                                    if (messages != 0) {
                                      return const SizedBox();
                                    }
                                    return Opacity(
                                      opacity: 0.5,
                                      child: SizedBox(
                                        height: MediaQuery.of(context).size.height / 2,
                                        child: Align(
                                          child: Text(
                                            translation[currentLanguage]["nomessagesfound"],
                                            textAlign: TextAlign.center,
                                            style: getFont("mainfont")(
                                              color: getColor("secondarytext"),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(
                                    height: 100,
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      );
                    }),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FileTypeButton extends StatefulWidget {
  const FileTypeButton({
    Key? key,
    required this.icon,
    required this.index,
  }) : super(key: key);

  final IconData icon;
  final int index;
  @override
  State<FileTypeButton> createState() => _FileTypeButtonState();
}

class _FileTypeButtonState extends State<FileTypeButton> {
  @override
  Widget build(BuildContext context) {
    Timer(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {});
      }
    });
    return Expanded(
      child: IconButton(
        splashColor: Colors.transparent,
        splashRadius: 0.0001,
        icon: Stack(
          children: [
            Opacity(
              opacity: 0.5,
              child: Icon(
                widget.icon,
                color: getColor("secondarytext"),
              ),
            ),
            AnimatedOpacity(
              opacity: selectedFileTypes.contains(widget.index) ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.icon,
                color: getColor("maintext"),
              ),
            ),
          ],
        ),
        onPressed: () {
          if (selectedFileTypes.contains(widget.index)) {
            selectedFileTypes.remove(widget.index);
            return;
          }
          selectedFileTypes.add(widget.index);
          setState(() {});
        },
      ),
    );
  }
}

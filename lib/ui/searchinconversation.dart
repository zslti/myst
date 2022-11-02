import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:myst/data/util.dart';
import 'package:myst/ui/messages.dart';

import '../data/theme.dart';
import '../data/translation.dart';
import '../main.dart';

TextEditingController searchController = TextEditingController();

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
                        height: max(0, MediaQuery.of(context).size.height - (isKeyboardVisible ? 410 : 122)),
                        //width: MediaQuery.of(context).size.width - 131,
                        child: ScrollConfiguration(
                          behavior: MyBehavior(),
                          child: SingleChildScrollView(
                            child: Column(
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
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Message(
                                        message: message,
                                        hasReducedWidth: true,
                                      ),
                                    );
                                  }),
                                const SizedBox(
                                  height: 100,
                                ),
                              ],
                            ),
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

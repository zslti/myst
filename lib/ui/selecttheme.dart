import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/main.dart';
import 'package:myst/ui/register.dart';

import '../data/translation.dart';
import '../data/util.dart';
import 'loading.dart';

bool t = false;

class SelectThemeView extends StatefulWidget {
  const SelectThemeView({Key? key}) : super(key: key);

  @override
  State<SelectThemeView> createState() => _SelectThemeViewState();
}

class _SelectThemeViewState extends State<SelectThemeView> {
  @override
  Widget build(BuildContext context) {
    if (!t) {
      Timer(const Duration(milliseconds: 50), () {
        setState(() {
          t = true;
        });
      });
    }
    Timer(const Duration(milliseconds: 15), () {
      setState(() {});
    });
    List themes = [dark, light];
    return Scaffold(
      backgroundColor: getColor("background"),
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: t ? 1 : 0,
        child: ScrollConfiguration(
          behavior: MyBehavior(),
          child: Stack(
            children: [
              ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 16,
                  ),
                  // ignore: prefer_const_constructors
                  AnimatedLogo(
                    sizeMul: 1.1,
                    stopAfterFirstCycle: true,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Builder(builder: (context) {
                      return Text(
                        translation[currentLanguage]["choosetheme"],
                        style: getFont("mainfont")(
                          color: getColor("maintext"),
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
                  ),
                  for (int i = 0; i < themes.length; i += 2)
                    Row(
                      children: [
                        Builder(builder: (context) {
                          if (i >= themes.length) {
                            return Container();
                          }
                          return Expanded(
                            child: Stack(
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 500),
                                  opacity: themes[i] == currentTheme ? 1 : 0,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      top: 4,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        color: getColor("highlight"),
                                        width: 1000,
                                        height: 208,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    top: 8,
                                    right: 4,
                                  ),
                                  child: ThemeCard(theme: themes[i]),
                                ),
                              ],
                            ),
                          );
                        }),
                        Builder(builder: (context) {
                          if (i + 1 >= themes.length) {
                            return Container();
                          }
                          return Expanded(
                            child: Stack(
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 500),
                                  opacity:
                                      themes[i + 1] == currentTheme ? 1 : 0,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      top: 4,
                                      right: 4,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        color: getColor("highlight"),
                                        width: 1000,
                                        height: 208,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    top: 8,
                                    right: 8,
                                  ),
                                  child: ThemeCard(theme: themes[i + 1]),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Builder(builder: (context) {
                        //   if (i + 1 >= themes.length) {
                        //     return Container();
                        //   }
                        //   return Expanded(
                        //     child: Padding(
                        //       padding: const EdgeInsets.only(
                        //         left: 4,
                        //         right: 8,
                        //         top: 8,
                        //       ),
                        //       child: ThemeCard(theme: themes[i + 1]),
                        //     ),
                        //   );
                        // }),
                      ],
                    ),
                  const SizedBox(
                    height: 70,
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 12,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TextButton(
                      onPressed: () {
                        pushReplacement(context, const RegisterView());
                      },
                      style: TextButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                        backgroundColor: getColor("button"),
                      ),
                      child: SizedBox(
                        width: 1000,
                        child: Text(
                          translation[currentLanguage]["next"],
                          textAlign: TextAlign.center,
                          style: getFont("mainfont")(
                            color: getColor("background"),
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
    );
  }
}

class ThemeCard extends StatefulWidget {
  const ThemeCard({
    Key? key,
    required this.theme,
  }) : super(key: key);

  final Map theme;

  @override
  State<ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<ThemeCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (themeSwitchProgress != 0) {
          return;
        }
        nextTheme = widget.theme;
        Timer.periodic(const Duration(milliseconds: 10), (timer) {
          setState(() {
            themeSwitchProgress += 0.04;
          });
          if (themeSwitchProgress >= 1) {
            Map? s = currentTheme;
            currentTheme = nextTheme;
            nextTheme = s;
            themeSwitchProgress = 0;
            prefs?.setString("theme", jsonEncode(currentTheme));
            timer.cancel();
          }
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 200,
          color: getColor("inputbackground", theme: widget.theme),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    color: getColor("background", theme: widget.theme),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  color: getColor(
                                    "button",
                                    theme: widget.theme,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Column(
                              children: [
                                Text(
                                  "Lorem Ipsum",
                                  style: getFont("mainfont")(
                                    color: getColor(
                                      "secondarytext",
                                      theme: widget.theme,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "Lorem Ipsum",
                                  style: getFont("mainfont")(
                                    color: getColor(
                                      "maintext",
                                      theme: widget.theme,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  color: getColor(
                                    "button",
                                    theme: widget.theme,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Lorem Ipsum",
                                  style: getFont("mainfont")(
                                    color: getColor(
                                      "secondarytext",
                                      theme: widget.theme,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width / 2 -
                                      75,
                                  height: 90,
                                  child: Text(
                                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                                    overflow: TextOverflow.fade,
                                    style: getFont("mainfont")(
                                      color: getColor(
                                        "maintext",
                                        theme: widget.theme,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 10,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  width: double.infinity,
                                  color: getColor(
                                    "background3",
                                    theme: widget.theme,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      translation[currentLanguage]["message"],
                                      style: getFont("mainfont")(
                                        color: getColor(
                                          "secondarytext",
                                          theme: widget.theme,
                                        ),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  color: getColor(
                                    "button2",
                                    theme: widget.theme,
                                  ),
                                  padding: const EdgeInsets.only(
                                    left: 2.0,
                                    //right: 6.0,
                                    top: 2.0,
                                    bottom: 2.0,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.send_rounded,
                                      color: getColor("maintext",
                                          theme: widget.theme),
                                      size: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  widget.theme["name"],
                  overflow: TextOverflow.ellipsis,
                  style: getFont("mainfont")(
                    color: getColor("maintext", theme: widget.theme),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

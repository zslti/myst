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
    List themes = [dark, light, dark, dark, light, dark];
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
                        translation[currentLanguage]["choosetheme"] +
                            " meg nincs kesz",
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
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              widget.theme["name"],
              style: getFont("mainfont")(
                color: getColor("maintext", theme: widget.theme),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

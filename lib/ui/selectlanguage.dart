import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/main.dart';
import 'package:myst/ui/selecttheme.dart';

import '../data/translation.dart';
import '../data/util.dart';
import 'loading.dart';

bool t = false;
List<double> pos = [
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble() * 1.5 - 0.5,
];
List<double> nextPos = [
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble() * 1.5 - 0.5,
];
double curveProgress = 0;
int clang = 0;
bool alreadySet = false, textVisible = true;

class SelectLanguageView extends StatefulWidget {
  const SelectLanguageView({Key? key, this.shouldPop = false}) : super(key: key);
  final bool shouldPop;
  @override
  State<SelectLanguageView> createState() => _SelectLanguageViewState();
}

class _SelectLanguageViewState extends State<SelectLanguageView> {
  @override
  Widget build(BuildContext context) {
    if (!t) {
      Timer(const Duration(milliseconds: 50), () {
        setState(() {
          t = true;
        });
        Timer.periodic(const Duration(milliseconds: 20), (timer) {
          if (curveProgress >= 1) {
            curveProgress = 0;
            pos = nextPos;
            nextPos = [
              Random().nextDouble() * 1.5 - 0.5,
              Random().nextDouble() * 1.5 - 0.5,
              Random().nextDouble() * 1.5 - 0.5,
              Random().nextDouble() * 1.5 - 0.5,
              Random().nextDouble() * 1.5 - 0.5,
            ];
          } else {
            curveProgress += 0.004;
          }
        });
      });
    }
    final availableLanguages = translation.keys;

    Timer(const Duration(milliseconds: 2000), () {
      if (!alreadySet) {
        textVisible = false;
        alreadySet = true;
        Timer(const Duration(milliseconds: 500), () {
          clang++;
          textVisible = true;
          Timer(const Duration(milliseconds: 2000), () {
            alreadySet = false;
          });
        });
      }
    });
    return Scaffold(
      backgroundColor: getColor("background"),
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: t ? 1 : 0,
        child: ScrollConfiguration(
          behavior: MyBehavior(),
          child: Stack(
            children: [
              for (int i = 0; i < 5; i++)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: ClipPath(
                      clipper: CustomClipPath(
                        interpolateBetween(
                              (pos[i] * 1000).round(),
                              0,
                              0,
                              (nextPos[i] * 1000).round(),
                              0,
                              0,
                              Curves.ease.transform(min(curveProgress, 1)),
                            )[0] /
                            1000,
                      ),
                      child: Builder(
                        builder: (context) {
                          Timer(const Duration(milliseconds: 10), () {
                            setState(() {});
                          });
                          return Opacity(
                            opacity: 0.1,
                            child: Container(
                              width: 1000,
                              height: MediaQuery.of(context).size.height / (4 + i),
                              color: getColor("curves"),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height / 16),
                  const AnimatedLogo(
                    sizeMul: 1.1,
                    stopAfterFirstCycle: true,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Builder(builder: (context) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: textVisible ? 1 : 0,
                        child: Text(
                          translation[availableLanguages.elementAt(
                            clang % availableLanguages.length,
                          )]["chooselanguage"],
                          style: getFont("mainfont")(
                            color: getColor("maintext"),
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final language in availableLanguages)
                          ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            child: TextButton(
                              onPressed: () {
                                prefs?.setString("language", language);
                                currentLanguage = language;
                                if (widget.shouldPop) {
                                  Navigator.pop(context);
                                } else {
                                  pushReplacement(context, const SelectThemeView());
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: getColor("inputbackground"),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: Image.asset(
                                      'icons/flags/png/${translation[language]["countrycode"]}.png',
                                      package: 'country_icons',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    translation[language]["languagename"],
                                    style: getFont("mainfont")(
                                      color: getColor("secondarytext"),
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

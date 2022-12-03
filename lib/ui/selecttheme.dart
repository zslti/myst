// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/main.dart';
import 'package:myst/ui/mainscreen.dart';
import 'package:myst/ui/register.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../data/translation.dart';
import '../data/util.dart';
import 'loading.dart';

bool t = false;

class SelectThemeView extends StatefulWidget {
  const SelectThemeView({Key? key, this.shouldPop = false}) : super(key: key);
  final bool shouldPop;
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
                  SizedBox(height: MediaQuery.of(context).size.height / 16),
                  AnimatedLogo(
                    sizeMul: 1.1,
                    stopAfterFirstCycle: true,
                  ),
                  const SizedBox(height: 20),
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
                                  opacity: themes[i]["name"] == currentTheme?["name"] ? 1 : 0,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4, top: 4),
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
                                  padding: const EdgeInsets.only(left: 8, top: 8, right: 4),
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
                                  opacity: themes[i + 1]["name"] == currentTheme?["name"] ? 1 : 0,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4, top: 4, right: 4),
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
                                  padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                                  child: ThemeCard(theme: themes[i + 1]),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 70),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TextButton(
                            onPressed: () {
                              if (widget.shouldPop) {
                                Navigator.pop(context);
                              } else {
                                pushReplacement(context, const RegisterView());
                              }
                            },
                            style: TextButton.styleFrom(
                              splashFactory: NoSplash.splashFactory,
                              backgroundColor: getColor("button"),
                            ),
                            child: Text(
                              widget.shouldPop ? translation[currentLanguage]["apply"] : translation[currentLanguage]["next"],
                              textAlign: TextAlign.center,
                              style: getFont("mainfont")(
                                color: getColor("background"),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 40,
                          child: TextButton(
                            onPressed: () {
                              nameController.text = currentTheme?["name"];
                              oldTheme = currentTheme ?? {};
                              newTheme = currentTheme ?? {};
                              loadedFontPages = 1;
                              push(context, const CustomThemeView());
                            },
                            style: TextButton.styleFrom(
                              splashFactory: NoSplash.splashFactory,
                              backgroundColor: getColor("secondarytext"),
                            ),
                            child: Text(
                              "+",
                              textAlign: TextAlign.center,
                              style: getFont("mainfont")(
                                color: getColor("background"),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                                  color: getColor("button", theme: widget.theme),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
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
                            const SizedBox(width: 5),
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
                                  width: MediaQuery.of(context).size.width / 2 - 75,
                                  height: 85,
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
                        const SizedBox(height: 5),
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
                            const SizedBox(width: 5),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  color: getColor(
                                    "button2",
                                    theme: widget.theme,
                                  ),
                                  padding: const EdgeInsets.only(left: 2.0, top: 2.0, bottom: 2.0),
                                  child: Center(
                                    child: Icon(
                                      Icons.send_rounded,
                                      color: getColor("maintext", theme: widget.theme),
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

TextEditingController nameController = TextEditingController();
TextEditingController fontSearchController = TextEditingController();
Map oldTheme = {};
Map newTheme = {};
Map fonts = GoogleFonts.asMap();
int loadedFontPages = 1;
Iterable matchingFonts = fonts.keys.where((font) => font.toLowerCase().contains(fontSearchController.text.toLowerCase()));
List changeableColors = [
  "logo",
  "background",
  "background2",
  "background3",
  "inputbackground",
  "cursor",
  "button",
  "button2",
  "passwordstrength",
  "passwordgradientstart",
  "passwordgradientend",
  "highlight",
  "notification",
  "positive",
  "negative",
];
List changeableTextColors = ["maintext", "secondarytext", "errortext"];

void updateTheme() {
  nextTheme = newTheme;
  if (themeSwitchProgress != 0) {
    themeSwitchProgress = 0;
  }
  Timer.periodic(const Duration(milliseconds: 10), (timer) {
    themeSwitchProgress += 0.04;
    if (themeSwitchProgress >= 1) {
      Map? s = currentTheme;
      currentTheme = nextTheme;
      nextTheme = s;
      themeSwitchProgress = 0;
      timer.cancel();
    }
  });
}

class CustomThemeView extends StatefulWidget {
  const CustomThemeView({super.key});

  @override
  State<CustomThemeView> createState() => _CustomThemeViewState();
}

class _CustomThemeViewState extends State<CustomThemeView> {
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
    return WillPopScope(
      onWillPop: () async {
        showCustomDialog(
          context,
          translation[currentLanguage]["unsavedchanges"],
          translation[currentLanguage]["unsavedchangestext"],
          [
            TextButton(
              child: Text(
                translation[currentLanguage]["save"],
                style: getFont("mainfont")(
                  fontSize: 14,
                  color: getColor("secondarytext"),
                ),
              ),
              onPressed: () {
                prefs?.setString("theme", jsonEncode(newTheme));
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(
                translation[currentLanguage]["discard"],
                style: getFont("mainfont")(
                  fontSize: 14,
                  color: getColor("secondarytext"),
                ),
              ),
              onPressed: () {
                newTheme = oldTheme;
                updateTheme();
                setState(() {});
                // Navigator.pop(context);
                // Navigator.pop(context);
              },
            ),
          ],
        );
        return false;
      },
      child: Scaffold(
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
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showCustomDialog(
                              context,
                              translation[currentLanguage]["unsavedchanges"],
                              translation[currentLanguage]["unsavedchangestext"],
                              [
                                TextButton(
                                  child: Text(
                                    translation[currentLanguage]["save"],
                                    style: getFont("mainfont")(
                                      fontSize: 14,
                                      color: getColor("secondarytext"),
                                    ),
                                  ),
                                  onPressed: () {
                                    prefs?.setString("theme", jsonEncode(newTheme));
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                ),
                                TextButton(
                                  child: Text(
                                    translation[currentLanguage]["discard"],
                                    style: getFont("mainfont")(
                                      fontSize: 14,
                                      color: getColor("secondarytext"),
                                    ),
                                  ),
                                  onPressed: () {
                                    newTheme = oldTheme;
                                    updateTheme();
                                    setState(() {});
                                    // Navigator.pop(context);
                                    // Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
                            child: Align(
                              alignment: const Alignment(0, 0.5),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: getColor("secondarytext"),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height / 32),
                    AnimatedLogo(
                      sizeMul: 1.1,
                      stopAfterFirstCycle: true,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Builder(builder: (context) {
                        return Text(
                          translation[currentLanguage]["createtheme"],
                          style: getFont("mainfont")(
                            color: getColor("maintext"),
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }),
                    ),
                    ThemeSettingText(text: translation[currentLanguage]["themename"]),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                        child: TextField(
                          keyboardType: TextInputType.visiblePassword,
                          textAlignVertical: const TextAlignVertical(y: -1),
                          controller: nameController,
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
                            isDense: true,
                            fillColor: getColor("inputbackground"),
                            filled: true,
                            hintText: translation[currentLanguage]["themename"],
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
                    SizedBox(height: 5),
                    SettingButton(
                      icon: Icon(Icons.color_lens_outlined, color: getColor("secondarytext")),
                      text: translation[currentLanguage]["colors"],
                      isOpenable: true,
                      hasShaderMask: false,
                      openSpeed: 0.025,
                      openableWidgetId: 4,
                      openedWidgets: [
                        for (final color in changeableColors)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ThemeSettingText(text: translation[currentLanguage]["${color}color"]),
                              ThemeColorPicker(
                                colorToChange: color,
                                exampleWidget: ExampleColor(color: getColor(color)),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SettingButton(
                      icon: Icon(Icons.format_color_text_rounded, color: getColor("secondarytext")),
                      text: translation[currentLanguage]["textcolor"],
                      isOpenable: true,
                      hasShaderMask: false,
                      openableWidgetId: 5,
                      openedWidgets: [
                        for (final color in changeableTextColors)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ThemeSettingText(text: translation[currentLanguage]["${color}color"]),
                              ThemeColorPicker(
                                colorToChange: color,
                                exampleWidget: ExampleText(text: "${color}colortext", color: getColor(color)),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Builder(builder: (context) {
                      return SettingButton(
                        icon: Icon(Icons.text_fields_rounded, color: getColor("secondarytext")),
                        text: translation[currentLanguage]["font"],
                        openSpeed: 0.025,
                        isOpenable: true,
                        hasShaderMask: false,
                        openableWidgetId: 6,
                        openedWidgets: [
                          ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(5)),
                            child: TextField(
                              onChanged: (str) {
                                matchingFonts = fonts.keys.where((font) => font.toLowerCase().contains(str.toLowerCase()));
                              },
                              keyboardType: TextInputType.visiblePassword,
                              textAlignVertical: const TextAlignVertical(y: -1),
                              controller: fontSearchController,
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
                                fillColor: getColor("inputbackground"),
                                filled: true,
                                hintText: translation[currentLanguage]["fontname"],
                                hintStyle: getFont("mainfont")(
                                  color: getColor("secondarytext"),
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          RichText(
                            text: TextSpan(
                              text: translation[currentLanguage]["fontnametext"],
                              style: getFont("mainfont")(
                                color: getColor("secondarytext"),
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: translation[currentLanguage]["fontnametext2"],
                                  style: getFont("mainfont")(
                                    color: getColor("maintext"),
                                    fontSize: 12,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => launchUrlString("https://fonts.google.com/", mode: LaunchMode.externalApplication),
                                ),
                              ],
                            ),
                          ),
                          for (final font in matchingFonts.take(50 * loadedFontPages))
                            GestureDetector(
                              onTap: () {
                                showCustomDialog(
                                  context,
                                  translation[currentLanguage]["applyfont"],
                                  translation[currentLanguage]["applyfonttext"],
                                  [
                                    TextButton(
                                      child: Text(
                                        translation[currentLanguage]["apply"],
                                        style: getFont("mainfont")(
                                          fontSize: 14,
                                          color: getColor("secondarytext"),
                                        ),
                                      ),
                                      onPressed: () {
                                        newTheme["fonts"]["mainfont"] = font;
                                        updateTheme();
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ThemeSettingText(
                                    text: font,
                                    font: font,
                                    hasHorizontalPadding: false,
                                  ),
                                  Text(
                                    "The quick brown fox jumps over the lazy dog.",
                                    style: fonts[font](
                                      color: getColor("secondarytext"),
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Builder(builder: (context) {
                            if (matchingFonts.length > 50 * loadedFontPages) {
                              return TextButton(
                                onPressed: () {
                                  setState(() {
                                    loadedFontPages++;
                                  });
                                },
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(getColor("inputbackground")),
                                ),
                                child: Text(
                                  translation[currentLanguage]["loadmore"],
                                  style: getFont("mainfont")(
                                    color: getColor("secondarytext"),
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            } else {
                              return SizedBox();
                            }
                          }),
                        ],
                      );
                    }),
                    const SizedBox(height: 70),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExampleColor extends StatefulWidget {
  const ExampleColor({
    Key? key,
    required this.color,
  }) : super(key: key);

  final Color color;
  @override
  State<ExampleColor> createState() => _ExampleColorState();
}

class _ExampleColorState extends State<ExampleColor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: widget.color,
        border: Border.all(color: getColor("highlight"), width: 2),
      ),
    );
  }
}

class ExampleText extends StatefulWidget {
  const ExampleText({Key? key, required this.text, required this.color}) : super(key: key);

  final String text;
  final Color color;
  @override
  State<ExampleText> createState() => _ExampleTextState();
}

class _ExampleTextState extends State<ExampleText> {
  @override
  Widget build(BuildContext context) {
    return Text(
      translation[currentLanguage][widget.text],
      style: getFont("mainfont")(
        color: widget.color,
        fontSize: 14,
      ),
    );
  }
}

class ThemeColorPicker extends StatefulWidget {
  const ThemeColorPicker({Key? key, required this.colorToChange, required this.exampleWidget, this.reducedPadding = false}) : super(key: key);

  final String colorToChange;
  final Widget exampleWidget;
  final bool reducedPadding;
  @override
  State<ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends State<ThemeColorPicker> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 13, vertical: widget.reducedPadding ? 0 : 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.exampleWidget,
          TextButton(
            onPressed: () {
              showDialog(
                builder: (context) => AlertDialog(
                  backgroundColor: getColor("background"),
                  title: Text(
                    translation[currentLanguage]["pickcolor"],
                    style: getFont("mainfont")(color: getColor("maintext")),
                  ),
                  content: SingleChildScrollView(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        primaryColor: getColor("primarytext"),
                        textTheme: TextTheme(subtitle1: TextStyle(color: getColor("secondarytext"))),
                      ),
                      child: ColorPicker(
                        pickerColor: getColor(widget.colorToChange, theme: newTheme),
                        onColorChanged: (color) {
                          newTheme["colors"][widget.colorToChange] = [color.red, color.green, color.blue];
                          updateTheme();
                        },
                        enableAlpha: false,
                        labelTypes: const [],
                        hexInputBar: true,
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(getColor("button")),
                      ),
                      child: Text(
                        translation[currentLanguage]["done"],
                        style: getFont("mainfont")(color: getColor("background")),
                      ),
                    ),
                  ],
                ),
                context: context,
              );
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(getColor("inputbackground")),
            ),
            child: Text(
              translation[currentLanguage]["pickcolor"],
              style: getFont("mainfont")(color: getColor("secondarytext")),
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeSettingText extends StatefulWidget {
  const ThemeSettingText({
    Key? key,
    required this.text,
    this.font = "Poppins",
    this.hasHorizontalPadding = true,
  }) : super(key: key);

  final String text;
  final String font;
  final bool hasHorizontalPadding;
  @override
  State<ThemeSettingText> createState() => _ThemeSettingTextState();
}

class _ThemeSettingTextState extends State<ThemeSettingText> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 18, bottom: 4, left: widget.hasHorizontalPadding ? 13 : 0, right: widget.hasHorizontalPadding ? 13 : 0),
      child: Text(
        widget.text,
        style: fonts[widget.font](
          color: getColor("secondarytext"),
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

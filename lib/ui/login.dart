import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/ui/register.dart';

import '../data/translation.dart';
import '../data/util.dart';
import '../main.dart';
import 'loading.dart';

TextEditingController emailController = TextEditingController();
TextEditingController passwordController = TextEditingController();
bool t = false;
bool passwordObscured = true;
String errorText = "";
bool errorVisible = false;
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

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  void displayError(String error) {
    setState(() {
      errorText = translation[currentLanguage][error];
      errorVisible = true;
      Timer(const Duration(milliseconds: 5000), () {
        errorVisible = false;
      });
    });
  }

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
                                Curves.ease
                                    .transform(min(curveProgress, 1)))[0] /
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
                              height:
                                  MediaQuery.of(context).size.height / (4 + i),
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
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 16,
                  ),
                  const AnimatedLogo(
                    sizeMul: 1.1,
                    stopAfterFirstCycle: true,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Text(
                      translation[currentLanguage]["login"],
                      style: getFont("mainfont")(
                        color: getColor("maintext"),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: getColor("cursor"),
                        style: getFont("mainfont")(
                          color: getColor("secondarytext"),
                        ),
                        decoration: InputDecoration(
                          fillColor: getColor("inputbackground"),
                          filled: true,
                          hintText: translation[currentLanguage]["email"],
                          hintStyle: getFont("mainfont")(
                            color: getColor("secondarytext"),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: Stack(
                        children: [
                          TextField(
                            controller: passwordController,
                            obscureText: passwordObscured,
                            cursorColor: getColor("cursor"),
                            style: getFont("mainfont")(
                              color: getColor("secondarytext"),
                            ),
                            decoration: InputDecoration(
                              fillColor: getColor("inputbackground"),
                              filled: true,
                              hintText: translation[currentLanguage]
                                  ["password"],
                              hintStyle: getFont("mainfont")(
                                color: getColor("secondarytext"),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 50,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    passwordObscured = !passwordObscured;
                                  });
                                },
                                style: const ButtonStyle(
                                  splashFactory: NoSplash.splashFactory,
                                ),
                                child: Icon(
                                  Icons.visibility,
                                  color: getColor("secondarytext"),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: TextButton(
                        onPressed: () async {},
                        style: TextButton.styleFrom(
                          splashFactory: NoSplash.splashFactory,
                          backgroundColor: getColor("button"),
                        ),
                        child: Text(
                          translation[currentLanguage]["login"],
                          style: getFont("mainfont")(
                            color: getColor("background"),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: errorVisible ? 1 : 0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 14),
                          child: Text(
                            errorText,
                            style: getFont("mainfont")(
                              color: getColor("errortext"),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: errorVisible ? 0 : 1,
                              child: RichText(
                                text: TextSpan(
                                  text: translation[currentLanguage]
                                      ["noaccount"],
                                  style: getFont("mainfont")(
                                    color: getColor("secondarytext"),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: translation[currentLanguage]
                                          ["createnew"],
                                      style: getFont("mainfont")(
                                        color: getColor("maintext"),
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => pushReplacement(
                                              context,
                                              const RegisterView(),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: errorVisible ? 0 : 1,
                              child: Text(
                                translation[currentLanguage]["forgotpassword"],
                                style: getFont("mainfont")(
                                  color: getColor("maintext"),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 200,
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

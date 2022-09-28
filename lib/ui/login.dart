// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/ui/mainscreen.dart';
import 'package:myst/ui/passwordreset.dart';
import 'package:myst/ui/register.dart';

import '../data/translation.dart';
import '../data/userdata.dart';
import '../data/util.dart';
import '../main.dart';
import 'conversations.dart';
import 'loading.dart';

TextEditingController emailController = TextEditingController();
TextEditingController passwordController = TextEditingController();
bool t = false;
bool passwordObscured = true;
String errorText = "";
bool errorVisible = false;
bool rememberMe = false;
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
      //print(error);
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
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 8,
                      bottom: 6,
                    ),
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
                  Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor: getColor("secondarytext"),
                    ),
                    child: SizedBox(
                      height: 30,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, right: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 35,
                              child: Checkbox(
                                activeColor: getColor("secondarytext"),
                                checkColor: getColor("background"),
                                value: rememberMe,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3)),
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  rememberMe = !rememberMe;
                                });
                              },
                              child: Text(
                                translation[currentLanguage]["rememberme"],
                                style: getFont("mainfont")(
                                  color: getColor("secondarytext"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: TextButton(
                        onPressed: () async {
                          if (emailController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            displayError("emptyerror");
                            return;
                          }
                          if (!RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                          ).hasMatch(emailController.text)) {
                            displayError("emailerror");
                            return;
                          }
                          try {
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: emailController.text,
                              password: passwordController.text,
                            );
                            if (rememberMe) {
                              prefs?.setString(
                                "user",
                                jsonEncode([
                                  emailController.text,
                                  passwordController.text
                                ]),
                              );
                            } else {
                              prefs?.setString("user", "");
                            }
                            final user = FirebaseAuth.instance.currentUser;
                            if (user?.emailVerified ?? false) {
                              try {
                                conversations = await getConversations();
                                for (int i = 0; i < conversations.length; i++) {
                                  conversations[i] = {
                                    "email": conversations[i],
                                    "displayname": await getDisplayName(
                                      conversations[i],
                                    ),
                                  };
                                }
                                // ignore: empty_catches
                              } catch (e) {
                                return;
                              }
                              updateSignedinDevices();
                              push(context, const MainView());
                            } else {
                              await user?.sendEmailVerification();
                              displayError("verifyemailtext");
                            }
                          } on FirebaseAuthException catch (e) {
                            displayError(e.code);
                            return;
                          }
                        },
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
                              child: GestureDetector(
                                onTap: () {
                                  push(context, const PasswordResetView());
                                },
                                child: Text(
                                  translation[currentLanguage]
                                      ["forgotpassword"],
                                  style: getFont("mainfont")(
                                    color: getColor("maintext"),
                                  ),
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

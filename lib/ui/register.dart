import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_password_strength/flutter_password_strength.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/translation.dart';
import 'package:myst/main.dart';
import 'package:myst/ui/login.dart';
import 'package:rainbow_color/rainbow_color.dart';

import '../data/util.dart';
import 'loading.dart';

TextEditingController nameController = TextEditingController();
TextEditingController emailController = TextEditingController();
TextEditingController passwordController = TextEditingController();
TextEditingController password2Controller = TextEditingController();
bool t = false;
bool passwordObscured = true, password2Obscured = true;
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

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
                    child: Text(
                      translation[currentLanguage]["register"],
                      style: getFont("mainfont")(
                        color: getColor("maintext"),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 4, left: 13, right: 13),
                    child: Text(
                      translation[currentLanguage]["usernametext"],
                      style: getFont("mainfont")(
                        color: getColor("secondarytext"),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: TextField(
                        controller: nameController,
                        cursorColor: getColor("cursor"),
                        style: getFont("mainfont")(
                          color: getColor("secondarytext"),
                        ),
                        decoration: InputDecoration(
                          fillColor: getColor("inputbackground"),
                          filled: true,
                          hintText: translation[currentLanguage]["username"],
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
                              hintText: translation[currentLanguage]["password"],
                              hintStyle: getFont("mainfont")(
                                color: getColor("secondarytext"),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                          Column(
                            children: [
                              const SizedBox(height: 45),
                              FlutterPasswordStrength(
                                password: passwordController.text,
                                backgroundColor: getColor("passwordstrength"),
                                strengthColors: RainbowColorTween(
                                  [getColor("passwordgradientstart"), getColor("passwordgradientend")],
                                ),
                              ),
                            ],
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
                      child: Stack(
                        children: [
                          TextField(
                            controller: password2Controller,
                            obscureText: password2Obscured,
                            cursorColor: getColor("cursor"),
                            style: getFont("mainfont")(
                              color: getColor("secondarytext"),
                            ),
                            decoration: InputDecoration(
                              fillColor: getColor("inputbackground"),
                              filled: true,
                              hintText: translation[currentLanguage]["confirmpassword"],
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
                                    password2Obscured = !password2Obscured;
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
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty ||
                              password2Controller.text.isEmpty) {
                            displayError("emptyerror");
                            return;
                          }
                          if (passwordController.text.length < 8) {
                            displayError("shortpassworderror");
                            return;
                          }
                          if (passwordController.text != password2Controller.text) {
                            displayError("passwordmismatcherror");
                            return;
                          }
                          if (!emailRegex.hasMatch(emailController.text)) {
                            displayError("emailerror");
                            return;
                          }
                          try {
                            await FirebaseAuth.instance.createUserWithEmailAndPassword(
                              email: emailController.text,
                              password: passwordController.text,
                            );
                            CollectionReference users = FirebaseFirestore.instance.collection('users');
                            users.add({
                              'username': nameController.text,
                              'email': emailController.text,
                            });

                            // ignore: use_build_context_synchronously
                            pushReplacement(context, const LoginView());
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
                          translation[currentLanguage]["createaccount"],
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
                                  text: translation[currentLanguage]["alreadyregistered"],
                                  style: getFont("mainfont")(
                                    color: getColor("secondarytext"),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: translation[currentLanguage]["signin"],
                                      style: getFont("mainfont")(
                                        color: getColor("maintext"),
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => pushReplacement(
                                              context,
                                              const LoginView(),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 200)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

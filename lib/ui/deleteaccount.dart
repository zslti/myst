import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/userdata.dart';
import 'package:myst/data/util.dart';

import '../data/translation.dart';
import '../main.dart';
import 'loading.dart';
import 'login.dart';

bool t = false;
bool clicked = false;
bool passwordObscured = true;
TextEditingController emailController = TextEditingController();
TextEditingController passwordController = TextEditingController();
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
String errorText = "";
bool errorVisible = false;

class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({Key? key, this.textType = ""}) : super(key: key);
  final String textType;
  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
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
      //FirebaseAuth.instance.sendDeleteAccountEmail(),
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
                      translation[currentLanguage]["deleteaccount"],
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
                              hintText: translation[currentLanguage]["password"],
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
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 4),
                    child: TextButton(
                      onPressed: () async {
                        if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                          displayError("emptyerror");
                          return;
                        }
                        if (!RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                        ).hasMatch(emailController.text)) {
                          displayError("emailerror");
                          return;
                        }
                        setState(() {
                          clicked = true;
                        });
                        try {
                          String email = FirebaseAuth.instance.currentUser?.email ?? "";
                          UserCredential? result = await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(
                            EmailAuthProvider.credential(
                              email: emailController.text,
                              password: passwordController.text,
                            ),
                          );
                          if (email == result?.user?.email) {
                            // ignore: use_build_context_synchronously
                            showCustomDialog(
                              context,
                              translation[currentLanguage]["deleteaccount"],
                              translation[currentLanguage]["deleteaccounttext"],
                              [
                                TextButton(
                                  child: Text(
                                    translation[currentLanguage]["deleteaccount"],
                                    style: getFont("mainfont")(
                                      fontSize: 14,
                                      color: getColor("secondarytext"),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await deleteAccount(result?.user);
                                    FirebaseAuth.instance.signOut();
                                    prefs?.setString("user", "");
                                    // ignore: use_build_context_synchronously
                                    Navigator.pop(context);
                                    // ignore: use_build_context_synchronously
                                    pushReplacement(
                                      context,
                                      const LoginView(),
                                    );
                                  },
                                ),
                              ],
                            );
                          }
                          // ignore: empty_catches
                        } on FirebaseAuthException catch (e) {
                          displayError(e.code);
                        }
                      },
                      style: TextButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                        backgroundColor: getColor("button"),
                      ),
                      child: Text(
                        translation[currentLanguage]["next"],
                        style: getFont("mainfont")(
                          color: getColor("background"),
                        ),
                      ),
                    ),
                  ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

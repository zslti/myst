import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/translation.dart';
import 'package:myst/main.dart';

import '../data/util.dart';
import 'loading.dart';

TextEditingController nameController = TextEditingController();
TextEditingController emailController = TextEditingController();
TextEditingController passwordController = TextEditingController();
TextEditingController password2Controller = TextEditingController();
bool t = false;
List<double> pos = [
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble(),
  Random().nextDouble(),
  Random().nextDouble(),
  Random().nextDouble(),
];
List<double> nextPos = [
  Random().nextDouble() * 1.5 - 0.5,
  Random().nextDouble(),
  Random().nextDouble(),
  Random().nextDouble(),
  Random().nextDouble(),
];
double curveProgress = 0;

class CustomClipPath extends CustomClipper<Path> {
  double p;

  @override
  Path getClip(Size size) {
    double w = size.width;
    double h = size.height;

    final path = Path();
    path.lineTo(0, h - 150);
    path.quadraticBezierTo(w * p, h, w, h - 150);
    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }

  CustomClipPath(this.p);
}

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  @override
  Widget build(BuildContext context) {
    if (!t) {
      Timer(const Duration(milliseconds: 50), () {
        setState(() {
          t = true;
        });
        Timer.periodic(const Duration(milliseconds: 20), (timer) {
          //setState(() {
          if (curveProgress >= 1) {
            curveProgress = 0;
            pos = nextPos;
            nextPos = [
              Random().nextDouble() * 1.5 - 0.5,
              Random().nextDouble(),
              Random().nextDouble(),
              Random().nextDouble(),
              Random().nextDouble(),
            ];
          } else {
            // print(interpolateBetween((pos[0] * 1000).round(), 0, 0,
            //         (nextPos[0] * 1000).round(), 0, 0, curveProgress)[0] /
            //     1000);
            curveProgress += 0.01;
          }
          //});
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
              ClipPath(
                clipper: CustomClipPath(
                  interpolateBetween(
                          (pos[0] * 1000).round(),
                          0,
                          0,
                          (nextPos[0] * 1000).round(),
                          0,
                          0,
                          Curves.ease.transform(min(curveProgress, 1)))[0] /
                      1000,
                ),
                child: Builder(
                  builder: (context) {
                    Timer(const Duration(milliseconds: 10), () {
                      setState(() {});
                    });
                    return Container(
                      width: 1000,
                      height: 250,
                      color: Colors.red,
                    );
                  },
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
                      translation[currentLanguage]["register"],
                      style: getFont("mainfont")(
                        color: getColor("maintext"),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 18,
                      bottom: 4,
                      left: 13,
                      right: 13,
                    ),
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
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
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
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: TextField(
                        controller: password2Controller,
                        obscureText: true,
                        cursorColor: getColor("cursor"),
                        style: getFont("mainfont")(
                          color: getColor("secondarytext"),
                        ),
                        decoration: InputDecoration(
                          fillColor: getColor("inputbackground"),
                          filled: true,
                          hintText: translation[currentLanguage]
                              ["confirmpassword"],
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
                      child: TextButton(
                        onPressed: () {},
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
                  const SizedBox(
                    height: 200,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

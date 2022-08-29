import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myst/ui/mainscreen.dart';
import 'package:myst/ui/register.dart';
import 'package:myst/ui/selectlanguage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'ui/loading.dart';

SharedPreferences? prefs;
String currentLanguage = "en";
bool hasLanguageSelected = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<bool> initializeApp() async {
    //TODO: choose theme before registration

    //TODO: uncomment line when themes are done: currentTheme = jsonDecode(prefs?.getString("theme") ?? "");
    //prefs = await SharedPreferences.getInstance();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final languageData = prefs?.getString("language");

    if (languageData == null) {
      hasLanguageSelected = false;
    }

    currentLanguage = languageData ?? "en";
    final userData = prefs?.getString("user") ?? "";

    await Future.delayed(const Duration(milliseconds: 4500));

    if (userData.isNotEmpty) {
      final data = jsonDecode(userData);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: data[0],
          password: data[1],
        );
      } on FirebaseAuthException {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myst',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: const MaterialColor(
          0xffffffff,
          <int, Color>{
            50: Color(0xffffffff), //10%
            100: Color(0xffffffff), //20%
            200: Color(0xffffffff), //30%
            300: Color(0xffffffff), //40%
            400: Color(0xffffffff), //50%
            500: Color(0xffffffff), //60%
            600: Color(0xffffffff), //70%
            700: Color(0xffffffff), //80%
            800: Color(0xffffffff), //90%
            900: Color(0xffffffff), //100%
          },
        ),
      ),
      home: FutureBuilder(
        future: initializeApp(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final snapshotValue = snapshot.data.toString();
              if (snapshotValue == 'true') {
                return const MainView();
              } else if (!hasLanguageSelected) {
                return const SelectLanguageView();
              } else {
                return const RegisterView();
              }
            default:
              return const LoadingView();
          }
        },
      ),
    );
  }
}

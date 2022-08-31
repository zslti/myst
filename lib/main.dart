import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myst/ui/register.dart';
import 'package:myst/ui/selectlanguage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/theme.dart';
import 'data/userdata.dart';
import 'firebase_options.dart';
import 'ui/loading.dart';
import 'ui/mainscreen.dart';
import 'ui/conversations.dart';

SharedPreferences? prefs;
String currentLanguage = "en";
bool hasLanguageSelected = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<bool> initializeApp() async {
    prefs?.setString("theme", ""); //TODO: remove line when everything is done
    //TODO: when sending more messages in a row dont need to show name and picture again
    final themeData = prefs?.getString("theme") ?? "";

    currentTheme = dark;
    if (themeData.isNotEmpty && jsonDecode(themeData) != null) {
      currentTheme = jsonDecode(themeData);
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final languageData = prefs?.getString("language");

    if (languageData == null || languageData == "") {
      hasLanguageSelected = false;
    }

    currentLanguage = languageData ?? "en";
    final userData = prefs?.getString("user") ?? "";

    await Future.delayed(const Duration(milliseconds: 3000));

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

    try {
      conversations = await getConversations();
      for (int i = 0; i < conversations.length; i++) {
        conversations[i] = {
          "email": conversations[i],
          "displayname": await getDisplayName(conversations[i]),
        };
      }
      // ignore: empty_catches
    } catch (e) {}

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

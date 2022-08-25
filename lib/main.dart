import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui/loading.dart';

SharedPreferences? prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<bool> initializeApp() async {
    //TODO: uncomment line when themes are done: currentTheme = jsonDecode(prefs?.getString("theme") ?? "");
    //prefs = await SharedPreferences.getInstance();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myst',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: initializeApp(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return const LoadingView();
            default:
              return const LoadingView();
          }
        },
      ),
    );
  }
}

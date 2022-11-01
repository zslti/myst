import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myst/ui/messages.dart';
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
int lastGestureTime = DateTime.now().millisecondsSinceEpoch;
bool downloaderInitialized = false;
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  importance: Importance.high, playSound: true,
);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));
  //SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

  // flutterLocalNotificationsPlugin.initialize(
  //   const InitializationSettings(
  //     android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  //   ),
  // );
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // await flutterLocalNotificationsPlugin
  //     .resolvePlatformSpecificImplementation<
  //         AndroidFlutterLocalNotificationsPlugin>()
  //     ?.createNotificationChannel(channel);

  // await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );

  // String email = (FirebaseAuth.instance.currentUser?.email ?? "messages")
  //     .replaceAll("@", "at");
  // FirebaseMessaging.instance.subscribeToTopic(email).then((value) {
  //   //print("Subscribed to messages");
  // });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   RemoteNotification? notification = message.notification;
    //   AndroidNotification? android = message.notification?.android;
    //   if (notification != null && android != null) {
    //     flutterLocalNotificationsPlugin.show(
    //       notification.hashCode,
    //       notification.title,
    //       notification.body,
    //       NotificationDetails(
    //         android: AndroidNotificationDetails(
    //           channel.id,
    //           channel.name,
    //           //icon: 'app_icon',
    //           playSound: true,
    //           importance: Importance.high,
    //           priority: Priority.high,
    //           color: Colors.blue,
    //         ),
    //       ),
    //     );
    //   }
    // });

    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   //print('A new onMessageOpenedApp event was published!');
    //   RemoteNotification? notification = message.notification;
    //   AndroidNotification? android = message.notification?.android;
    //   if (notification != null && android != null) {
    //     //print("show dialog here");
    //   }
    // });
  }

  Future<void> loadImages() async {
    List messages = await getAllMessages();
    messages.removeWhere((element) {
      return !element["users"].contains(FirebaseAuth.instance.currentUser?.email);
    });
    messages.removeWhere((element) {
      return element["type"] != "image";
    });
    for (var message in messages.getRange(0, min(50, messages.length))) {
      if (message["type"] == "image") {
        getSentMedia(message["message"]);
      }
    }
  }

  Future<bool> initializeApp() async {
    prefs?.setString("theme", ""); //TODO: remove line when everything is done
    //TODO: message actions like download, share
    //TODO: app icon
    //TODO: search in conversation(in right card)
    //TODO: delete conversation
    //TODO: when deleting account delete all conversations
    //TODO: calls
    //TODO: compress videos, images, audio
    //TODO: custom themes
    //TODO: youtube embed
    //TODO: watch together
    //TODO: vanish mode
    //TODO: group chats
    //TODO: polls
    //TODO: mention people
    //TODO: games
    //TODO: optimize downloading videos
    //TODO: change push animation
    final themeData = prefs?.getString("theme") ?? "";
    emList.removeAt(40);
    emList.removeAt(102);
    recentEmojis = jsonDecode(prefs?.getString("recentemojis") ?? "[]");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // if (!downloaderInitialized) {
    //   await FlutterDownloader.initialize(
    //     ignoreSsl: true,
    //   );
    //   downloaderInitialized = true;
    // }

    currentTheme = dark;
    if (themeData.isNotEmpty && jsonDecode(themeData) != null) {
      currentTheme = jsonDecode(themeData);
    }
    FirebaseAuth.instance.signOut();

    final languageData = prefs?.getString("language");

    if (languageData == null || languageData == "") {
      hasLanguageSelected = false;
    }

    currentLanguage = languageData ?? "en";

    Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (DateTime.now().millisecondsSinceEpoch - lastGestureTime < 10000) {
        updateStatus();
      }
      //precacheImages(context);
    });

    if (!hasLanguageSelected) {
      return false;
    }

    final userData = prefs?.getString("user") ?? "";

    //await Future.delayed(const Duration(milliseconds: 3000));

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
    } catch (e) {
      return false;
    }
    for (final conversation in conversations) {
      getPicture(conversation["email"]);
      getPicture(conversation["email"], folder: "banners");
    }
    loadImages();
    await Future.delayed(const Duration(milliseconds: 3000));
    bool forceLogout = await updateSignedinDevices();
    if (forceLogout) {
      await deleteCurrentDevice();
      FirebaseAuth.instance.signOut();
      return false;
    }

    return FirebaseAuth.instance.currentUser?.email?.isNotEmpty ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        lastGestureTime = DateTime.now().millisecondsSinceEpoch;
      },
      onPanDown: (details) {
        lastGestureTime = DateTime.now().millisecondsSinceEpoch;
      },
      onPanUpdate: (details) {
        lastGestureTime = DateTime.now().millisecondsSinceEpoch;
      },
      child: MaterialApp(
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
      ),
    );
  }
}

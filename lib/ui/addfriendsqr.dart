import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myst/data/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/translation.dart';
import '../data/userdata.dart';
import '../data/util.dart';
import '../main.dart';
import 'conversations.dart';
import 'loading.dart';
import 'mainscreen.dart';

int unreadMessages = 0;
DraggableScrollableController scrollController =
    DraggableScrollableController();
double scrollSize = 0;
bool isScrolling = false;

class AddFriendsQR extends StatefulWidget {
  const AddFriendsQR({super.key});

  @override
  State<AddFriendsQR> createState() => _AddFriendsQRState();
}

class _AddFriendsQRState extends State<AddFriendsQR> {
  Future<void> getData() async {
    unreadMessages = await getUnreadMessages();
    myStatus = await getStatus(FirebaseAuth.instance.currentUser?.email ?? "");
    if (bottomSheetData["email"] != null && scrollSize != 0) {
      bottomSheetProfileStatus = await getStatus(bottomSheetData["email"]!);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(milliseconds: 500), () {
      getData();
      if (mounted) {
        setState(() {});
      }
    });
    if (scrollController.isAttached) {
      scrollSize = scrollController.size;
      if (scrollController.size < 0.3 &&
          scrollController.size > 0.01 &&
          !isScrolling) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    }
    return Scaffold(
      backgroundColor: getColor("background2"),
      body: Stack(children: [
        ScrollConfiguration(
          behavior: MyBehavior(),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 90,
                    left: 16,
                    right: 16,
                  ),
                  child: GestureDetector(
                    onTap: (() {
                      scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: getColor("background"),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translation[currentLanguage]["addfriendqr"],
                              style: getFont("mainfont")(
                                color: getColor("maintext"),
                                fontSize: 18,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                translation[currentLanguage]["addfriendqrtext"],
                                style: getFont("mainfont")(
                                  color: getColor("secondarytext"),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: QrImage(
                                  data: encryptText(
                                    FirebaseAuth.instance.currentUser?.email ??
                                        "",
                                  ),
                                  version: QrVersions.auto,
                                  size: 275.0,
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            GestureDetector(
                              onTap: () {
                                push(context, const ScanQRView());
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.qr_code_rounded,
                                    color: getColor("secondarytext"),
                                    size: 26,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    translation[currentLanguage]["scanqr"],
                                    style: getFont("mainfont")(
                                      color: getColor("secondarytext"),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 100,
                ),
              ],
            ),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          height: 73,
          decoration: BoxDecoration(
            color: getColor("background3"),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(
                  0,
                  3,
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
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
                Align(
                  alignment: const Alignment(0, 0.6),
                  child: Text(
                    translation[currentLanguage]["addfriend"],
                    style: getFont("mainfont")(
                      color: getColor("maintext"),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: getColor("background"),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(
                    0,
                    -3,
                  ),
                ),
              ],
            ),
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    style: const ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    onPressed: () {
                      if (selectedIndex == 0) return;
                      selectedIndex = 0;
                      push(context, const MainView());
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: selectedIndex == 0 ? 1 : 0.5,
                      // ignore: prefer_const_constructors
                      child: Builder(builder: (context) {
                        Timer(const Duration(milliseconds: 10), () {
                          setState(() {});
                        });
                        return const AnimatedLogo(
                          sizeMul: 0.3,
                          stopAfterFirstCycle: true,
                        );
                      }),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: const ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    onPressed: () {
                      if (selectedIndex == 1) return;
                      selectedIndex = 1;
                      //pushReplacement(context, const FriendsView());
                    },
                    child: Stack(
                      children: [
                        Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: selectedIndex == 1 ? 1 : 0.5,
                            child: Image.asset(
                              "assets/friends.png",
                              color: getColor("logo"),
                              height: 37,
                              width: 37,
                            ),
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0.2, 1),
                          child: NotificationBubble(
                            amount: friendRequestAmount,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: const ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    onPressed: () {
                      //if (selectedIndex == 2) return;
                      //selectedIndex = 2;
                      //push(context, const MainView());
                      bottomSheetData = {};
                      scrollController.animateTo(
                        0.5,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.ease,
                      );
                      isScrolling = true;
                      Timer(const Duration(milliseconds: 400), () {
                        isScrolling = false;
                      });
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: selectedIndex == 2 ? 1 : 0.5,
                      // ignore: prefer_const_constructors
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: ProfileImage(
                                url: myProfilePicture,
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: StatusIndicator(status: myStatus),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DraggableScrollableSheet(
          minChildSize: 0,
          initialChildSize: scrollSize,
          controller: scrollController,
          builder: (context, scrollController) {
            return SettingsView(
              scrollController: scrollController,
            );
          },
        ),
      ]),
    );
  }
}

class ScanQRView extends StatefulWidget {
  const ScanQRView({super.key});

  @override
  State<ScanQRView> createState() => _ScanQRViewState();
}

class _ScanQRViewState extends State<ScanQRView> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: getColor("background"),
        iconTheme: IconThemeData(
          color: getColor("secondarytext"), //change your color here
        ),
        title: Text(
          translation[currentLanguage]["scanqr"],
          style: getFont("mainfont")(
            color: getColor("maintext"),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return Icon(
                      Icons.flash_off,
                      color: getColor("secondarytext"),
                      size: 24,
                    );
                  case TorchState.on:
                    return Icon(
                      Icons.flash_on,
                      color: getColor("secondarytext"),
                      size: 24,
                    );
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state as CameraFacing) {
                  case CameraFacing.front:
                    return Icon(
                      Icons.camera_front,
                      color: getColor("secondarytext"),
                      size: 24,
                    );
                  case CameraFacing.back:
                    return Icon(
                      Icons.camera_rear,
                      color: getColor("secondarytext"),
                      size: 24,
                    );
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        allowDuplicates: false,
        controller: cameraController,
        onDetect: (barcode, args) {
          if (barcode.rawValue == null) {
            debugPrint('Failed to scan Barcode');
          } else {
            final String code = decryptText(barcode.rawValue!);
            sendFriendRequest(code);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: getColor("background"),
                content: Text(
                  translation[currentLanguage]["requestsent"],
                  style: getFont("mainfont")(
                    color: getColor("maintext"),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

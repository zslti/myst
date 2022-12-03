import 'dart:async';
import 'dart:math';

import 'package:agora_uikit/controllers/rtc_buttons.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/translation.dart';

import '../data/userdata.dart';
import '../main.dart';
import 'messages.dart';

class VideoCallView extends StatefulWidget {
  const VideoCallView({super.key, this.isCollapsed = false});

  final bool isCollapsed;
  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  final AgoraClient _client = AgoraClient(
    agoraConnectionData: AgoraConnectionData(
      appId: '44fe75aa0bce4141bcfe093b6f9a6da2',
      channelName: 'temp',
      tempToken:
          '007eJxTYDifG50+bUKq6N/mzSwtxibzOhQsFxUvVE082Siikqq2r1GBwcQkLdXcNDHRICk51cTQxDApOS3VwNI4ySzNMtEsJdHIdFp7ckMgI0P2VgFGRgYIBPFZGEpScwsYGADTSR3G',
    ),
  );
  @override
  void initState() {
    super.initState();
    initAgora();
  }

  void initAgora() async {
    try {
      await _client.initialize();
    } catch (e) {
      // print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: getColor("background"),
        body: SafeArea(
          top: !widget.isCollapsed,
          child: Stack(
            children: [
              Hero(
                tag: "videocall",
                child: AgoraVideoViewer(
                  client: _client,
                  layoutType: Layout.floating,
                  disabledVideoWidget: Center(
                    child: Column(
                      children: [
                        // const Expanded(child: SizedBox()),
                        // ClipRRect(
                        //   borderRadius: BorderRadius.circular(150),
                        //   child: SizedBox(
                        //     width: 130,
                        //     height: 130,
                        //     child: ProfileImage(
                        //       url: profilePictures[currentConversation['email']] ?? "",
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 20),
                        // RichText(
                        //   text: TextSpan(
                        //     text: translation[currentLanguage]["incall"],
                        //     style: getFont("mainfont")(
                        //       color: getColor("secondarytext"),
                        //       fontSize: 20,
                        //     ),
                        //     children: [
                        //       TextSpan(
                        //         text: displayNames[currentConversation['email']],
                        //         style: getFont("mainfont")(
                        //           color: getColor("maintext"),
                        //           fontSize: 20,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // const Expanded(child: SizedBox()),
                        // SizedBox(
                        //   height: MediaQuery.of(context).size.height * 0.15,
                        // ),
                        Text(
                          translation[currentLanguage]["nocamera"],
                          style: getFont("mainfont")(
                            color: getColor("secondarytext"),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Theme(
                data: ThemeData(
                  primaryColor: getColor("secondarytext"),
                  backgroundColor: getColor("background2"),
                ),
                child: AgoraVideoButtons(
                  client: _client,
                  enabledButtons: widget.isCollapsed
                      ? []
                      : [
                          BuiltInButtons.toggleCamera,
                          BuiltInButtons.toggleMic,
                          BuiltInButtons.callEnd,
                          BuiltInButtons.switchCamera,
                        ],
                  disconnectButtonChild: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      endCall(
                        sessionController: _client.sessionController,
                      );
                      sendMessage("", currentConversation["email"], type: "callleft");
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // muteButtonChild: GestureDetector(
                  //   child: Builder(builder: (context) {
                  //     if(_client.)
                  //     return Container(
                  //       width: 50,
                  //       height: 50,
                  //       decoration: BoxDecoration(
                  //         color: getColor("background2"),
                  //         borderRadius: BorderRadius.circular(50),
                  //       ),
                  //       child: Icon(
                  //         Icons.mic,
                  //         color: getColor("secondarytext"),
                  //       ),
                  //     );
                  //   }),
                  // ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: prefer_const_constructors
Offset position = Offset(100, 100);
Offset dragPosition1 = const Offset(0, 0);
Offset dragPosition2 = const Offset(0, 0);
double xmodifier = 0;
double ymodifier = 0;

class VideoCallPnpOverlay extends StatefulWidget {
  const VideoCallPnpOverlay({super.key, required this.child});

  final Widget child;
  @override
  State<VideoCallPnpOverlay> createState() => _VideoCallPnpOverlayState();
}

class _VideoCallPnpOverlayState extends State<VideoCallPnpOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Builder(builder: (context) {
          // print(dragPosition1 - dragPosition2);
          double windowWidth = min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) / 3;
          double windowHeight = windowWidth * 1.5;
          if (position.dx < 0) {
            xmodifier += 2;
          } else {
            if (position.dx > MediaQuery.of(context).size.width - windowWidth) {
              xmodifier -= 2;
            } else {
              xmodifier *= 0.6;
            }
          }
          if (position.dy < 30) {
            ymodifier += 2;
          } else {
            if (position.dy > MediaQuery.of(context).size.height - windowHeight) {
              ymodifier -= 2;
            } else {
              ymodifier *= 0.6;
            }
          }

          Offset modifier = (dragPosition1 - dragPosition2);
          if (modifier.dx.abs() > 30) {
            modifier = Offset(0, modifier.dy);
            dragPosition1 = Offset(0, dragPosition1.dy);
            dragPosition2 = Offset(0, dragPosition2.dy);
          }
          if (modifier.dy.abs() > 30) {
            modifier = Offset(modifier.dx, 0);
            dragPosition1 = Offset(dragPosition1.dx, 0);
            dragPosition2 = Offset(dragPosition2.dx, 0);
          }
          modifier = Offset(modifier.dx + xmodifier, modifier.dy + ymodifier);
          position += modifier;
          dragPosition1 *= 0.8;
          dragPosition2 *= 0.8;
          Timer(const Duration(milliseconds: 15), () {
            if (mounted) {
              setState(() {});
            }
          });
          return Positioned(
            left: position.dx,
            top: position.dy,
            child: Align(
              child: Draggable(
                feedback: SizedBox(
                  width: windowWidth,
                  height: windowHeight,
                  child: Stack(
                    children: [
                      const AbsorbPointer(child: VideoCallView(isCollapsed: true)),
                      SizedBox(
                        width: windowWidth,
                        height: windowHeight,
                      ),
                    ],
                  ),
                ),
                childWhenDragging: const SizedBox(),
                onDragEnd: (details) => position = details.offset,
                onDragUpdate: (details) {
                  dragPosition2 = dragPosition1;
                  dragPosition1 = details.localPosition;
                },
                child: GestureDetector(
                  onDoubleTap: () {
                    context.pushTransparentRoute(const VideoCallView());
                  },
                  child: Hero(
                    tag: "videocall",
                    child: SizedBox(
                      width: windowWidth,
                      height: windowHeight,
                      child: Stack(
                        children: [
                          const AbsorbPointer(child: VideoCallView(isCollapsed: true)),
                          SizedBox(
                            width: windowWidth,
                            height: windowHeight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

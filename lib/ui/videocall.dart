import 'package:agora_uikit/controllers/rtc_buttons.dart';
import 'package:flutter/material.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/translation.dart';

import '../main.dart';

class VideoCallView extends StatefulWidget {
  const VideoCallView({super.key});

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  final AgoraClient _client = AgoraClient(
    agoraConnectionData: AgoraConnectionData(
      appId: '44fe75aa0bce4141bcfe093b6f9a6da2',
      channelName: 'temp',
      tempToken:
          '007eJxTYDDnlGxv052Xv/jgw6wJDz7l3IpbvNHpxYojq1kvG23TyXdXYDAxSUs1N01MNEhKTjUxNDFMSk5LNbA0TjJLs0w0S0k0EriZn9wQyMhwf78qMyMDBIL4LAwlqbkFDAwAspIhJg==',
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
          child: Stack(
            children: [
              AgoraVideoViewer(
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
              Theme(
                data: ThemeData(
                  primaryColor: getColor("secondarytext"),
                  backgroundColor: getColor("background2"),
                ),
                child: AgoraVideoButtons(
                  client: _client,
                  enabledButtons: const [
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
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(50),
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

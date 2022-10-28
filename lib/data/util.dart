// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:myst/ui/messages.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../main.dart';
import '../ui/mainscreen.dart';
import 'theme.dart';
import 'translation.dart';

List<double> interpolateBetween(int r1, int g1, int b1, int r2, int g2, int b2, double progress) {
  double r, g, b;
  progress = min(progress, 1);
  r = r1 + (r2 - r1) * progress;
  g = g1 + (g2 - g1) * progress;
  b = b1 + (b2 - b1) * progress;
  return [r, g, b];
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

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

bool increasing = false;
Curve curve = Curves.easeOut;

void pushReplacement(BuildContext context, Widget widget) {
  //increasing = true;
  //systemchrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
  Timer(const Duration(milliseconds: 2500), () {
    increasing = false;
  });
  Navigator.pushAndRemoveUntil(
    context,
    PageRouteBuilder(
      // ignore: prefer_const_constructors
      pageBuilder: (c, a1, a2) => widget,
      transitionsBuilder: (c, anim, a2, child) => ScaleTransition(
        scale: AlwaysStoppedAnimation<double>(
          (increasing) ? (curve.transform(anim.value) / 5) + 0.80 : 1,
        ),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
      transitionDuration: const Duration(
        milliseconds: 250,
      ),
    ),
    (Route<dynamic> route) => false,
  );
}

void push(BuildContext context, Widget widget) {
  //increasing = true;
  //systemchrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
  Timer(const Duration(milliseconds: 2500), () {
    increasing = false;
  });
  Navigator.push(
    context,
    PageRouteBuilder(
      // ignore: prefer_const_constructors
      pageBuilder: (c, a1, a2) => widget,
      transitionsBuilder: (c, anim, a2, child) => ScaleTransition(
        scale: AlwaysStoppedAnimation<double>(
          (increasing) ? (curve.transform(anim.value) / 5) + 0.80 : 1,
        ),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
      transitionDuration: const Duration(
        milliseconds: 250,
      ),
    ),
  );
}

const double bleedWidth = 20;

enum RevealSide { left, right, main }

RevealSide currentSide = RevealSide.main;
RevealSide swipeDirection = RevealSide.main;

class OverlappingPanels extends StatefulWidget {
  final Widget? left;
  final Widget main;
  final Widget? right;

  final double restWidth;

  final ValueChanged<RevealSide>? onSideChange;

  const OverlappingPanels({
    this.left,
    required this.main,
    this.right,
    this.restWidth = 50,
    this.onSideChange,
    Key? key,
  }) : super(key: key);

  static OverlappingPanelsState? of(BuildContext context) {
    return context.findAncestorStateOfType<OverlappingPanelsState>();
  }

  @override
  State<StatefulWidget> createState() {
    return OverlappingPanelsState();
  }
}

class OverlappingPanelsState extends State<OverlappingPanels> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 15), () {
      onTranslate(400);
      _onApplyTranslation();
      isSliding = true;
    });
  }

  AnimationController? controller;
  double translate = 0;

  double _calculateGoal(double width, int multiplier) {
    return (multiplier * width) + (-multiplier * widget.restWidth);
  }

  void _onApplyTranslation() {
    final mediaWidth = MediaQuery.of(context).size.width;

    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onSideChange != null) {
          widget.onSideChange!(
            translate == 0 ? RevealSide.main : (translate > 0 ? RevealSide.left : RevealSide.right),
          );
        }
        animationController.dispose();
      }
    });

    final currentSide = translate == 0 ? RevealSide.main : (translate > 0 ? RevealSide.left : RevealSide.right);
    bool currentlyOnMain = currentSide == swipeDirection;
    final divider = currentlyOnMain ? 16 : 1.2;
    isSliding = currentlyOnMain;
    if (translate.abs() >= mediaWidth / divider) {
      final multiplier = (translate > 0 ? 1 : -1);
      final goal = _calculateGoal(mediaWidth, multiplier);
      final Tween<double> tween = Tween(begin: translate, end: goal);

      final animation = tween.animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      );

      animation.addListener(() {
        setState(() {
          translate = animation.value;
        });
      });
    } else {
      final animation = Tween<double>(begin: translate, end: 0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      );

      animation.addListener(() {
        setState(() {
          translate = animation.value;
        });
      });
    }

    animationController.forward();
  }

  void reveal(RevealSide direction) {
    if (translate != 0) {
      return;
    }

    final mediaWidth = MediaQuery.of(context).size.width;

    final multiplier = (direction == RevealSide.left ? 1 : -1);
    final goal = _calculateGoal(mediaWidth, multiplier);

    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onApplyTranslation();
        animationController.dispose();
      }
    });

    final animation = Tween<double>(begin: translate, end: goal).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    animation.addListener(() {
      setState(() {
        translate = animation.value;
      });
    });

    animationController.forward();
  }

  void onTranslate(double delta, {bool shouldApplyTransition = false}) {
    setState(() {
      final translate = this.translate + delta;
      if (translate < 0 && widget.right != null || translate > 0 && widget.left != null) {
        this.translate = translate;
      }
      if (shouldApplyTransition) {
        _onApplyTranslation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Offstage(
        offstage: translate < 0,
        child: widget.left,
      ),
      Offstage(
        offstage: translate > 0,
        child: widget.right,
      ),
      Transform.translate(
        offset: Offset(translate, 0),
        child: widget.main,
      ),
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) {
          isSliding = true;
          onTranslate(details.delta.dx);
          if (details.delta.dx > 0) {
            swipeDirection = RevealSide.left;
          } else {
            swipeDirection = RevealSide.right;
          }
        },
        onHorizontalDragEnd: (details) {
          isSliding = false;
          _onApplyTranslation();
        },
      ),
    ]);
  }
}

extension StringExtension on String {
  double textHeight(TextStyle style, double textWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: this, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    final countLines = (textPainter.size.width / textWidth).ceil();
    final height = countLines * textPainter.size.height;
    return height;
  }
}

final key = encrypt.Key.fromBase64('yE9tgqNxWcYDTSPNM+EGQw==');
final iv = encrypt.IV.fromBase64('8PzGKSMLuqSm0MVbviaWHA==');

String encryptText(String text) {
  try {
    return encrypt.Encrypter(encrypt.AES(key)).encrypt(text, iv: iv).base64;
  } catch (e) {
    return "";
  }
}

String decryptText(String text) {
  try {
    return encrypt.Encrypter(encrypt.AES(key)).decrypt64(text, iv: iv);
  } catch (e) {
    return "";
  }
}

String hourMinuteFormat(int hour, int minute) {
  if (currentLanguage == "en") {
    String suffix = "AM";
    if (hour >= 12) {
      suffix = "PM";
      hour -= 12;
    }
    if (hour == 0 && suffix == "PM") {
      hour = 12;
    }
    String minuteString = minute.toString();
    if (minuteString.length == 1) {
      minuteString = "0$minuteString";
    }

    return "$hour:$minuteString $suffix";
  } else {
    String minuteString = minute.toString();
    if (minuteString.length == 1) {
      minuteString = "0$minuteString";
    }
    String hourString = hour.toString();
    if (hourString.length == 1) {
      hourString = "0$hourString";
    }
    return "$hourString:$minuteString";
  }
}

String timestampToDate(int timestamp, {bool showOnlyDate = false}) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  DateTime now = DateTime.now();
  String daySuffix = "";
  if (currentLanguage == "en") {
    if (date.day == 1 || date.day == 21 || date.day == 31) {
      daySuffix = "st";
    } else if (date.day == 2 || date.day == 22) {
      daySuffix = "nd";
    } else if (date.day == 3 || date.day == 23) {
      daySuffix = "rd";
    } else {
      daySuffix = "th";
    }
  } else {
    daySuffix = ".";
  }
  String theDate =
      "${translation[currentLanguage]['monthprefix${date.month}']}${date.day}$daySuffix ${translation[currentLanguage]['monthsuffix${date.month}']}";
  if (showOnlyDate) {
    if (currentLanguage == "en") {
      return "$theDate, ${date.year}";
    } else {
      return "${date.year} $theDate";
    }
  }
  if (date.day == now.day && date.month == now.month && date.year == now.year) {
    return "${translation[currentLanguage]['todayat']} ${hourMinuteFormat(date.hour, date.minute)}${translation[currentLanguage]['todayat2']}";
  }
  if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
    return "${translation[currentLanguage]['yesterdayat']} ${hourMinuteFormat(date.hour, date.minute)}${translation[currentLanguage]['yesterdayat2']}";
  }

  if (date.year == now.year) {
    if (currentLanguage == "en") {
      return "${hourMinuteFormat(date.hour, date.minute)}, $theDate";
    } else {
      return "$theDate${hourMinuteFormat(date.hour, date.minute)}";
    }
  }
  if (currentLanguage == "en") {
    return "${hourMinuteFormat(date.hour, date.minute)}, $theDate, ${date.year}";
  } else {
    return "${date.year} $theDate${hourMinuteFormat(date.hour, date.minute)}";
  }
}

Map downloadedMedia = {
  "default": Image.network(
    "https://i.pinimg.com/736x/6b/f6/2c/6bf62c6c123cdcd33d2d693782a46b34.jpg",
  ).image
};

class ProfileImage extends StatefulWidget {
  const ProfileImage({
    Key? key,
    this.url = "",
    this.type = "profile",
    this.username = "",
  }) : super(key: key);
  final String url;
  final String type;
  final String username;

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  @override
  Widget build(BuildContext context) {
    if (widget.url == "empty") {
      return Container();
    }
    if (widget.url.isEmpty || widget.url.contains(" ") || !widget.url.contains("https://")) {
      if (widget.type == "profile") {
        return Image(
          image: downloadedMedia["default"],
        );
      }
      if (widget.username == "sentimage") {
        return const SizedBox();
      }
      String myName = widget.username.isEmpty ? myDisplayName : widget.username;
      if (myName.length < 3) {
        myName += "   ";
      }
      Color color = Color.fromARGB(
        255,
        (myName.codeUnitAt(0) % 10 * 25.5).round(),
        (myName.codeUnitAt(1) % 10 * 25.5).round(),
        (myName.codeUnitAt(2) % 10 * 25.5).round(),
      ).withOpacity(0.2);

      return Container(
        width: double.infinity,
        height: double.infinity,
        color: color,
      );
    }
    if (!downloadedMedia.containsKey(widget.url)) {
      downloadedMedia[widget.url] = Image.network(
        widget.url,
      ).image;
    }
    if (widget.type == "profile") {
      return AspectRatio(
        aspectRatio: 1,
        child: Image(
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
            return Image(
              image: downloadedMedia["default"],
            );
          },
          image: downloadedMedia[widget.url],
        ),
      );
    } else {
      return Image(
        fit: widget.type == "image" ? BoxFit.fitHeight : BoxFit.fitWidth,
        width: double.infinity,
        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
          return Image(
            image: downloadedMedia["default"],
          );
        },
        image: downloadedMedia[widget.url],
      );
    }
  }
}

bool hasConnection = true;
Future<bool> hasNetwork() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    return hasConnection;
  } on SocketException catch (_) {
    hasConnection = false;
    return false;
  }
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}

void showCustomDialog(
  BuildContext context,
  String title,
  String content,
  List<Widget> actions,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      actions.add(
        TextButton(
          child: Text(
            translation[currentLanguage]["cancel"],
            style: getFont("mainfont")(
              fontSize: 14,
              color: getColor("secondarytext"),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      );
      actions = actions.reversed.toList();
      return AlertDialog(
        backgroundColor: getColor("background"),
        title: Text(
          title,
          style: getFont("mainfont")(
            fontSize: 20,
            color: getColor("maintext"),
          ),
        ),
        content: Text(
          content,
          style: getFont("mainfont")(
            fontSize: 14,
            color: getColor("secondarytext"),
          ),
        ),
        actions: actions,
      );
    },
  );
}

Future<List<String>> getRandomQuote() async {
  String response = (await http.get(Uri.parse("https://zenquotes.io/api/random"))).body;
  if (jsonDecode(response)[0]["q"].contains("Too many requests")) {
    return ["", ""];
  }
  return [jsonDecode(response)[0]["q"], jsonDecode(response)[0]["a"]];
}

TransformationController _transformationController = TransformationController();
TapDownDetails _doubleTapDetails = TapDownDetails();

class ImageView extends StatefulWidget {
  const ImageView({super.key, required this.url});
  final String url;
  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) {
        _doubleTapDetails = details;
      },
      onDoubleTap: (() {
        //if (_transformationController.value != Matrix4.identity()) {
        //  _transformationController.value = Matrix4.identity();
        //} else {
        final position = _doubleTapDetails.localPosition;
        bool zoomDirection = _transformationController.value == Matrix4.identity();
        double zoomProgress = zoomDirection ? 0 : 1;

        double incromentAmount = zoomDirection ? 0.05 : -0.05;
        Timer.periodic(const Duration(milliseconds: 10), (timer) {
          double adjustedZoomProgress = Curves.easeInOut.transform(zoomProgress) * (zoomDirection ? 1 : _transformationController.value[0] / 2);
          _transformationController.value = Matrix4.identity()
            ..translate(-position.dx * adjustedZoomProgress, -position.dy * adjustedZoomProgress)
            ..scale(1 + adjustedZoomProgress);
          zoomProgress += incromentAmount;
          if (zoomProgress >= 1 && zoomDirection) {
            zoomProgress = 1;
            timer.cancel();
            adjustedZoomProgress = Curves.easeInOut.transform(zoomProgress);
            _transformationController.value = Matrix4.identity()
              ..translate(-position.dx * adjustedZoomProgress, -position.dy * adjustedZoomProgress)
              ..scale(1 + adjustedZoomProgress);
          }
          if (zoomProgress <= 0 && !zoomDirection) {
            zoomProgress = 0;
            timer.cancel();
            adjustedZoomProgress = Curves.easeInOut.transform(zoomProgress);
            _transformationController.value = Matrix4.identity()
              ..translate(-position.dx * adjustedZoomProgress, -position.dy * adjustedZoomProgress)
              ..scale(1 + adjustedZoomProgress);
          }
        });
        //}
      }),
      child: DismissiblePage(
        onDismissed: () {
          //systemchrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
          Timer(const Duration(milliseconds: 200), () {
            Timer.periodic(const Duration(milliseconds: 10), (timer) {
              imageRoundedAmount += 0.03;
              if (imageRoundedAmount >= 1) {
                imageRoundedAmount = 1;
                timer.cancel();
              }
              if (mounted) {
                setState(() {});
              }
            });
          });
          Navigator.of(context).pop();
        },
        direction: DismissiblePageDismissDirection.multi,
        isFullScreen: true,
        child: //Hero(
            //tag: widget.url,
            //child:
            InteractiveViewer(
          transformationController: _transformationController,
          onInteractionStart: (details) {
            Offset offset = details.localFocalPoint;
            if (details.pointerCount == 1 &&
                (offset.dx < 60 || offset.dx > MediaQuery.of(context).size.width - 60 || offset.dy > MediaQuery.of(context).size.height - 140)) {
              Timer(const Duration(milliseconds: 200), () {
                Timer.periodic(const Duration(milliseconds: 10), (timer) {
                  imageRoundedAmount += 0.03;
                  if (imageRoundedAmount >= 1) {
                    imageRoundedAmount = 1;
                    timer.cancel();
                  }
                  if (mounted) {
                    setState(() {});
                  }
                });
              });
              Navigator.of(context).pop();
            }
          },
          maxScale: 4,
          minScale: 1,
          child: ProfileImage(
            url: widget.url,
            type: "banner",
            username: "sentimage",
          ),
        ),
      ),
      //),
    );
  }
}

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({Key? key, required this.url}) : super(key: key);
  final String url;
  @override
  _VideoPlayerViewState createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late VideoPlayerController _controller;

  void _playVideo({bool init = false}) {
    _controller = (downloadedMedia[widget.url] ?? VideoPlayerController.network(widget.url))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      // ..setLooping(true)
      ..initialize().then((_) {
        //_controller.play();
        setState(() {});
      });
  }

  @override
  void initState() {
    super.initState();
    _playVideo(init: true);
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(_controller),
                const Opacity(opacity: 0.7, child: Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 75))),
              ],
            ),
          )
        : Container();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

int lastVideoStateChange = 0;

class FullscreenVideoPlayerView extends StatefulWidget {
  const FullscreenVideoPlayerView({Key? key, required this.url}) : super(key: key);
  final String url;
  @override
  _FullscreenVideoPlayerViewState createState() => _FullscreenVideoPlayerViewState();
}

class _FullscreenVideoPlayerViewState extends State<FullscreenVideoPlayerView> {
  late VideoPlayerController _controller;

  void _playVideo({bool init = false}) {
    _controller = (VideoPlayerController.network("https://i.imgur.com/3fkG0PD.mp4"))
      //_controller = (downloadedMedia[widget.url] ?? VideoPlayerController.network(widget.url))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..setLooping(true)
      ..initialize().then((_) {
        _controller.play();
        setState(() {});
      });
  }

  @override
  void initState() {
    super.initState();
    _playVideo(init: true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //systemchrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
        return true;
      },
      child: GestureDetector(
        onTap: () {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
          lastVideoStateChange = DateTime.now().millisecondsSinceEpoch;
          //systemchrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
          Timer(const Duration(milliseconds: 2000), () {
            //systemchrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
          });
        },
        child: DismissiblePage(
          onDismissed: () {
            Timer(const Duration(milliseconds: 200), () {
              Timer.periodic(const Duration(milliseconds: 10), (timer) {
                imageRoundedAmount += 0.03;
                if (imageRoundedAmount >= 1) {
                  imageRoundedAmount = 1;
                  timer.cancel();
                }
                if (mounted) {
                  setState(() {});
                }
              });
            });
            Navigator.of(context).pop();
          },
          direction: DismissiblePageDismissDirection.multi,
          isFullScreen: false,
          child: //Hero(
              //tag: widget.url,
              //child:
              Scaffold(
            backgroundColor: Colors.black,
            body: _controller.value.isInitialized
                ? Stack(
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: Stack(
                            children: [
                              VideoPlayer(_controller),
                              Builder(builder: (context) {
                                Timer(const Duration(milliseconds: 100), () {
                                  setState(() {});
                                });
                                return AnimatedOpacity(
                                  opacity: DateTime.now().millisecondsSinceEpoch - lastVideoStateChange < 500 ? 0.75 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Center(
                                    child: Icon(_controller.value.isPlaying ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 100),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                          lastVideoStateChange = DateTime.now().millisecondsSinceEpoch;
                          //systemchrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
                          Timer(const Duration(milliseconds: 2000), () {
                            //systemchrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
                          });
                        },
                        child: AnimatedOpacity(
                          opacity: DateTime.now().millisecondsSinceEpoch - lastVideoStateChange < 2500 ? 0.75 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                              child: Column(
                                children: [
                                  const Expanded(
                                    child: SizedBox(
                                      height: double.infinity,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _controller.value.position.toString().split(".")[0],
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: _controller.value.position.inMilliseconds / _controller.value.duration.inMilliseconds,
                                          onChanged: (value) {
                                            _controller.seekTo(Duration(milliseconds: (value * _controller.value.duration.inMilliseconds).toInt()));
                                            _controller.play();
                                          },
                                        ),
                                      ),
                                      Text(
                                        _controller.value.duration.toString().split(".")[0],
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                : Container(),
          ),
        ),
        //),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

RegExp emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

Future<String> filePathFromUrl(String url) async {
  //print("audiourl$url");
  final response = await http.get(Uri.parse(url));
  final documentDirectory = await getApplicationDocumentsDirectory();
  final file = File('${documentDirectory.path}imagetest.png');
  file.writeAsBytesSync(response.bodyBytes);
  return file.path;
}

class AudioWaveformWidget extends StatefulWidget {
  final Color waveColor;
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Waveform waveform;
  final Duration start;
  final Duration duration;

  const AudioWaveformWidget({
    Key? key,
    required this.waveform,
    required this.start,
    required this.duration,
    this.waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 5.0,
    this.pixelsPerStep = 8.0,
  }) : super(key: key);

  @override
  _AudioWaveformState createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveformWidget> {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: AudioWaveformPainter(
          waveColor: widget.waveColor,
          waveform: widget.waveform,
          start: widget.start,
          duration: widget.duration,
          scale: widget.scale,
          strokeWidth: widget.strokeWidth,
          pixelsPerStep: widget.pixelsPerStep,
        ),
      ),
    );
  }
}

class AudioWaveformPainter extends CustomPainter {
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Paint wavePaint;
  final Waveform waveform;
  final Duration start;
  final Duration duration;

  AudioWaveformPainter({
    required this.waveform,
    required this.start,
    required this.duration,
    Color waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 5.0,
    this.pixelsPerStep = 8.0,
  }) : wavePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    double width = size.width;
    double height = size.height;

    final waveformPixelsPerWindow = waveform.positionToPixel(duration).toInt();
    final waveformPixelsPerDevicePixel = waveformPixelsPerWindow / width;
    final waveformPixelsPerStep = waveformPixelsPerDevicePixel * pixelsPerStep;
    final sampleOffset = waveform.positionToPixel(start);
    final sampleStart = -sampleOffset % waveformPixelsPerStep;
    for (var i = sampleStart.toDouble(); i <= waveformPixelsPerWindow + 1.0; i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      final x = i / waveformPixelsPerDevicePixel;
      final minY = normalise(waveform.getPixelMin(sampleIdx), height);
      final maxY = normalise(waveform.getPixelMax(sampleIdx), height);
      canvas.drawLine(
        Offset(x + strokeWidth / 2, max(strokeWidth * 0.75, minY)),
        Offset(x + strokeWidth / 2, min(height - strokeWidth * 0.75, maxY)),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return false;
  }

  double normalise(int s, double height) {
    if (waveform.flags == 0) {
      final y = 32768 + (scale * s).clamp(-32768.0, 32767.0).toDouble();
      return height - 1 - y * height / 65536;
    } else {
      final y = 128 + (scale * s).clamp(-128.0, 127.0).toDouble();
      return height - 1 - y * height / 256;
    }
  }
}

void downloadFile(String path) async {
  final storageRef = FirebaseStorage.instance.ref();
  final fileRef = storageRef.child(path);

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.absolute}/$path');

  await fileRef.writeToFile(file);
}

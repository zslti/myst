import 'package:flutter/material.dart';
import 'package:myst/data/theme.dart';
import 'package:myst/data/util.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  @override
  Widget build(BuildContext context) {
    return OverlappingPanels(
      main: Scaffold(
        backgroundColor: getColor("background"),
      ),
      left: const Scaffold(
        backgroundColor: Colors.red,
      ),
      right: const Scaffold(
        backgroundColor: Colors.blue,
      ),
    );
  }
}

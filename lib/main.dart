import 'package:flutter/material.dart';
import 'package:seldat/LogAnalysis.dart';
import 'package:seldat/settings.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIdx = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            NavigationRail(
                selectedIndex: _selectedIdx,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (int value) => {
                      setState(() {
                        _selectedIdx = value;
                      })
                    },
                destinations: const [
                  NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      label: Text("Log Analysis")),
                  NavigationRailDestination(
                      icon: Icon(Icons.settings), label: Text("Settings")),
                ]),
            const VerticalDivider(
              width: 1.0,
            ),
            Expanded(
                child: switch (_selectedIdx) {
              0 => LogAnalysis(),
              1 => const SetupPage(),
              int() => throw UnimplementedError(),
            }),
          ],
        ),
      ),
    );
  }
}

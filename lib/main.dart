import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seldat/Dashboard.dart';
import 'package:seldat/LogAnalysis.dart';
import 'package:seldat/settings.dart';
import 'dart:io';

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
  bool scanning = false;
  StreamController<File> evtxStreamController = StreamController<File>();
  List<File> eventLogList = List.empty(growable: true);

  Stream<File> scanFiles(Directory dir) async* {
    try {
      var dirList = dir.list();
      await for (final FileSystemEntity entity in dirList) {
        if (entity is File) {
          yield entity;
          setState(() {
            if (entity.path.endsWith(".csv")) {
              // TODO : Turn this to evtx and parse it
              eventLogList.add(entity);
            }
          });
        } else if (entity is Directory) {
          yield* scanFiles(Directory(entity.path));
        }
      }
    } on PathAccessException {
      return;
    }
  }

  void start() {
    if (!scanning) {
      scanFiles(Directory('./')).listen((event) {
        // print(event.path);
        if (event.path.endsWith('.evtx.csv')) {
          // print(event.path);
          evtxStreamController.add(event);
        }
      });
      scanning = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Seldat",
                style: TextStyle(color: Colors.white),
              ),
              OutlinedButton(
                  onPressed: start,
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.amber)),
                  child: const Text("Analyze"))
            ],
          ),
          backgroundColor: Colors.redAccent,
          centerTitle: false,
        ),
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
                      icon: Icon(Icons.dashboard), label: Text("Overall")),
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
                child: !scanning
                    ? const Center(child: Text('Analyze with Seldat!'))
                    : switch (_selectedIdx) {
                        0 => Dashboard(),
                        1 => LogAnalysis(fileList: eventLogList),
                        2 => const SetupPage(),
                        int() => throw UnimplementedError(),
                      }),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:seldat/Dashboard.dart';
import 'package:seldat/LogAnalysis.dart';
import 'package:seldat/Registry.dart';
import 'package:seldat/Report.dart';
import 'package:seldat/settings.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
      size: Size(1600, 1000),
      center: true,
      title: "Seldat",
      titleBarStyle: TitleBarStyle.hidden,
      skipTaskbar: false,
      backgroundColor: Colors.white,
      windowButtonVisibility: false);

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setAsFrameless();
    await windowManager.setResizable(true);
  });

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with SingleTickerProviderStateMixin {
  bool scanning = false;
  late TabController tabController = TabController(length: 3, vsync: this);
  final Color _primaryColor = const Color.fromARGB(255, 0xFF, 0x61, 0x61);
  bool isMaximized = false;

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black87,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            )
          ]),
      child: MaterialApp(
        color: Colors.transparent,
        home: Scaffold(
          appBar: AppBar(
            shadowColor: Colors.black,
            title: GestureDetector(
              onPanDown: (DragDownDetails details) {
                windowManager.startDragging();
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon(icon: Icons.menu, color: Colors.white),
                  Text(
                    "Seldat",
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        color: _primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.minimize),
                        onPressed: () {
                          print("minimize");
                          windowManager.minimize();
                        },
                      ),
                      IconButton(
                        icon: isMaximized
                            ? const Icon(Icons.maximize_rounded)
                            : const Icon(Icons.maximize),
                        onPressed: () {
                          if (isMaximized) {
                            windowManager.unmaximize();
                          } else {
                            windowManager.maximize();
                          }
                          setState(() {
                            isMaximized = !isMaximized;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          windowManager.close();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.white,
            centerTitle: false,
          ),
          body: Column(
            children: [
              _tabBar(),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: const [
                    Dashboard(),
                    Report(),
                    SetupPage(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBar() {
    return TabBar(
      controller: tabController,
      labelColor: const Color.fromARGB(255, 0xFF, 0x61, 0x61),
      indicatorColor: const Color.fromARGB(255, 0xFF, 0x61, 0x61),
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      dividerHeight: 2.0,
      tabs: const [
        Tab(
          height: 35,
          text: "Dashboard",
        ),
        Tab(height: 35, text: "Report"),
        Tab(height: 35, text: "Settings")
      ],
    );
  }
}

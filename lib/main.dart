import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paged_datatable/l10n/generated/l10n.dart';
import 'package:seldat/Dashboard/DashboardSkeleton.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:seldat/LogAnalysis.dart';
import 'package:seldat/LogAnalysis/LogFetcher.dart';
import 'package:seldat/Registry/RegistryFetcher.dart';
import 'package:seldat/Report/ReportSkeleton.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:seldat/Dashboard.dart';
import 'package:seldat/Report.dart';
import 'package:seldat/settings.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WindowOptions windowOptions = const WindowOptions(
      size: Size(1600, 1000),
      center: true,
      title: "SELDAT",
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
  DatabaseManager db = DatabaseManager();
  late TabController tabController = TabController(length: 4, vsync: this);
  final Color _primaryColor = const Color.fromARGB(255, 0xFF, 0x61, 0x61);
  bool isMaximized = false;
  late LogFetcher logFetcher;
  RegistryFetcher registryFetcher = RegistryFetcher();
  bool scanned = false;

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    db.open();
    logFetcher = LogFetcher(db);
    super.initState();
    logFetcher.setAddCount(addEventLog);
    registryFetcher.setAddCount(addRegistry);

    logFetcher.loadDB().then((value) => {
          if (value)
            {
              setState(() {
                scanned = true;
              })
            }
        });
    // registryFetcher.setAddSRUM(addSRUM);
    // registryFetcher.setAddPrefetch(addPrefetch);
    // registryFetcher.setAddJumplist(addJumplist);
  }

  void startScan() async {
    setState(() {
      scanned = true;
    });
    logFetcher.setAddCount(addEventLog);
    logFetcher.scanFiles(Directory('C:\\Windows\\System32\\winevt\\Logs'));
    // registryFetcher.fetchRegistry();
  }

  int evtxCount = 0;
  int regCount = 0;
  int srumCount = 0;
  int prefetchCount = 0;
  int jumplistCount = 0;

  void addEventLog(int count) {
    setState(() {
      evtxCount += count;
    });
  }

  void addRegistry(int count) {
    setState(() {
      regCount += count;
    });
  }

  void addSRUM() {
    setState(() {
      srumCount++;
    });
  }

  void addPrefetch() {
    setState(() {
      prefetchCount++;
    });
  }

  void addJumplist() {
    setState(() {
      jumplistCount++;
    });
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
        localizationsDelegates: const [
          PagedDataTableLocalization.delegate,
        ],
        color: Colors.transparent,
        home: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            shadowColor: Colors.black,
            title: GestureDetector(
              onTapDown: (TapDownDetails detail) {
                windowManager.startDragging();
              },
              behavior: HitTestBehavior.translucent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon(icon: Icons.menu, color: Colors.white),
                  Text(
                    "SELDAT",
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
                  children: [
                    if (scanned)
                      Dashboard(
                          evtxCount: evtxCount,
                          regCount: regCount,
                          srumCount: srumCount,
                          prefetchCount: prefetchCount,
                          jumplistCount: jumplistCount)
                    else
                      DashboardSkeleton(startAnalysis: startScan),
                    if (scanned)
                      Report(
                        logFetcher: logFetcher,
                        registryFetcher: registryFetcher,
                      )
                    else
                      const ReportSkeleton(),
                    const SetupPage(),
                    Center(
                      child: Column(
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                addEventLog(1);
                              },
                              child: const Text("Add Evtx")),
                          ElevatedButton(
                              onPressed: () {
                                addRegistry(1);
                              },
                              child: const Text("Add Registry")),
                          ElevatedButton(
                              onPressed: () {
                                addSRUM();
                              },
                              child: const Text("Add SRUM")),
                          ElevatedButton(
                              onPressed: () {
                                addPrefetch();
                              },
                              child: const Text("Add Prefetch")),
                          ElevatedButton(
                              onPressed: () {
                                addJumplist();
                              },
                              child: const Text("Add Jumplist")),
                          ElevatedButton(
                              onPressed: () {
                                logFetcher.runAIModelPredict();
                              },
                              child: const Text("Run AI Model")),
                        ],
                      ),
                    ),
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
        Tab(height: 35, text: "Settings"),
        Tab(height: 35, text: "Test"),
      ],
    );
  }
}

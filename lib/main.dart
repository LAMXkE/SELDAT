import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paged_datatable/l10n/generated/l10n.dart';
import 'package:seldat/Dashboard/DashboardSkeleton.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:seldat/JumpList/JumpListFetcher.dart';
import 'package:seldat/LogAnalysis/LogFetcher.dart';
import 'package:seldat/Registry/RegistryFetcher.dart';
import 'package:seldat/Report/ReportSkeleton.dart';
import 'package:seldat/srum/SrumFetcher.dart';
import 'package:seldat/Prefetch/PrefetchFetcher.dart';
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

class MyMaterialScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      controller: details.controller,
      child: child,
    );
  }
}

class _MainAppState extends State<MainApp> with SingleTickerProviderStateMixin {
  DatabaseManager db = DatabaseManager();
  late TabController tabController = TabController(length: 4, vsync: this);
  final Color _primaryColor = const Color.fromARGB(255, 0xFF, 0x61, 0x61);
  bool isMaximized = false;
  late LogFetcher logFetcher;
  late RegistryFetcher registryFetcher;
  late Srumfetcher srumFetcher;
  late Prefetchfetcher prefetchFetcher;
  late JumplistFetcher jumplistFetcher;
  bool scanned = false;
  bool loadingFromDB = false;
  List<int> loadingStatus = [1, 1, 1, 1, 1];
  List<String> dbList = [];
  String DBPath = '';

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void checkScanned() {
    print("CURRENT STATE: ------------------");
    print("log: ${logFetcher.isFetched}");
    print("registry: ${registryFetcher.isFetched}");
    print("srum: ${srumFetcher.isFetched}");
    print("prefetch: ${prefetchFetcher.isFetched}");
    print("jumplist: ${jumplistFetcher.isFetched}");
    print("-------------------------------");

    setState(() {
      if (logFetcher.isFetched) {
        loadingStatus[0] = 0;
      }
      if (registryFetcher.isFetched) {
        loadingStatus[1] = 0;
      }
      if (srumFetcher.isFetched) {
        loadingStatus[2] = 0;
      }
      if (prefetchFetcher.isFetched) {
        loadingStatus[3] = 0;
      }
      if (jumplistFetcher.isFetched) {
        loadingStatus[4] = 0;
      }
    });

    if (logFetcher.isFetched &&
        // registryFetcher.isFetched &&
        srumFetcher.isFetched) {
      Future.delayed(const Duration(seconds: 1), () {}).then(
        (value) {
          setState(() {
            scanned = true;
          });
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();

    Directory.current.listSync().forEach((element) {
      if (element.path.contains(".db")) {
        print("[*] Database found at ${element.path}");
        dbList.add(element.path);
      }
    });

    if (dbList.isNotEmpty) {
      loadingFromDB = true;
    }
  }

  void initFetcher() {
    db.open().then((value) {
      logFetcher = LogFetcher(db);
      srumFetcher = Srumfetcher(db);
      registryFetcher = RegistryFetcher(db);
      prefetchFetcher = Prefetchfetcher(db);
      jumplistFetcher = JumplistFetcher(db);

      logFetcher.setAddCount(addEventLog);
      registryFetcher.setAddCount(addRegistry);
      srumFetcher.setAddCount(addSRUM);
      prefetchFetcher.setAddCount(addPrefetch);
      jumplistFetcher.setAddCount(addJumplist);
      if (!loadingFromDB) {
        return;
      }

      logFetcher.loadDB().then((value) {
        print("log loaded");
        checkScanned();
      });
      srumFetcher.loadDB().then((value) {
        print("srum loaded");
        checkScanned();
      });
      registryFetcher.loadDB().then((value) {
        print("registry loaded");
        checkScanned();
      });
      prefetchFetcher.loadDB().then((value) {
        print("prefetch loaded");
        checkScanned();
      });
      jumplistFetcher.loadDB().then((value) {
        print("jumplist loaded");
        checkScanned();
      });
    });
  }

  void startScan() async {
    if (loadingFromDB) return;

    if (!logFetcher.isFetched) {
      logFetcher
          .scanFiles(Directory('C:\\Windows\\System32\\winevt\\Logs'))
          .then((onValue) {
        checkScanned();
      });
    }
    if (!srumFetcher.isFetched) {
      srumFetcher.fetchSrumData().then((onValue) {
        checkScanned();
      });
    }

    if (!registryFetcher.isFetched) {
      registryFetcher.fetchAllRegistryData().then((onValue) {
        checkScanned();
      });
    }

    if (!prefetchFetcher.isFetched) {
      prefetchFetcher.getAllPrefetchFile().then((onValue) {
        checkScanned();
      });
    }

    if (!jumplistFetcher.isFetched) {
      jumplistFetcher.getAllJumpListFile().then((onValue) {
        checkScanned();
      });
    }

    setState(() {
      scanned = true;
    });
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

  void addSRUM(int cnt) {
    setState(() {
      srumCount += cnt;
    });
  }

  void addPrefetch(int cnt) {
    setState(() {
      prefetchCount += cnt;
    });
  }

  void addJumplist(int cnt) {
    setState(() {
      jumplistCount += cnt;
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
        scrollBehavior: MyMaterialScrollBehavior(),
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
                          db.close();
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
                      DashboardSkeleton(
                          startAnalysis: startScan,
                          chooseDB: (String dbpath) {
                            setState(() {
                              db.dbName = dbpath;
                            });
                            initFetcher();
                          },
                          chosen: db.dbName != '' ? true : false,
                          dbList: dbList,
                          loadfromDB: loadingFromDB,
                          setLoadfromDB: (value) {
                            setState(() {
                              loadingFromDB = value;
                            });
                          },
                          loadingStatus: loadingStatus),
                    if (scanned)
                      Report(
                        logFetcher: logFetcher,
                        registryFetcher: registryFetcher,
                        srumfetcher: srumFetcher,
                        prefetchFetcher: prefetchFetcher,
                        jumplistFetcher: jumplistFetcher,
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
                                addSRUM(1);
                              },
                              child: const Text("Add SRUM")),
                          ElevatedButton(
                              onPressed: () {
                                addPrefetch(1);
                              },
                              child: const Text("Add Prefetch")),
                          ElevatedButton(
                              onPressed: () {
                                addJumplist(1);
                              },
                              child: const Text("Add Jumplist")),
                          ElevatedButton(
                              onPressed: () {
                                logFetcher.runAIModelPredict();
                              },
                              child: const Text("Run AI Model")),
                          ElevatedButton(
                              onPressed: () {
                                srumFetcher.fetchSrumData();
                              },
                              child: const Text("Fetch SRUM")),
                          ElevatedButton(
                              onPressed: () {
                                registryFetcher.fetchAllRegistryData();
                              },
                              child: const Text("Fetch Registry")),
                          ElevatedButton(
                              onPressed: () {
                                prefetchFetcher.getAllPrefetchFile();
                              },
                              child: const Text("Fetch Prefetch")),
                          ElevatedButton(
                              onPressed: () {
                                jumplistFetcher.getAllJumpListFile();
                              },
                              child: const Text("Fetch Jumplist")),
                          Row(
                            children: [
                              const TextField(
                                decoration: InputDecoration(
                                    hintText: "Enter a directory"),
                              ),
                              ElevatedButton(
                                  onPressed: () {}, child: const Text("test"))
                            ],
                          )
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

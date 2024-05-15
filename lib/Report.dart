import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seldat/LogAnalysis.dart';
import 'package:seldat/LogAnalysis/FileView.dart';
import 'dart:io';

import 'package:seldat/LogAnalysis/LogFetcher.dart';
import 'package:seldat/Registry.dart';
import 'package:seldat/Registry/RegistryFetcher.dart';

class Report extends StatefulWidget {
  final LogFetcher logFetcher;
  final RegistryFetcher registryFetcher;
  const Report({
    super.key,
    required this.logFetcher,
    required this.registryFetcher,
  });

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    print("Report");
  }

  late TabController reportTabController =
      TabController(length: 4, vsync: this);

  @override
  void dispose() {
    reportTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _tabBar(),
        Expanded(
          child: TabBarView(
            controller: reportTabController,
            children: [
              LogAnalysis(
                logFetcher: widget.logFetcher,
              ),
              RegistryUI(
                registryFetcher: widget.registryFetcher,
              ),
              const Center(child: Text("SRUM Placeholder")),
              const Center(child: Text("Prefetch Placeholder")),
            ],
          ),
        )
      ],
    );
    return Row(
      children: [
        Flexible(
          flex: 7,
          child: Column(
            children: [
              Flexible(
                flex: 4,
                child: Row(
                  children: [
                    Flexible(
                      flex: 3,
                      child: Container(
                          clipBehavior: Clip.hardEdge,
                          alignment: Alignment.topLeft,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1.0,
                              color: Colors.black54,
                            ),
                          ),
                          child: Column(
                            children: [
                              ExpansionTile(
                                title: const Text(".Evtx"),
                                children: [
                                  SizedBox(
                                    height: 200,
                                    child: FileView(
                                      files: widget.logFetcher.eventLogFileList,
                                    ),
                                  )
                                ],
                              ),
                              ExpansionTile(
                                  title: const Text("Registry"),
                                  children: [
                                    SizedBox(
                                      height: 300,
                                      child: RegistryUI(
                                        registryFetcher: widget.registryFetcher,
                                      ),
                                    ),
                                  ]),
                            ],
                          )),
                    ),
                    const Flexible(
                      flex: 7,
                      child: Center(child: Text("Graph Placeholder")),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54),
                  ),
                  child: const Center(
                    child: Text("log timeline placeholder"),
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54),
            ),
            child: const Center(
              child: Text("Detail Placeholder"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabBar() {
    return TabBar(
        controller: reportTabController,
        labelColor: Colors.black,
        tabAlignment: TabAlignment.fill,
        tabs: const [
          Tab(
            height: 35,
            child: Text("Log Analysis"),
          ),
          Tab(
            height: 35,
            child: Text("Registry"),
          ),
          Tab(
            height: 35,
            child: Text("SRUM"),
          ),
          Tab(height: 35, child: Text("Prefetch")),
        ]);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seldat/LogAnalysis.dart';
import 'package:seldat/LogAnalysis/FileView.dart';
import 'dart:io';

import 'package:seldat/LogAnalysis/LogFetcher.dart';
import 'package:seldat/Registry.dart';
import 'package:seldat/Registry/RegistryFetcher.dart';
import 'package:seldat/Prefetch/PrefetchViewer.dart';
import 'package:seldat/srum/SrumFetcher.dart';
import 'package:seldat/srum/SrumView.dart';
import 'package:seldat/JumpList/JumpListViewer.dart';

class Report extends StatefulWidget {
  final LogFetcher logFetcher;
  final RegistryFetcher registryFetcher;
  final Srumfetcher srumfetcher;
  const Report({
    super.key,
    required this.logFetcher,
    required this.registryFetcher,
    required this.srumfetcher,
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
      TabController(length: 5, vsync: this);

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
              // const Text("Log Analysis"),
              LogAnalysis(
                logFetcher: widget.logFetcher,
              ),
              RegistryUI(
                registryFetcher: widget.registryFetcher,
              ),
              // const Text('Registry'),
              // SrumView(srumfetcher: widget.srumfetcher),
              SrumView(srumfetcher: widget.srumfetcher),
              PrefetchViewer(), // PrefetchViewer() 위젯 추가
              JumplistViewer(), // JumpListViewer() 위젯 추가
            ],
          ),
        )
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
          Tab(
            height: 35,
            child: Text("Prefetch"),
          ),
          Tab(
            height: 35,
            child: Text("JumpList"),
          ),
        ]);
  }
}

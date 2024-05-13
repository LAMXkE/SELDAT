import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seldat/LogAnalysis/FileView.dart';
import 'dart:io';

import 'package:seldat/LogAnalysis/LogFetcher.dart';

class Report extends StatefulWidget {
  const Report({
    super.key,
  });

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  LogFetcher logFetcher = LogFetcher();
  late List<File> eventLogList;

  @override
  void initState() {
    super.initState();
    print("Report");
    eventLogList = logFetcher.getEventLogList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                          child: ExpansionTile(
                            title: const Text(".Evtx"),
                            children: [
                              SizedBox(
                                height: 200,
                                child: FileView(
                                  files: eventLogList,
                                ),
                              )
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
}

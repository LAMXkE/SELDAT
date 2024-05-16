import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:seldat/LogAnalysis/FileView.dart';
import 'dart:io';

import 'package:seldat/LogAnalysis/LogFetcher.dart';
import 'package:sqflite/sqflite.dart';

class LogAnalysis extends StatefulWidget {
  final LogFetcher logFetcher;

  const LogAnalysis({
    super.key,
    required this.logFetcher,
  });

  @override
  State<LogAnalysis> createState() => _LogAnalysisState();
}

class _LogAnalysisState extends State<LogAnalysis>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late List<File> eventLogFileList;
  DatabaseManager db = DatabaseManager();
  String selectedFilename = "";

  @override
  void initState() {
    super.initState();
    print("Log Analysis");
    eventLogFileList = widget.logFetcher.getEventLogFileList();
  }

  Future<List<DataRow>> eventlogList = Future(() => List.empty());

  Future<List<DataRow>> getEventLogList() async {
    await db.open();
    List<DataRow> rows = [];
    List<Map<String, Object?>> eventLogList =
        await db.getEventLogList(selectedFilename);

    for (var event in eventLogList) {
      rows.add(DataRow(cells: [
        DataCell(Text(event['riskScore'].toString())),
        DataCell(Text(DateTime.fromMillisecondsSinceEpoch(
                int.parse(event['timestamp'].toString()))
            .toLocal()
            .toString())),
        DataCell(Text(event['event_id'].toString())),
        const DataCell(Text("")),
      ]));
    }
    db.close();
    return rows;
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
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1.0,
                              color: Colors.black54,
                            ),
                          ),
                          child: FileView(
                            files: eventLogFileList,
                            setSelected: (String filename) {
                              setState(() {
                                print("$filename selected");
                                selectedFilename = filename;
                                getEventLogList().then((value) =>
                                    eventlogList = Future.value(value));
                              });
                            },
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
                  width: double.infinity,
                  child: FutureBuilder(
                      future: eventlogList,
                      builder: (context, snapshot) => snapshot.hasData
                          ? SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: _logLists(snapshot.data as List<DataRow>),
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            )),
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

  DataTable _logLists(List<DataRow> snapshot) {
    return DataTable(
      columns: const [
        DataColumn(label: Text("Risk Score")),
        DataColumn(label: Text("Timestamp")),
        DataColumn(label: Text("Event ID")),
        DataColumn(label: Text("context"))
      ],
      rows: snapshot,
    );
  }
}

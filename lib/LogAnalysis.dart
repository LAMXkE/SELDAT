import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:seldat/LogAnalysis/FileView.dart';
import 'dart:io';

import 'package:seldat/LogAnalysis/LogFetcher.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xml/xml.dart';

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
  XmlDocument detail = XmlDocument.parse("<empty/>");

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
      rows.add(DataRow(
        cells: [
          DataCell(Text(event['riskScore'].toString())),
          DataCell(Text(DateTime.fromMillisecondsSinceEpoch(
                  int.parse(event['timestamp'].toString()))
              .toLocal()
              .toString())),
          DataCell(Text(event['event_id'].toString())),
          const DataCell(Text("")),
        ],
        onSelectChanged: (checked) {
          setState(() {
            detail = XmlDocument.parse(event['full_log'].toString());
          });
        },
      ));
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
                                selectedFilename = filename;
                                eventlogList = getEventLogList();
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
                  clipBehavior: Clip.hardEdge,
                  child: FutureBuilder(
                      future: eventlogList,
                      builder: (context, snapshot) =>
                          snapshot.connectionState == ConnectionState.done
                              ? _logLists(snapshot.data as List<DataRow>)
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
            child: _detailUI(),
          ),
        ),
      ],
    );
  }

  SizedBox _logLists(List<DataRow> snapshot) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataTable(
            columns: const [
              DataColumn(label: Text("Risk Score")),
              DataColumn(label: Text("Timestamp")),
              DataColumn(label: Text("Event ID")),
              DataColumn(label: Text("context"))
            ],
            rows: List.empty(),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowHeight: 0,
                columns: const [
                  DataColumn(label: Text("Risk Score"), numeric: true),
                  DataColumn(label: Text("Timestamp")),
                  DataColumn(label: Text("Event ID"), numeric: true),
                  DataColumn(label: Text("context"))
                ],
                rows: snapshot,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _detailUI() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
      ),
      child: Center(
        child: Text(detail.toXmlString()),
      ),
    );
  }
}

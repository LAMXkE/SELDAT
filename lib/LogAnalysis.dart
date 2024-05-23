import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:seldat/LogAnalysis/FileView.dart';
import 'dart:io';

import 'package:seldat/LogAnalysis/LogFetcher.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xml/xml.dart';
import 'LogDetail.dart';

import 'LogAnalysis/GraphView.dart';

class LogAnalysis extends StatefulWidget {
  final LogFetcher logFetcher;

  const LogAnalysis({
    super.key,
    required this.logFetcher,
  });

  @override
  State<LogAnalysis> createState() => _LogAnalysisState();
}

class _LogAnalysisState extends State<LogAnalysis> {
  late List<File> eventLogFileList;
  DatabaseManager db = DatabaseManager();
  String selectedFilename = "";
  int selectedFile = -1;
  XmlDocument detail = XmlDocument.parse("<empty/>");
  int pageSize = 15;
  PaginatedList<eventLog>? logdata;
  @override
  void initState() {
    super.initState();
    print("Log Analysis");
    eventLogFileList = widget.logFetcher.getEventLogFileList();
  }

  //

  @override
  Widget build(BuildContext context) {
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
                            selected: selectedFile,
                            setSelected: (String filename, int index) {
                              setState(() {
                                if (selectedFilename == filename) {
                                  selectedFilename = "";
                                  selectedFile = -1;
                                  _controller.refresh();
                                  return;
                                }
                                selectedFilename = filename;
                                selectedFile = index;
                                _controller.refresh();
                              });
                            },
                          )),
                    ),
                    Flexible(
                      flex: 7,
                      child: GraphView(data: logdata),
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
                  child: _logLists(),
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

  final _controller = PagedDataTableController<String, eventLog>();

  SizedBox _logLists() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PagedDataTableTheme(
              data: PagedDataTableThemeData(
                footerHeight: 40,
                headerHeight: 40,
                rowHeight: 45,
                rowColor: (index) {
                  if (index % 2 == 0) {
                    return Colors.grey[200]!;
                  }
                  return Colors.white;
                },
              ),
              child: PagedDataTable<String, eventLog>(
                controller: _controller,
                initialPageSize: 15,
                pageSizes: const [15, 30, 50, 100],
                configuration: const PagedDataTableConfiguration(),
                fetcher: (pageSize, sortModel, filterModel, pageToken) async {
                  await db.open();
                  String? orderBy;
                  bool descending = false;
                  if (sortModel != null) {
                    orderBy = sortModel.fieldName;
                    descending = sortModel.descending;
                  }
                  int? eventId;
                  if (filterModel["event_id"] != null) {
                    eventId = int.parse(filterModel["event_id"] as String);
                  }
                  final PaginatedList<eventLog> data = await db.getEventLog(
                    filename: selectedFilename,
                    event_id: eventId,
                    content: filterModel["content"] as String?,
                    anomaly: filterModel["anomaly"] as bool?,
                    malicious: filterModel["malicious"] as bool?,
                    orderBy: orderBy,
                    sortDesc: descending,
                    pageSize: pageSize,
                    pageToken: pageToken,
                  );
                  setState(() {
                    logdata = data;
                  });
                  db.close();
                  return (data.items, data.nextPageToken);
                },
                filters: [
                  TextTableFilter(
                      id: "content",
                      chipFormatter: (value) => "Log contains $value",
                      name: "Log"),
                  TextTableFilter(
                      chipFormatter: (value) => "Event ID is $value",
                      id: "event_id",
                      name: "EventID"),
                ],
                fixedColumnCount: 2,
                columns: [
                  TableColumn(
                    title: const Text("Risk Score"),
                    cellBuilder: (context, item, index) {
                      return GestureDetector(
                          onTap: () => setState(() {
                                detail = XmlDocument.parse(item.full_log);
                              }),
                          child: Text(item.riskScore.toString()));
                    },
                    size: const FixedColumnSize(130),
                  ),
                  TableColumn(
                    title: const Text("Filename"),
                    cellBuilder: (context, item, index) => GestureDetector(
                        onTap: () => setState(() {
                              detail = XmlDocument.parse(item.full_log);
                            }),
                        child: Text(item.filename
                            .split("\\")
                            .last
                            .replaceAll("%4", "/"))),
                    size: const FixedColumnSize(300),
                  ),
                  TableColumn(
                    id: "timestamp",
                    title: const Text("Timestamp"),
                    cellBuilder: (context, item, index) => GestureDetector(
                      onTap: () => setState(() {
                        detail = XmlDocument.parse(item.full_log);
                      }),
                      child: Text(item.timestamp.toLocal().toString()),
                    ),
                    size: const FixedColumnSize(300),
                    sortable: true,
                  ),
                  TableColumn(
                    id: "event_id",
                    title: const Text("Event ID"),
                    cellBuilder: (context, item, index) => GestureDetector(
                        onTap: () => setState(() {
                              detail = XmlDocument.parse(item.full_log);
                            }),
                        child: Text(item.event_id.toString())),
                    size: const FixedColumnSize(200),
                    sortable: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _detailUI() {
    //String xmlData = detail.toXmlString();

    return Container(
      // decoration: BoxDecoration(
      //   border: Border.all(color: Colors.black54),
      // ),
      // child: Center(
      //   child: Text(detail.toXmlString()),
      // ),
      child: LogDetailElementsViewer(xmlData: detail),
    );
  }
}

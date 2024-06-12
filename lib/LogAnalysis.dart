import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:seldat/LogAnalysis/FileView.dart';
import 'dart:io';

import 'package:seldat/LogAnalysis/LogFetcher.dart';
import 'package:seldat/RelatedArtifact.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'LogAnalysis/LogDetail.dart';

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

class _LogAnalysisState extends State<LogAnalysis>
    with AutomaticKeepAliveClientMixin<LogAnalysis> {
  late List<File> eventLogFileList;
  late DatabaseManager db;
  String selectedFilename = "";
  int selectedFile = -1;
  XmlDocument detail = XmlDocument.parse("<empty/>");
  int pageSize = 15;
  List<int> maliciousList = [];
  List<int> maliciousLevel = [];
  PaginatedList<eventLog>? logdata;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    db = widget.logFetcher.db;
    super.initState();
    print("Log Analysis");
    eventLogFileList = widget.logFetcher.getEventLogFileList();
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
                  if (maliciousList.contains(index)) {
                    if (maliciousLevel[maliciousList.indexOf(index)] == 0) {
                      return Colors.orange[300]!.withOpacity(0.5);
                    }
                    if (maliciousLevel[maliciousList.indexOf(index)] == 1) {
                      return Colors.red[100]!.withOpacity(0.5);
                    }
                    if (maliciousLevel[maliciousList.indexOf(index)] == 2) {
                      return Colors.red[300]!.withOpacity(0.5);
                    }
                    if (maliciousLevel[maliciousList.indexOf(index)] == 3) {
                      return Colors.red[500]!.withOpacity(0.5);
                    }
                    if (maliciousLevel[maliciousList.indexOf(index)] == 4) {
                      return Colors.red[800]!.withOpacity(0.5);
                    }
                  }
                  return Colors.white;
                },
              ),
              child: PagedDataTable<String, eventLog>(
                controller: _controller,
                initialPageSize: 100,
                pageSizes: const [30, 50, 100],
                configuration: const PagedDataTableConfiguration(),
                fetcher: (pageSize, sortModel, filterModel, pageToken) async {
                  print(filterModel);
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
                  bool? anomaly;
                  if (filterModel["malicious"] == "Anomaly") {
                    anomaly = true;
                  } else if (filterModel["malicious"] == "Normal") {
                    anomaly = false;
                  } else {
                    anomaly = null;
                  }
                  final PaginatedList<eventLog> data = await db.getEventLog(
                    filename: selectedFilename,
                    event_id: eventId,
                    content: filterModel["content"] as String?,
                    malicious: anomaly,
                    timestamp: filterModel["timestamp"] as DateTimeRange?,
                    orderBy: orderBy,
                    sortDesc: descending,
                    pageSize: pageSize,
                    pageToken: pageToken,
                  );
                  int idx = 0;
                  maliciousList.clear();
                  maliciousLevel.clear();
                  for (var element in data.items) {
                    if (element.isMalicious || element.sigmaLevel > 0) {
                      maliciousList.add(idx);
                      if (element.sigmaLevel > 0) {
                        maliciousLevel.add(element.sigmaLevel);
                      } else {
                        maliciousLevel.add(0);
                      }
                    }
                    idx++;
                  }
                  setState(() {
                    logdata = data;
                  });
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
                  DropdownTableFilter(
                    initialValue: const Text("Anomaly"),
                    items: [
                      const DropdownMenuItem(
                        value: "All",
                        child: Text("All"),
                      ),
                      const DropdownMenuItem(
                        value: "Anomaly",
                        child: Text("Anomaly"),
                      ),
                      const DropdownMenuItem(
                        value: "Normal",
                        child: Text("Normal"),
                      ),
                    ],
                    chipFormatter: (value) => "$value",
                    id: "malicious",
                    name: "Log Type",
                  ),
                  DateRangePickerTableFilter(
                    id: "timestamp",
                    name: "Timestamp",
                    initialDatePickerMode: DatePickerMode.year,
                    initialEntryMode: DatePickerEntryMode.input,
                    enabled: true,
                    firstDate: DateTime(2021, 1, 1),
                    lastDate: DateTime.now(),
                    initialValue: DateTimeRange(
                        start: DateTime(2021, 1, 1), end: DateTime.now()),
                    formatter: (p0) => p0.toString(),
                    chipFormatter: (value) =>
                        "Timestamp between ${value.start} and ${value.end}",
                  ),
                ],
                fixedColumnCount: 2,
                columns: [
                  TableColumn(
                      id: 'event_record_id',
                      title: const Text("Event Record ID"),
                      cellBuilder: (context, item, index) => GestureDetector(
                          onTap: () => setState(() {
                                detail = XmlDocument.parse(item.full_log);
                              }),
                          child: Text(item.event_record_id.toString())),
                      size: const FixedColumnSize(200),
                      sortable: true),
                  TableColumn(
                    id: "event_id",
                    title: const Text("Event ID"),
                    cellBuilder: (context, item, index) => GestureDetector(
                        onTap: () => setState(() {
                              detail = XmlDocument.parse(item.full_log);
                            }),
                        child: Text(item.event_id.toString())),
                    size: const FixedColumnSize(180),
                    sortable: true,
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
                    title: const Text("SystemTime"),
                    cellBuilder: (context, item, index) => GestureDetector(
                      onTap: () => setState(() {
                        detail = XmlDocument.parse(item.full_log);
                      }),
                      child: Text(item.timestamp.toLocal().toString()),
                    ),
                    size: const FixedColumnSize(250),
                    sortable: true,
                  ),
                  TableColumn(
                    id: "tag",
                    title: const Text("TAG"),
                    cellBuilder: (context, item, index) => GestureDetector(
                      onTap: () => setState(() {
                        detail = XmlDocument.parse(item.full_log);
                      }),
                      child: Row(children: [
                        if (item.isMalicious) const Chip(label: Text("AI")),
                        if (item.sigmaLevel > 0)
                          const Chip(label: Text("Sigma"))
                      ]),
                    ),
                    size: const FixedColumnSize(300),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailUI() {
    if (detail.toString() == "<empty/>") {
      return const Center(child: Text("Select a log to view details"));
    }
    String? timeString =
        detail.xpath("Event/System/TimeCreated/@SystemTime").first.value;
    if (timeString == null) {
      return const Center(child: Text("No time information found"));
    }
    DateTime date = DateTime.parse(timeString);
    return Flex(
      direction: Axis.vertical,
      children: [
        ExpansionTile(title: const Text("Related Artifacts"), children: [
          RelatedArtifactWidget(
              databaseManager: widget.logFetcher.db,
              date: date,
              exclude: "evtx")
        ]),
        Flexible(child: LogDetailElementsViewer(xmlData: detail)),
      ],
    );
  }
}

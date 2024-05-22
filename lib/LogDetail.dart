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

class LogDetailElementsViewer extends StatefulWidget {
  late XmlDocument xmlData;
  LogDetailElementsViewer({super.key, required this.xmlData});

  @override
  _LogDetailElementsViewerState createState() =>
      _LogDetailElementsViewerState();
}

class _LogDetailElementsViewerState extends State<LogDetailElementsViewer> {
  List<Map<String, dynamic>> createParsedXMLData(XmlDocument Data) {
    var eventLog = Data.findAllElements('Event');

    List<Map<String, dynamic>> parsedDataList = [];

    for (var event in eventLog) {
      for (var child in event.children) {
        if (child is XmlElement) {
          Map<String, dynamic> header = {};
          header['Header'] = child.name.local;
          header['Content'] = [];

          for (var tag in child.children) {
            if (tag is XmlElement) {
              Map<String, dynamic> content = {};
              content['Tag'] = tag.name.local;
              content['Content'] = [];
              if (tag.attributes.isNotEmpty) {
                for (XmlAttribute attribute in tag.attributes) {
                  content['Content']
                      .add([attribute.name.toString(), attribute.value]);
                }
              }
              if (tag.innerText != "") {
                content['Content'].add(['Value', tag.innerText]);
              }
              header['Content'].add(content);
            }
          }
          parsedDataList.add(header);
        }
      }
    }
    //print(parsedDataList);
    return parsedDataList;
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }

  @override
  void didUpdateWidget(LogDetailElementsViewer oldWidget) {
    // 로그가 바뀔 때마다 디테일 화면 맨 위로 이동
    super.didUpdateWidget(oldWidget);
    if (widget.xmlData != oldWidget.xmlData) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    var data = createParsedXMLData(widget.xmlData);
    return ListView(
      controller: _scrollController,
      children: data.map(_buildTiles).toList(),
    );
  }

  Widget _buildTiles(Map<String, dynamic> header) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: Text(
        header['Header'],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: (header['Content'] as List)
          .cast<Map<String, dynamic>>()
          .map<Widget>(_buildContent)
          .toList(),
    );
  }

  Widget _buildContent(Map<String, dynamic> content) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "${content['Tag']}",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      children: (content['Content'] as List)
          .cast<List<dynamic>>()
          .map<Widget>((item) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.only(left: 35.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${item[0]} :  ${item[1]}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:seldat/SystemInfo/SystemInfoFetcher.dart';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class SystemInfoViewer extends StatefulWidget {
  final Map<String, String> data;
  const SystemInfoViewer({super.key, required this.data});

  @override
  _SystemInfoViewerState createState() => _SystemInfoViewerState();
}

class _SystemInfoViewerState extends State<SystemInfoViewer> {
  // Map<String, String> data = {'Loading...': ''};
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ParsedDataListView(parsedData: widget.data);
  }
}

class ParsedDataListView extends StatefulWidget {
  final Map<String, String> parsedData;

  const ParsedDataListView({super.key, required this.parsedData});

  @override
  _ParsedDataListViewState createState() => _ParsedDataListViewState();
}

class _ParsedDataListViewState extends State<ParsedDataListView> {
  String? selectedKey;
  int? selectedIndex;
  bool isHovering = false;
  void setSelected(String key, int index) {
    setState(() {
      selectedKey = key;
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 248, 248, 248),
          borderRadius: BorderRadius.circular(5.0),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(255, 185, 185, 185),
              blurRadius: 5.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: ListView.builder(
          itemCount: widget.parsedData.length,
          itemBuilder: (context, index) {
            var key = widget.parsedData.keys.elementAt(index);
            var value = widget.parsedData[key]!;
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: IntrinsicHeight(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12.0, 5.0, 5.0, 5.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lens,
                                  size: 6.0,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  key,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: SelectableText(
                          value,
                          style: const TextStyle(
                            fontSize: 15.0,
                            height: 2.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

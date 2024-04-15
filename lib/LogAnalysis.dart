import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seldat/LogAnalysis/FileView.dart';
import 'dart:io';

class LogAnalysis extends StatelessWidget {
  final List<File> fileList;

  LogAnalysis({
    super.key,
    required this.fileList,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
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
                              files: fileList,
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
      ),
    );
  }
}

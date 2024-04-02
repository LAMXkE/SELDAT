import 'package:flutter/material.dart';
import 'package:seldat/LogAnalysis/FileView.dart';
import 'dart:io';

class LogAnalysis extends StatelessWidget {
  List<File> filelist = List.filled(1, File("/Security.evtx"));

  LogAnalysis({super.key});

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
                            decoration: const BoxDecoration(
                              border: Border(width: 1.0, color: Colors.black54),
                            ),
                            child: FileView(files: filelist)),
                      ),
                      const Flexible(
                          flex: 7,
                          child: Center(child: Text("Graph Placeholder")))
                    ],
                  ),
                ),
                Flexible(
                    flex: 4,
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54)),
                        child: const Center(child: Text("log timeline placeholder"))))
              ],
            ),
          ),
          Flexible(
            flex: 3,
            child: Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.black54)),
                child: const Center(child: Text("Detail Placeholder"))),
          )
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/src/utf16.dart';
import 'package:flutter/services.dart';
import 'package:koala/koala.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:win32/win32.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

class LogFetcher {
  // Properties
  List<File> eventLogFileList = List.empty(growable: true);
  Function addCount = () {};
  bool isFetched = false;

  // Constructor
  LogFetcher() {
    // Constructor code...
    if (!Directory(".\\Artifacts").existsSync()) {
      Directory(".\\Artifacts").create();
    }
    if (!Directory(".\\Artifacts\\EventLogs").existsSync()) {
      Directory(".\\Artifacts\\EventLogs").create();
    }
  }

  Future<bool> loadDB() async {
    DatabaseManager db = DatabaseManager();
    await db.open();
    List<Map<String, Object?>> evtxFileList = await db.getEvtxFileList();
    if (evtxFileList.isNotEmpty) {
      for (var file in evtxFileList) {
        print(file);
        eventLogFileList.add(File(file['filename'].toString()));
        addCount(int.parse(file['logCount'].toString()));
      }
      db.close();
      return true;
    }
    db.close();
    return false;
  }

  void setAddCount(Function addCount) {
    this.addCount = addCount;
  }

  bool getIsFetched() {
    return isFetched;
  }

  // Methods
  void scanFiles(Directory dir) async {
    await scan(dir);
    DatabaseManager db = DatabaseManager();
    await db.open();
    for (var file in eventLogFileList) {
      await parseEventLog(file, db);
    }
    db.close();
  }

  Future scan(Directory dir) async {
    try {
      var dirList = dir.list();
      await for (final FileSystemEntity entity in dirList) {
        if (entity is File) {
          if (entity.path.endsWith(".evtx")) {
            // eventLogFileList.add(entity);
            try {
              entity.copy(
                  "Artifacts\\EventLogs\\${entity.path.split('\\').last}");
              eventLogFileList.add(File(
                  "Artifacts\\EventLogs\\${entity.path.split('\\').last}"));
            } on PathExistsException catch (_, e) {}
          }
        } else if (entity is Directory) {
          scan(Directory(entity.path));
        }
      }
    } on PathAccessException {
      return;
    }
  }

  // DataFrame createDataFrame(List<Map<String, Object?>> eventLogs) {
  //   DataFrame df = DataFrame.empty();
  //   List<String> eventId = List.empty(growable: true);
  //   List<DateTime> timestamp = List.empty(growable: true);
  //   for (var logObj in eventLogs) {
  //     XmlDocument log =  XmlDocument.parse(logObj['full_log'].toString());

  //     if(log.xpath("Event/System/EventID").isEmpty){
  //         eventId.add("N/A");
  //     }else{
  //       eventId.add(log.xpath("Event/System/EventID").first.innerText);
  //     }

  //     if(log.xpath("Event/System/TimeCreated").isEmpty){
  //         timestamp.add(DateTime.fromMillisecondsSinceEpoch(0)); //TODO: Change to 0 when the time is not available in the log (e.g. Security log does not have time in the log file)
  //     }
  //     else{
  //       timestamp.add(
  //         DateTime.fromMillisecondsSinceEpoch(
  //           int.parse( log.xpath("Event/System/TimeCreated").first.getAttribute("SystemTime").toString())
  //           )
  //       );
  //     }

  //   }

  //   df.addColumn("EventID", eventId);
  //   df.addColumn("Timestamp", timestamp);

  //   // group list with seconds

  //   return df;
  // }

  Future parseEventLog(File file, DatabaseManager db) async {
    await runevtxdump(file.path).then((value) async {
      List<String> eventList = value.split(RegExp(r"Record [0-9]*"));
      for (String event in eventList) {
        XmlDocument record;
        try {
          record = XmlDocument.parse(event);
        } catch (e) {
          continue;
        }
        if (record.findAllElements("EventID").isEmpty) {
          continue;
        }
        String eventId = record.xpath("/Event/System/EventID").first.innerText;
        String? timeCreated = record
            .xpath("/Event/System/TimeCreated")
            .first
            .getAttribute("SystemTime");
        if (timeCreated == null) {
          continue;
        }

        eventLog log = eventLog(
            event_id: int.parse(eventId),
            filename: file.path,
            full_log: event,
            isAnalyzed: false,
            riskScore: 0.0,
            timestamp: DateTime.parse(timeCreated));
        //write to sqlite database
        await db.insertEventLog(log);
        addCount(1);
      }
      db.insertEvtxFiles(evtxFiles(
          filename: file.path, logCount: value.length, isFetched: true));
    });
  }

  Future<void> runAIModelPredict() async {
    Interpreter interpreter =
        await Interpreter.fromAsset('blobs/autoencoder_model.tflite');

    interpreter.getInputTensors();
    List<Tensor> input = List.empty(growable: true);

    interpreter.allocateTensors();
    DatabaseManager db = DatabaseManager();
    await db.open();

    List<Map<String, Object?>> eventLogs = await db.getEventLogWithExplorer();
    List<String> output = List.empty(growable: true);
    for (var log in eventLogs) {}

    interpreter.run(input, output);

    db.close();
  }

  List<File> getEventLogFileList() {
    return eventLogFileList;
  }

  Future<String> runevtxdump(String path) async {
    var process =
        await Process.run('evtxdump.exe', [path], stdoutEncoding: utf8);

    return process.stdout;
  }
}
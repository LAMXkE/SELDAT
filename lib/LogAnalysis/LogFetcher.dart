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
  final DatabaseManager db;

  // Constructor
  LogFetcher(this.db) {
    // Constructor code...
    if (!Directory(".\\Artifacts").existsSync()) {
      Directory(".\\Artifacts").create();
    }
    if (!Directory(".\\Artifacts\\EventLogs").existsSync()) {
      Directory(".\\Artifacts\\EventLogs").create();
    }
    if (!Directory(".\\Artifacts\\EvtxCsv").existsSync()) {
      Directory(".\\Artifacts\\EvtxCsv").create();
    }
  }

  Future<bool> loadDB() async {
    List<Map<String, Object?>> evtxFileList = await db.getEvtxFileList();
    if (evtxFileList.isNotEmpty) {
      for (var file in evtxFileList) {
        eventLogFileList.add(File(file['filename'].toString()));
        addCount(int.parse(file['logCount'].toString()));
      }
      await db
          .getEventLog(filename: "", pageSize: 15, pageToken: "0")
          .then((value) {
        if (value.items.isNotEmpty) {
          isFetched = true;
          return true;
        }
      });
    }
    return false;
  }

  void setAddCount(Function addCount) {
    this.addCount = addCount;
  }

  bool getIsFetched() {
    return isFetched;
  }

  // Methods
  Future<void> scanFiles(Directory dir) async {
    await scan(dir);
    for (var file in eventLogFileList) {
      await parseEventLog(file, db);
    }
    await runAIModelPredict();
    isFetched = true;
  }

  Future scan(Directory dir) async {
    Directory("Artifacts\\EventLogs").listSync().forEach((entity) {
      if (entity is File && entity.path.endsWith('.evtx')) {
        entity.delete();
      }
    });
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

  Future parseEventLog(File file, DatabaseManager db) async {
    await runevtxdump(file.path).then((value) async {
      List<eventLog> eventLogs = [];
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
        int eventRecordId = int.parse(
            record.xpath("/Event/System/EventRecordID").first.innerText);

        eventLog log = eventLog(
            event_id: int.parse(eventId),
            filename: file.path,
            event_record_id: eventRecordId,
            full_log: event,
            isMalicious: false,
            timestamp: DateTime.parse(timeCreated));
        eventLogs.add(log);
        //write to sqlite database
        addCount(1);
      }
      await db.insertEventLogs(eventLogs);
      await db.insertEvtxFiles(evtxFiles(
          filename: file.path, logCount: eventList.length, isFetched: true));
    });
  }

  Future<void> runAIModelPredict() async {
    Directory(".\\Artifacts\\EvtxCsv").listSync().forEach((entity) {
      if (entity is File && entity.path.endsWith('.csv')) {
        entity.delete();
      }
    });
    print("Running AI Model");
    Process.run("./tools/runModel.exe", [],
            workingDirectory: "${Directory.current.path}/tools")
        .then((ProcessResult process) {
      bool isResult = false;
      process.stdout.toString().split("\n").forEach((element) {
        if (isResult) {
          if (element.length < 19) return;
          String timeGroup = element.substring(0, 11);
          bool isMalicious = element.contains("True");
          if (int.tryParse(timeGroup) == null) {
            print("Error: $element");
            return;
          }

          if (isMalicious) {
            print("Malicious Event: $element");
            db.updateMaliciousEvtx(int.parse(timeGroup) * 1000);
          }
        }
        if (element.contains("[*] Printing results")) {
          isResult = true;
        }
      });
      print("AI Model Finished");
    });
    // eventLog(event_id: 0, filename: "", full_log: "", isAnalyzed: false, riskScore: 0.0, timestamp: DateTime.now());
  }

  List<File> getEventLogFileList() {
    return eventLogFileList;
  }

  Future<String> runevtxdump(String path) async {
    var process =
        await Process.run('./tools/evtxdump.exe', [path], stdoutEncoding: utf8);

    return process.stdout;
  }
}

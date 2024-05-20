import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  // TODO: Implement your database procedures here
  // This class is responsible for managing the database
  // connection and operations.
  // You can use the SQLite package to interact with the database.
  // For more information, see: https://pub.dev/packages/sqflite

  // Properties
  Database? database;

  // Constructor
  DatabaseManager();

  Future<void> insertEventLog(eventLog event) async {
    await database!.insert('evtx', event.toMap());
  }

  Future<void> insertEvtxFiles(evtxFiles evtxFile) async {
    await database!.insert('evtxFiles', evtxFile.toMap());
  }

  Future<List<Map<String, Object?>>> getEvtxFileList() {
    return database!.query('evtxFiles');
  }

  Future<List<Map<String, Object?>>> getEventLogList(String filename) {
    if (filename == "") {
      return database!.query('evtx');
    }

    return database!
        .query('evtx', where: 'filename = ?', whereArgs: [filename]);
  }

  Future<PaginatedList<eventLog>> getEventLog({
    required String filename,
    required int pageSize,
    required String? pageToken,
    int? event_id,
    bool? anomaly,
    bool? malicious,
    String? content,
    String? orderBy,
    bool sortDesc = false,
  }) async {
    print("pageToken $pageToken");
    List<Map<String, Object?>> eventLogs =
        List.from(await getEventLogList(filename));

    print("$event_id, $anomaly, $malicious, $content, $orderBy, $sortDesc");

    if (orderBy == null) {
      print("[*] orderby is null Sorting by timestamp");
      eventLogs.sort(
          (b, a) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
    } else if (orderBy == "riskScore") {
      eventLogs.sort((b, a) => sortDesc
          ? (a['riskScore'] as double).compareTo(b['riskScore'] as double)
          : (b['riskScore'] as double).compareTo(a['riskScore'] as double));
    } else if (orderBy == "timestamp") {
      print("[*] Sorting by timestamp $sortDesc");
      eventLogs.sort((b, a) => sortDesc
          ? (a['timestamp'] as int).compareTo(b['timestamp'] as int)
          : (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    } else if (orderBy == "event_id") {
      eventLogs.sort((b, a) => sortDesc
          ? (a['event_id'] as int).compareTo(b['event_id'] as int)
          : (b['event_id'] as int).compareTo(a['event_id'] as int));
    }

    int nextId = pageToken == null ? 0 : int.tryParse(pageToken) ?? 1;
    int nextIndex =
        eventLogs.indexWhere((element) => element['id'] as int == nextId);
    if (nextIndex == -1) {
      nextIndex = 0;
    }
    eventLogs = eventLogs.sublist(nextIndex);

    if (anomaly != null) {
      eventLogs = eventLogs
          .where((element) => element['riskScore'] as int > 0.5)
          .toList();
    }

    if (content != null) {
      eventLogs = eventLogs
          .where((element) => element['full_log'].toString().contains(content))
          .toList();
    }

    if (malicious != null) {
      eventLogs = eventLogs
          .where((element) => element['riskScore'] as int > 0.8)
          .toList();
    }

    if (event_id != null) {
      eventLogs = eventLogs
          .where((element) => element['event_id'] as int == event_id)
          .toList();
    }

    List<eventLog> logs = eventLogs
        .map((e) => eventLog(
              id: e['id'] as int,
              timestamp:
                  DateTime.fromMillisecondsSinceEpoch(e['timestamp'] as int),
              filename: e['filename'] as String,
              full_log: e['full_log'] as String,
              isAnalyzed: e['isAnalyzed'] as int == 1 ? true : false,
              riskScore: e['riskScore'] as double,
              event_id: e['event_id'] as int,
            ))
        .take(pageSize + 1)
        .toList();

    String? nextPageToken;
    if (logs.length == pageSize + 1) {
      eventLog last = logs.removeLast();
      nextPageToken = last.id.toString();
    }

    return PaginatedList(items: logs, nextPageToken: nextPageToken);
  }

  Future<void> insertRegistry(registry reg) async {
    await database?.insert('registry', reg.toMap());
  }

  Future<void> insertSRUM(SRUM srum) async {
    await database?.insert('SRUM', srum.toMap());
  }

  Future<void> insertPrefetch(prefetch pref) async {
    await database?.insert('prefetch', pref.toMap());
  }

  Future<void> insertJumplist(jumplist jump) async {
    await database?.insert('jumplist', jump.toMap());
  }

  void close() {
    database?.close();
    print("[*] Database closed");
  }

  // Methods
  Future open() async {
    print("[*] Opening database...");
    database = await openDatabase(
      join(Directory.current.path, 'database.db'),
      version: 1,
      onCreate: (Database db, int version) async {
        return db.execute('''
                          CREATE TABLE evtxFiles(
                            id INTEGER PRIMARY KEY,
                            filename TEXT,
                            logCount INTEGER,
                            isFetched BOOLEAN
                          );

                          CREATE TABLE evtx(
                            id INTEGER NOT NULL,
                            timestamp DATETIME,
                            filename VARCHAR,
                            full_log TEXT,
                            "isAnalyzed" BOOLEAN,
                            "riskScore" DOUBLE,
                            event_id INTEGER NOT NULL,
                            PRIMARY KEY(id)
                          );

                          CREATE TABLE registry(
                            id INTEGER NOT NULL,
                            directory VARCHAR NOT NULL,
                            "key" VARCHAR NOT NULL,
                            value VARCHAR NOT NULL,
                            type INTEGER NOT NULL,
                            PRIMARY KEY(id)
                          );

                          CREATE TABLE "SRUM"(
                            id INTEGER NOT NULL,
                            entry_num INTEGER NOT NULL,
                            entry_creation DATETIME NOT NULL,
                            application VARCHAR NOT NULL,
                            user_sid VARCHAR NOT NULL,
                            "Interface" VARCHAR NOT NULL,
                            "Profile" INTEGER NOT NULL,
                            PRIMARY KEY(id)
                          );

                          CREATE TABLE prefetch(
                            id INTEGER NOT NULL,
                            filename VARCHAR NOT NULL,
                            "createTime" DATETIME,
                            "modifiedTime" DATETIME,
                            "fileSize" INT,
                            process_exe VARCHAR,
                            process_path VARCHAR,
                            run_counter INTEGER,
                            "lastRunTime" DATETIME,
                            "missingProcess" BOOLEAN,
                            PRIMARY KEY(id)
                          );

                          CREATE TABLE jumplist(
                            id INTEGER NOT NULL,
                            filename VARCHAR,
                            "fullPath" VARCHAR,
                            "recordTime" DATETIME,
                            "createTime" DATETIME,
                            "modifiedTime" DATETIME,
                            "accessTime" DATETIME,
                            "hostName" VARCHAR,
                            "fileSize" INTEGER,
                            PRIMARY KEY(id)
                          );
                          ''');
      },
    );
  }
}

class PaginatedList<T> {
  final Iterable<T> _items;
  final String? _nextPageToken;

  List<T> get items => UnmodifiableListView(_items);
  String? get nextPageToken => _nextPageToken;

  PaginatedList({
    required Iterable<T> items,
    String? nextPageToken,
  })  : _items = items,
        _nextPageToken = nextPageToken;
}

class evtxFiles {
  final String filename;
  final int logCount;
  final bool isFetched;

  const evtxFiles({
    required this.filename,
    required this.logCount,
    required this.isFetched,
  });

  Map<String, Object?> toMap() {
    return {
      'filename': filename,
      'logCount': logCount,
      'isFetched': isFetched ? 1 : 0,
    };
  }
}

class eventLog {
  final int? id;
  final DateTime timestamp;
  final String filename;
  final String full_log;
  final bool isAnalyzed;
  final double riskScore;
  final int event_id;

  const eventLog({
    this.id,
    required this.timestamp,
    required this.filename,
    required this.full_log,
    required this.isAnalyzed,
    required this.riskScore,
    required this.event_id,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'filename': filename,
      'full_log': full_log,
      'isAnalyzed': isAnalyzed ? 1 : 0,
      'riskScore': riskScore,
      'event_id': event_id,
    };
  }
}

class registry {
  final String directory;
  final String key;
  final String value;
  final int type;

  const registry({
    required this.directory,
    required this.key,
    required this.value,
    required this.type,
  });

  Map<String, Object?> toMap() {
    return {
      'directory': directory,
      'key': key,
      'value': value,
      'type': type,
    };
  }
}

class SRUM {
  final int entry_num;
  final DateTime entry_creation;
  final String application;
  final String user_sid;
  final String Interface;
  final int Profile;

  const SRUM({
    required this.entry_num,
    required this.entry_creation,
    required this.application,
    required this.user_sid,
    required this.Interface,
    required this.Profile,
  });

  Map<String, Object?> toMap() {
    return {
      'entry_num': entry_num,
      'entry_creation': entry_creation,
      'application': application,
      'user_sid': user_sid,
      'Interface': Interface,
      'Profile': Profile,
    };
  }
}

class prefetch {
  final String filename;
  final DateTime createTime;
  final DateTime modifiedTime;
  final int fileSize;
  final String process_exe;
  final String process_path;
  final int run_counter;
  final DateTime lastRunTime;
  final bool missingProcess;

  const prefetch({
    required this.filename,
    required this.createTime,
    required this.modifiedTime,
    required this.fileSize,
    required this.process_exe,
    required this.process_path,
    required this.run_counter,
    required this.lastRunTime,
    required this.missingProcess,
  });

  Map<String, Object?> toMap() {
    return {
      'filename': filename,
      'createTime': createTime,
      'modifiedTime': modifiedTime,
      'fileSize': fileSize,
      'process_exe': process_exe,
      'process_path': process_path,
      'run_counter': run_counter,
      'lastRunTime': lastRunTime,
      'missingProcess': missingProcess,
    };
  }
}

class jumplist {
  final String filename;
  final String fullPath;
  final DateTime recordTime;
  final DateTime createTime;
  final DateTime modifiedTime;
  final DateTime accessTime;
  final String hostName;
  final int fileSize;

  const jumplist({
    required this.filename,
    required this.fullPath,
    required this.recordTime,
    required this.createTime,
    required this.modifiedTime,
    required this.accessTime,
    required this.hostName,
    required this.fileSize,
  });

  Map<String, Object?> toMap() {
    return {
      'filename': filename,
      'fullPath': fullPath,
      'recordTime': recordTime,
      'createTime': createTime,
      'modifiedTime': modifiedTime,
      'accessTime': accessTime,
      'hostName': hostName,
      'fileSize': fileSize,
    };
  }
}

import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:seldat/srum/SrumFetcher.dart';
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
    if (database == null) {
      await open();
    }
    await database!.insert('evtx', event.toMap());
  }

  Future<void> insertEventLogs(List<eventLog> events) async {
    if (database == null) {
      await open();
    }
    Batch batch = database!.batch();
    for (var event in events) {
      batch.insert('evtx', event.toMap());
    }
    await batch.commit(noResult: true, continueOnError: true);
  }

  Future<void> insertEvtxFiles(evtxFiles evtxFile) async {
    if (database == null) {
      await open();
    }
    await database!.insert('evtxFiles', evtxFile.toMap());
  }

  Future<List<Map<String, Object?>>> getEvtxFileList() async {
    if (database == null) {
      await open();
    }
    return database!.query('evtxFiles');
  }

  Future<List<Map<String, Object?>>> getEventLogList(String filename) async {
    if (database == null) {
      await open();
    }
    if (filename == "") {
      return database!.query('evtx');
    }

    return database!
        .query('evtx', where: 'filename = ?', whereArgs: [filename]);
  }

  Future<void> updateMaliciousEvtx(int timestamp) async {
    if (database == null) {
      await open();
    }
    await database!.update('evtx', {'isMalicious': 1},
        where: 'timestamp >= ? AND timestamp < ?',
        whereArgs: [timestamp, timestamp + 60 * 1000]);
  }

  Future<void> updateEventLog(eventLog event) async {
    if (database == null) {
      await open();
    }
    await database!
        .update('evtx', event.toMap(), where: 'id = ?', whereArgs: [event.id]);
  }

  List<Map<String, Object?>> EventLogCache = [];

  Future<PaginatedList<eventLog>> getEventLog({
    required String filename,
    required int pageSize,
    required String? pageToken,
    int? event_id,
    bool? anomaly,
    bool? malicious,
    String? content,
    String? orderBy,
    DateTimeRange? timestamp,
    bool sortDesc = false,
  }) async {
    print("pageToken $pageToken");
    if (EventLogCache.isEmpty) {
      EventLogCache = await getEventLogList(filename);
    }

    List<Map<String, Object?>> eventLogs = filename == ""
        ? EventLogCache.toList()
        : List.from(
            EventLogCache.where((element) => element['filename'] == filename));

    print("$event_id, $anomaly, $malicious, $content, $orderBy, $sortDesc");

    if (orderBy == null) {
      print("[*] orderby is null Sorting by timestamp");
      eventLogs.sort(
          (b, a) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
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

    if (timestamp != null) {
      int from = timestamp.start.millisecondsSinceEpoch;
      int to = timestamp.end.millisecondsSinceEpoch;
      eventLogs = eventLogs
          .where((element) =>
              element['timestamp'] as int >= from &&
              element['timestamp'] as int <= to)
          .toList();
    }

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
          .where((element) => element['isMalicious'] as int == 1)
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
              event_record_id: e['event_record_id'] as int,
              timestamp:
                  DateTime.fromMillisecondsSinceEpoch(e['timestamp'] as int),
              filename: e['filename'] as String,
              full_log: e['full_log'] as String,
              isAnalyzed: e['isAnalyzed'] as int == 1 ? true : false,
              isMalicious: e['isMalicious'] as int == 1 ? true : false,
              event_id: int.parse(e['event_id'].toString()),
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

  Future<void> insertRegistry(REGISTRY reg) async {
    if (database == null) {
      await open();
    }
    await database?.insert('registry', reg.toMap());
  }

  Future<void> insertRegistryList(List<REGISTRY> reg) async {
    if (database == null) {
      await open();
    }

    Batch bat = database!.batch();
    for (var r in reg) {
      bat.insert('registry', r.toMap());
    }
    await bat.commit(noResult: true, continueOnError: true);
  }

  Future<List<REGISTRY>> getRegistryList() async {
    if (database == null) {
      await open();
    }
    List<Map<String, Object?>> registryList = await database!.query('registry');
    return registryList
        .map((e) => REGISTRY(
              directory: e['directory'] as String,
              key: e['key'] as String,
              value: e['value'] as String,
              type: e['type'] as String,
            ))
        .toList();
  }

  Future<void> insertSRUM(List<SRUM> srums) async {
    if (database == null) {
      await open();
    }
    Batch bat = database!.batch();
    for (var srum in srums) {
      bat.insert('SRUM', srum.toMap());
    }
    await bat.commit(noResult: true, continueOnError: true);
  }

  Future<List<SRUM>> getSRUMList() async {
    if (database == null) {
      await open();
    }
    List<Map<String, Object?>> srumList = await database!.query('SRUM');
    return srumList
        .map((e) => SRUM(
              id: e['id'] as int,
              type: SRUMType.values[e['type'] as int],
              timestamp:
                  DateTime.fromMillisecondsSinceEpoch(e['timestamp'] as int),
              exeinfo: e['exeinfo'] as String,
              ExeInfoDescription: e['ExeInfoDescription'] as String,
              exeTimeStamp: e['exeTimeStamp'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      e['exeTimeStamp'] as int),
              SidType: e['SidType'] as String,
              Sid: e['Sid'] as String,
              Username: e['Username'] as String,
              user_sid: e['user_sid'] as String,
              AppId: e['AppId'] as int,
              full: e['full'] as String,
            ))
        .toList();
  }

  Future<void> insertPrefetch(prefetch pref) async {
    if (database == null) {
      await open();
    }
    await database?.insert('prefetch', pref.toMap());
  }

  Future<List<prefetch>> getPrefetchList() async {
    if (database == null) {
      await open();
    }
    List<Map<String, Object?>> prefetchList = await database!.query('prefetch');
    return prefetchList
        .map((e) => prefetch(
              filename: e['filename'] as String,
              createTime: DateTime.parse(e['createTime'] as String),
              modifiedTime: DateTime.parse(e['modifiedTime'] as String),
              fileSize: e['fileSize'] as int,
              process_exe: e['process_exe'] as String,
              process_path: e['process_path'] as String,
              run_counter: e['run_counter'] as int,
              lastRunTime0: DateTime.tryParse(['lastRunTime0'] as String),
              lastRunTime1: DateTime.tryParse(e['lastRunTime1'] as String),
              lastRunTime2: DateTime.tryParse(e['lastRunTime2'] as String),
              lastRunTime3: DateTime.tryParse(e['lastRunTime3'] as String),
              lastRunTime4: DateTime.tryParse(e['lastRunTime4'] as String),
              lastRunTime5: DateTime.tryParse(e['lastRunTime5'] as String),
              lastRunTime6: DateTime.tryParse(e['lastRunTime6'] as String),
              lastRunTime7: DateTime.tryParse(e['lastRunTime7'] as String),
              missingProcess: e['missingProcess'] as int == 1 ? true : false,
            ))
        .toList();
  }

  Future<void> insertJumplist(jumplist jump) async {
    if (database == null) {
      await open();
    }
    await database?.insert('jumplist', jump.toMap());
  }

  Future<List<jumplist>> getJumplistList() async {
    if (database == null) {
      await open();
    }
    List<Map<String, Object?>> jumplistList = await database!.query('jumplist');
    return jumplistList
        .map((e) => jumplist(
              filename: e['filename'] as String,
              fullPath: e['fullPath'] as String,
              recordTime: DateTime.parse(e['recordTime'] as String),
              createTime: DateTime.parse(e['createTime'] as String),
              modifiedTime: DateTime.parse(e['modifiedTime'] as String),
              accessTime: DateTime.parse(e['accessTime'] as String),
              fileAttributes: e['fileAttributes'] as String,
              fileSize: e['fileSize'] as int,
              entryID: e['entryID'] as String,
              applicationID: e['applicationID'] as String,
              fileExtension: e['fileExtension'] as String,
              computerName: e['computerName'] as String,
              jumplistsFilename: e['jumplistsFilename'] as String,
            ))
        .toList();
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
                            event_record_id INT,
                            filename VARCHAR,
                            full_log TEXT,
                            "isMalicious" BOOLEAN,
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
                            type INTEGER NOT NULL,
                            timestamp DATETIME,
                            exeinfo VARCHAR,
                            "ExeInfoDescription" VARCHAR,
                            "exeTimeStamp" DATETIME,
                            "SidType" VARCHAR,
                            Sid VARCHAR,
                            Username VARCHAR,
                            "user_sid" VARCHAR,
                            AppId INTEGER,
                            full TEXT,
                            PRIMARY KEY(id)
                          );

                          CREATE TABLE "prefetch" (
                            "id"	INTEGER NOT NULL,
                            "filename"	VARCHAR NOT NULL,
                            "createTime"	DATETIME,
                            "modifiedTime"	DATETIME,
                            "fileSize"	INT,
                            "process_exe"	VARCHAR,
                            "process_path"	VARCHAR,
                            "run_counter"	INTEGER,
                            "missingProcess"	BOOLEAN, 
                            'lastRuntime0' datetime, 
                            'lastRuntime1' datetime, 
                            'lastRuntime2' datetime, 
                            'lastRuntime3' datetime, 
                            'lastRuntime4' datetime, 
                            'lastRuntime5' datetime, 
                            'lastRuntime6' datetime, 
                            'lastRuntime7' datetime,
                            PRIMARY KEY("id")
                          )

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
  final bool isMalicious;
  final int event_id;
  final int event_record_id;

  const eventLog({
    this.id,
    required this.event_record_id,
    required this.timestamp,
    required this.filename,
    required this.full_log,
    required this.isAnalyzed,
    required this.isMalicious,
    required this.event_id,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_record_id': event_record_id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'filename': filename,
      'full_log': full_log,
      'isAnalyzed': isAnalyzed ? 1 : 0,
      'isMalicious': isMalicious ? 1 : 0,
      'event_id': event_id,
    };
  }
}

class REGISTRY {
  final String directory;
  final String key;
  final String value;
  final String type;

  const REGISTRY({
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
  final int id;
  final SRUMType type;
  final DateTime timestamp;
  final String exeinfo;
  final String ExeInfoDescription;
  final DateTime? exeTimeStamp;
  final String SidType;
  final String Sid;
  final String Username;
  final String user_sid;
  final int AppId;
  final String full;

  const SRUM(
      {required this.id,
      required this.type,
      required this.timestamp,
      required this.exeinfo,
      required this.ExeInfoDescription,
      required this.SidType,
      required this.Sid,
      required this.exeTimeStamp,
      required this.Username,
      required this.user_sid,
      required this.AppId,
      required this.full});

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'exeinfo': exeinfo,
      'ExeInfoDescription': ExeInfoDescription,
      'exeTimeStamp': exeTimeStamp?.millisecondsSinceEpoch,
      'SidType': SidType,
      'Sid': Sid,
      'Username': Username,
      'user_sid': user_sid,
      'AppId': AppId,
      'full': full,
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
  final DateTime? lastRunTime0;
  final DateTime? lastRunTime1;
  final DateTime? lastRunTime2;
  final DateTime? lastRunTime3;
  final DateTime? lastRunTime4;
  final DateTime? lastRunTime5;
  final DateTime? lastRunTime6;
  final DateTime? lastRunTime7;
  final bool missingProcess;

  const prefetch({
    required this.filename,
    required this.createTime,
    required this.modifiedTime,
    required this.fileSize,
    required this.process_exe,
    required this.process_path,
    required this.run_counter,
    required this.lastRunTime0,
    required this.lastRunTime1,
    required this.lastRunTime2,
    required this.lastRunTime3,
    required this.lastRunTime4,
    required this.lastRunTime5,
    required this.lastRunTime6,
    required this.lastRunTime7,
    required this.missingProcess,
  });

  Map<String, Object?> toMap() {
    return {
      'filename': filename,
      'createTime': createTime.millisecondsSinceEpoch,
      'modifiedTime': modifiedTime.millisecondsSinceEpoch,
      'fileSize': fileSize,
      'process_exe': process_exe,
      'process_path': process_path,
      'run_counter': run_counter,
      'lastRunTime0': lastRunTime0,
      'lastRunTime1': lastRunTime1,
      'lastRunTime2': lastRunTime2,
      'lastRunTime3': lastRunTime3,
      'lastRunTime4': lastRunTime4,
      'lastRunTime5': lastRunTime5,
      'lastRunTime6': lastRunTime6,
      'lastRunTime7': lastRunTime7,
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
  final String fileAttributes;
  final int fileSize;
  final String entryID;
  final String applicationID;
  final String fileExtension;
  final String computerName;
  final String jumplistsFilename;

  const jumplist({
    required this.filename,
    required this.fullPath,
    required this.recordTime,
    required this.createTime,
    required this.modifiedTime,
    required this.accessTime,
    required this.fileAttributes,
    required this.fileSize,
    required this.entryID,
    required this.applicationID,
    required this.fileExtension,
    required this.computerName,
    required this.jumplistsFilename,
  });

  Map<String, Object?> toMap() {
    return {
      'filename': filename,
      'fullPath': fullPath,
      'recordTime': recordTime.microsecondsSinceEpoch,
      'createTime': createTime.millisecondsSinceEpoch,
      'modifiedTime': modifiedTime.millisecondsSinceEpoch,
      'accessTime': accessTime.millisecondsSinceEpoch,
      'fileAttributes': fileAttributes,
      'fileSize': fileSize,
      'entryID': entryID,
      'applicationID': applicationID,
      'fileExtension': fileExtension,
      'computerName': computerName,
      'jumplistsFilename': jumplistsFilename,
    };
  }
}

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
  String dbName = "";

  // Constructor
  DatabaseManager();

  Future<void> insertEventLog(eventLog event) async {
    if (database == null) {
      await open();
    }
    await database!.transaction((txn) async {
      await txn.insert('evtx', event.toMap());
    });
  }

  Future<void> insertEventLogs(List<eventLog> events) async {
    if (database == null) {
      await open();
    }

    await database!.transaction((txn) async {
      Batch batch = txn.batch();
      for (var event in events) {
        batch.insert('evtx', event.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> insertEvtxFiles(evtxFiles evtxFile) async {
    if (database == null) {
      await open();
    }
    await database!.transaction((txn) async {
      await txn.insert('evtxFiles', evtxFile.toMap());
    });
  }

  Future<List<Map<String, Object?>>> getEvtxFileList() async {
    if (database == null) {
      await open();
    }
    return await database!.transaction((txn) async {
      return await txn.query('evtxFiles');
    });
  }

  Future<int> getEvtxAnomalyCount() async {
    if (database == null) {
      await open();
    }
    return await database!.transaction((txn) async {
      List<Map<String, Object?>> evtxList = await txn.query('evtx',
          where: 'isMalicious = ? OR sigmaLevel > ?', whereArgs: [1, 0]);
      return evtxList.length;
    });
  }

  Future<List<Map<String, Object?>>> getEventLogList(String filename) async {
    if (database == null) {
      await open();
    }
    if (filename == "") {
      return database!.query('evtx');
    }

    return await database!.transaction((txn) async {
      return await txn
          .query('evtx', where: 'filename = ?', whereArgs: [filename]);
    });
  }

  Future<int> updateMaliciousEvtx(int timestamp) async {
    if (database == null) {
      await open();
    }
    int result = 0;
    await database!.transaction((txn) async {
      result = await txn.update('evtx', {'isMalicious': 1},
          where: 'timestamp >= ? AND timestamp < ?',
          whereArgs: [timestamp, timestamp + 60 * 1000]);
    });
    return result;
  }

  Future<void> updateEventLog(eventLog event) async {
    if (database == null) {
      await open();
    }
    await database!
        .update('evtx', event.toMap(), where: 'id = ?', whereArgs: [event.id]);
  }

  Future<void> updateSigmaRule(
      int eventRecordId, String filename, String name, String level) async {
    if (database == null) {
      await open();
    }
    int intLevel = 0;
    if (level == "low") {
      intLevel = 1;
    } else if (level == "medium") {
      intLevel = 2;
    } else if (level == "high") {
      intLevel = 3;
    } else if (level == "critical") {
      intLevel = 4;
    }

    await database!.transaction((txn) async {
      await txn.update(
        'evtx',
        {
          "sigmaName": name,
          "sigmaLevel": intLevel,
        },
        where: 'event_record_id = ? AND filename = ?',
        whereArgs: [eventRecordId, filename],
      );
    });
  }

  List<Map<String, Object?>> EventLogCache = [];

  void clearCache() {
    EventLogCache = [];
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
    DateTimeRange? timestamp,
    bool sortDesc = false,
  }) async {
    print("pageToken $pageToken");
    if (EventLogCache.isEmpty) {
      print("[*] Cache is empty");
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

    if (content != null) {
      eventLogs = eventLogs
          .where((element) => element['full_log'].toString().contains(content))
          .toList();
    }

    if (malicious != null) {
      eventLogs = eventLogs.where((element) {
        return element['isMalicious'] as int == 1 ||
            int.parse(element['sigmaLevel'].toString()) > 0;
      }).toList();
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
              isMalicious: e['isMalicious'] as int == 1 ? true : false,
              sigmaName:
                  e['sigmaName'] != null ? e['sigmaName'] as String : null,
              sigmaLevel: e['sigmaLevel'] != null ? e['sigmaLevel'] as int : 0,
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

  Future<int> getMaliciousRegistryCount() async {
    if (database == null) {
      await open();
    }
    List<Map<String, Object?>> registryList = await database!
        .query('registry', where: 'modified = ?', whereArgs: [1]);
    return registryList.length;
  }

  Future<void> insertRegistry(REGISTRY reg) async {
    if (database == null) {
      await open();
    }
    await database!.transaction((txn) async {
      await txn.insert('registry', reg.toMap());
    });
  }

  Future<void> insertRegistryList(List<REGISTRY> reg) async {
    if (database == null) {
      await open();
    }

    await database!.transaction((txn) async {
      Batch batch = txn.batch();
      for (var r in reg) {
        batch.insert('registry', r.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<REGISTRY>> getModifiedRegistryList() async {
    if (database == null) {
      await open();
    }
    List<Map<String, Object?>> registryList = await database!
        .query('registry', where: 'modified = ?', whereArgs: [1]);
    return registryList
        .map((e) => REGISTRY(
              directory: e['directory'] as String,
              key: e['key'] as String,
              value: e['value'] as String,
              type: e['type'] as String,
              modified: e['modified'] as int == 1 ? true : false,
            ))
        .toList();
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
              modified: e['modified'] as int == 1 ? true : false,
            ))
        .toList();
  }

  Future<void> insertSRUM(List<SRUM> srums) async {
    if (database == null) {
      await open();
    }
    await database!.transaction((txn) async {
      Batch bat = txn.batch();
      for (var srum in srums) {
        bat.insert('SRUM', srum.toMap());
      }
      await bat.commit(noResult: true, continueOnError: true);
    });
  }

  Future<List<SRUM>> getSRUMList() async {
    if (database == null) {
      await open();
    }
    return await database!.transaction((txn) async {
      List<Map<String, Object?>> srumList = await txn.query('SRUM');
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
    });
  }

  Future<void> insertPrefetch(prefetch pref) async {
    if (database == null) {
      await open();
    }
    await database!.transaction((txn) async {
      await txn.insert('prefetch', pref.toMap());
    });
  }

  Future<List<prefetch>> getPrefetchList() async {
    if (database == null) {
      await open();
    }
    return await database!.transaction((txn) async {
      List<Map<String, Object?>> prefetchList = await txn.query('prefetch');
      return prefetchList
          .map((e) => prefetch(
                filename: e['filename'] as String,
                createTime:
                    DateTime.fromMillisecondsSinceEpoch(e['createTime'] as int),
                modifiedTime: DateTime.fromMicrosecondsSinceEpoch(
                    e['modifiedTime'] as int),
                fileSize: e['fileSize'] as int,
                process_exe: e['process_exe'] as String,
                process_path: e['process_path'] as String,
                run_counter: e['run_counter'] as int,
                lastRuntime0: e['lastRuntime0'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['lastRuntime0'] as int),
                lastRuntime1: e['lastRuntime1'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['lastRuntime1'] as int),
                lastRuntime2: e['lastRuntime2'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['lastRuntime2'] as int),
                lastRuntime3: e['lastRuntime3'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['lastRuntime3'] as int),
                lastRuntime4: e['lastRuntime4'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['lastRuntime4'] as int),
                lastRuntime5: e['lastRuntime5'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['lastRuntime5'] as int),
                lastRuntime6: e['lastRuntime6'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['lastRuntime6'] as int),
                lastRuntime7: e['lastRuntime7'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['lastRuntime7'] as int),
                missingProcess: e['missingProcess'] as int == 1 ? true : false,
              ))
          .toList();
    });
  }

  Future<void> insertJumplist(jumplist jump) async {
    if (database == null) {
      await open();
    }
    await database!.transaction((txn) async {
      await txn.insert('jumplist', jump.toMap());
    });
  }

  Future<List<jumplist>> getJumplistList() async {
    if (database == null) {
      await open();
    }
    return await database!.transaction((txn) async {
      List<Map<String, Object?>> jumplistList = await txn.query('jumplist');
      return jumplistList
          .map((e) => jumplist(
                filename: e['filename'] as String,
                fullPath: e['fullPath'] as String,
                recordTime: e['recordTime'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['recordTime'] as int),
                createTime: e['createTime'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['createTime'] as int),
                modifiedTime: e['modifiedTime'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['modifiedTime'] as int),
                accessTime: e['accessTime'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        e['accessTime'] as int),
                fileAttributes: e['fileAttributes'] as String,
                fileSize: e['fileSize'] as int,
                entryID: e['entryID'] as String,
                applicationID: e['applicationID'] as String,
                fileExtension: e['fileExtension'] as String,
                computerName: e['computerName'] as String,
                jumplistsFilename: e['jumplistsFilename'] as String,
              ))
          .toList();
    });
  }

  Future<Map<String, dynamic>> getRelatedArtifacts(DateTime timestamp) async {
    if (database == null) {
      await open();
    }
    return await database!.transaction((txn) async {
      Map<String, dynamic> artifacts = {};
      int ts = timestamp.millisecondsSinceEpoch;

      int tsStart = ts - 5 * 60 * 1000;
      int tsEnd = ts + 5 * 60 * 1000;

      artifacts['evtx'] = await txn.query('evtx',
          where: 'timestamp >= ? AND timestamp < ?',
          whereArgs: [tsStart, tsEnd]);

      artifacts['srum'] = await txn.query('SRUM',
          where: 'timestamp >= ? AND timestamp < ?',
          whereArgs: [tsStart, tsEnd]);

      artifacts['prefetch'] = await txn.query('prefetch',
          where: '(createTime >= ? AND createTime < ?) OR '
              '(modifiedTime >= ? AND modifiedTime < ?) OR '
              '(lastRuntime0 >= ? AND lastRuntime0 < ?) OR '
              '(lastRuntime1 >= ? AND lastRuntime1 < ?) OR '
              '(lastRuntime2 >= ? AND lastRuntime2 < ?) OR '
              '(lastRuntime3 >= ? AND lastRuntime3 < ?) OR '
              '(lastRuntime4 >= ? AND lastRuntime4 < ?) OR '
              '(lastRuntime5 >= ? AND lastRuntime5 < ?) OR '
              '(lastRuntime6 >= ? AND lastRuntime6 < ?) OR '
              '(lastRuntime7 >= ? AND lastRuntime7 < ?)',
          whereArgs: [
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
          ]);
      artifacts['jumplist'] = await txn.query('jumplist',
          where: '(recordTime >= ? AND recordTime < ?) OR '
              '(createTime >= ? AND createTime < ?) OR '
              '(modifiedTime >= ? AND modifiedTime < ?) OR '
              '(accessTime >= ? AND accessTime < ?)',
          whereArgs: [
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
            tsStart,
            tsEnd,
          ]);

      return artifacts;
    });
  }

  Future<void> insertComputerInfo(Map<String, Object?> computerInfo) async {
    if (database == null) {
      await open();
    }
    await database!.transaction((txn) async {
      await txn.insert('computerInfo', computerInfo);
    });
  }

  //get computer info
  Future<List<computerInfo>> getComputerInfo() async {
    return await database!.transaction((txn) async {
      List<Map<String, Object?>> result = await txn.query('computerInfo');

      List<computerInfo> computerInfoList = result
          .map((e) => computerInfo(
                key: e['key'] as String,
                value: e['value'] as String,
              ))
          .toList();
      return computerInfoList;
    });
  }

  void close() {
    database?.close();
    print("[*] Database closed");
  }

  // Methods
  Future open() async {
    if (database != null) {
      close();
    }
    print("[*] Opening database... $dbName");
    print(join(Directory.current.path, dbName));

    database = await openDatabase(
      join(Directory.current.path, dbName),
      version: 1,
      onCreate: (Database db, int version) async {
        return db.execute('''
                          CREATE TABLE evtxFiles(
                            id INTEGER PRIMARY KEY,
                            filename TEXT,
                            logCount INTEGER,
                            isFetched BOOLEAN
                          );

                          CREATE TABLE "computerInfo" (
                            "key"	TEXT,
                            "value"	TEXT
                          );

                          CREATE TABLE evtx(
                            id INTEGER NOT NULL,
                            timestamp DATETIME,
                            event_record_id INT,
                            filename VARCHAR,
                            full_log TEXT,
                            "isMalicious" BOOLEAN,
                            "sigmaName" VARCHAR,
                            "sigmaLevel" INT,
                            event_id INTEGER NOT NULL,
                            PRIMARY KEY(id)
                          );

                          CREATE TABLE registry(
                            id INTEGER NOT NULL,
                            directory VARCHAR NOT NULL,
                            "key" VARCHAR NOT NULL,
                            value VARCHAR NOT NULL,
                            type INTEGER NOT NULL,
                            modified BOOLEAN,
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
                          );

                          CREATE TABLE jumplist(
                            id INTEGER NOT NULL,
                            filename VARCHAR,
                            "fullPath" VARCHAR,
                            "recordTime" DATETIME,
                            "createTime" DATETIME,
                            "modifiedTime" DATETIME,
                            "accessTime" DATETIME,
                            "fileSize" INTEGER,
                            "fileAttributes" VARCHAR,
                            "entryID" VARCHAR,
                            "applicationID" VARCHAR,
                            "fileExtension" VARCHAR,
                            "computerName" VARCHAR,
                            "jumplistsFilename" VARCHAR,
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
  final bool isMalicious;
  final int event_id;
  final int event_record_id;
  final int sigmaLevel;
  final String? sigmaName;

  const eventLog(
      {this.id,
      required this.event_record_id,
      required this.timestamp,
      required this.filename,
      required this.full_log,
      required this.isMalicious,
      required this.event_id,
      required this.sigmaLevel,
      required this.sigmaName});

  Map<String, dynamic> toMap() {
    return {
      'event_record_id': event_record_id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'filename': filename,
      'full_log': full_log,
      'isMalicious': isMalicious ? 1 : 0,
      'event_id': event_id,
      'sigmaLevel': sigmaLevel,
      'sigmaName': sigmaName,
    };
  }
}

class REGISTRY {
  final String directory;
  final String key;
  final String value;
  final String type;
  final bool modified;

  const REGISTRY({
    required this.directory,
    required this.key,
    required this.value,
    required this.type,
    required this.modified,
  });

  Map<String, Object?> toMap() {
    return {
      'directory': directory,
      'key': key,
      'value': value,
      'type': type,
      'modified': modified ? 1 : 0,
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
  final DateTime? lastRuntime0;
  final DateTime? lastRuntime1;
  final DateTime? lastRuntime2;
  final DateTime? lastRuntime3;
  final DateTime? lastRuntime4;
  final DateTime? lastRuntime5;
  final DateTime? lastRuntime6;
  final DateTime? lastRuntime7;
  final bool missingProcess;

  const prefetch({
    required this.filename,
    required this.createTime,
    required this.modifiedTime,
    required this.fileSize,
    required this.process_exe,
    required this.process_path,
    required this.run_counter,
    required this.lastRuntime0,
    required this.lastRuntime1,
    required this.lastRuntime2,
    required this.lastRuntime3,
    required this.lastRuntime4,
    required this.lastRuntime5,
    required this.lastRuntime6,
    required this.lastRuntime7,
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
      'lastRuntime0': lastRuntime0?.millisecondsSinceEpoch,
      'lastRuntime1': lastRuntime1?.millisecondsSinceEpoch,
      'lastRuntime2': lastRuntime2?.millisecondsSinceEpoch,
      'lastRuntime3': lastRuntime3?.millisecondsSinceEpoch,
      'lastRuntime4': lastRuntime4?.millisecondsSinceEpoch,
      'lastRuntime5': lastRuntime5?.millisecondsSinceEpoch,
      'lastRuntime6': lastRuntime6?.millisecondsSinceEpoch,
      'lastRuntime7': lastRuntime7?.millisecondsSinceEpoch,
      'missingProcess': missingProcess ? 1 : 0,
    };
  }
}

class jumplist {
  final String filename;
  final String fullPath;
  final DateTime? recordTime;
  final DateTime? createTime;
  final DateTime? modifiedTime;
  final DateTime? accessTime;
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
      'recordTime': recordTime?.millisecondsSinceEpoch,
      'createTime': createTime?.millisecondsSinceEpoch,
      'modifiedTime': modifiedTime?.millisecondsSinceEpoch,
      'accessTime': accessTime?.millisecondsSinceEpoch,
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

class computerInfo {
  final String key;
  final String value;

  const computerInfo({
    required this.key,
    required this.value,
  });

  Map<String, Object?> toMap() {
    return {
      'key': key,
      'value': value,
    };
  }
}

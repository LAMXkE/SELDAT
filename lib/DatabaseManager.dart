import 'dart:ffi';
import 'dart:io';
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
        return db.execute('''CREATE TABLE evtx(
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

class eventLog {
  final DateTime timestamp;
  final String filename;
  final String full_log;
  final bool isAnalyzed;
  final double riskScore;
  final int event_id;

  const eventLog({
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

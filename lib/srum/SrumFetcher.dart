import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:seldat/DatabaseManager.dart';

enum SRUMType {
  AppResourceUseInfo,
  NetworkUsage,
  AppTimeline,
  NetworkConnections,
  PushNotifications,
  EnergyUsage,
  VFUProv
}

class Srumfetcher {
  Function addCount = () {};
  bool isFetched = false;
  final DatabaseManager db;

  Srumfetcher(this.db) {
    // Initialize your class here
    if (!Directory(".\\Artifacts").existsSync()) {
      Directory(".\\Artifacts").create();
    }

    if (!Directory(".\\Artifacts\\Srum").existsSync()) {
      Directory(".\\Artifacts\\Srum").create();
    } else {
      Directory(".\\Artifacts\\Srum").listSync().forEach((entity) {
        if (entity is File && entity.path.endsWith('.csv')) {
          entity.deleteSync();
        }
      });
    }
  }

  void setAddCount(Function addCount) {
    this.addCount = addCount;
  }

  List<SrumData> srumData = [];
  List<SRUM> srumList = [];

  Future<bool> loadDB() async {
    srumList = await db.getSRUMList();
    if (srumList.isNotEmpty) {
      isFetched = true;
      addCount(srumList.length);
      return true;
    }
    return false;
  }

  Future<void> fetchSrumData() async {
    // Run SrumECmd in the tools directory

    if (srumList.isNotEmpty) {
      isFetched = true;
      return;
    }
    print('Fetching SRUM data...');

    await Process.run(
      'tools/SrumECmd.exe',
      ["-d", 'C:\\Windows\\System32\\sru', "--csv", "Artifacts\\Srum"],
    ).then((ProcessResult result) async {
      print("SrumECmd exit code: ${result.exitCode}");

      if (result.exitCode == 0) {
        // Read all CSV files in the current directory
        Directory(".\\Artifacts\\Srum").listSync().forEach((entity) {
          if (entity is File && entity.path.endsWith('.csv')) {
            // Parse the CSV file
            srumData.add(SrumData(
                filename: entity.path,
                dataType: toSrumType(entity.path),
                data: const CsvToListConverter()
                    .convert(entity.readAsStringSync())));
          }
        });

        for (SrumData item in srumData) {
          List<List<dynamic>> data = item.data;
          for (List<dynamic> row in data) {
            if (row[0].toString() == 'Id') {
              continue;
            }

            int Id = int.parse(row[0].toString());

            DateTime timestamp = DateTime.parse(row[1].toString());
            String exeinfo = row[2].toString();
            String ExeInfoDescription = row[3].toString();
            DateTime? exeTimeStamp = DateTime.tryParse(row[4].toString());
            String SidType = row[5].toString();
            String Sid = row[6].toString();
            String Username = row[7].toString();
            String userSid = row[8].toString();
            int AppId = -1;
            if (row[9].toString() != "") {
              AppId = int.parse(row[9].toString());
            }
            String full = row.join("`"); // [10] - [12

            srumList.add(SRUM(
                id: Id,
                type: item.dataType,
                timestamp: timestamp,
                exeinfo: exeinfo,
                ExeInfoDescription: ExeInfoDescription,
                exeTimeStamp: exeTimeStamp,
                SidType: SidType,
                Sid: Sid,
                Username: Username,
                user_sid: userSid,
                AppId: AppId,
                full: full));
            addCount(1);
          }
        }
        db.insertSRUM(srumList);
        print('SRUM data fetched! ${srumList.length} records added to DB.');
        isFetched = true;
      } else {
        print('SrumECmd failed with exit code ${result.exitCode}');
      }
    });
  }

  List<SRUM> getSrumData() {
    return srumList;
  }

  SRUMType toSrumType(String path) {
    if (path.contains("AppResourceUseInfo")) {
      return SRUMType.AppResourceUseInfo;
    }
    if (path.contains("NetworkUsage")) {
      return SRUMType.NetworkUsage;
    }
    if (path.contains("AppTimeline")) {
      return SRUMType.AppTimeline;
    }
    if (path.contains("NetworkConnections")) {
      return SRUMType.NetworkConnections;
    }
    if (path.contains("PushNotifications")) {
      return SRUMType.PushNotifications;
    }
    if (path.contains("EnergyUsage")) {
      return SRUMType.EnergyUsage;
    }
    if (path.contains("vfuprov")) {
      return SRUMType.VFUProv;
    }
    return SRUMType.AppResourceUseInfo;
  }

  String toSrumName(SRUMType type) {
    switch (type) {
      case SRUMType.AppResourceUseInfo:
        return "App Resource Usage";
      case SRUMType.NetworkUsage:
        return "Network Usage";
      case SRUMType.AppTimeline:
        return "App Timeline";
      case SRUMType.NetworkConnections:
        return "Network Connections";
      case SRUMType.PushNotifications:
        return "Push Notifications";
      case SRUMType.EnergyUsage:
        return "Energy Usage";
      case SRUMType.VFUProv:
        return "VFUProv";
      default:
        return "";
    }
  }
}

class SrumData {
  String filename;
  SRUMType dataType;
  List<List<dynamic>> data;
  SrumData(
      {required this.filename, required this.data, required this.dataType});
}

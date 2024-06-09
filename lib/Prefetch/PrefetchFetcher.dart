import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:seldat/DatabaseManager.dart';

class Prefetchfetcher {
  final DatabaseManager db;

  Function addCount = () {};
  bool isFetched = false;
  List<Map<String, dynamic>> prefetchList = [];

  Prefetchfetcher(this.db);

  void setAddCount(Function addCount) {
    this.addCount = addCount;
  }

  List<Map<String, dynamic>> getPrefetchList() {
    return prefetchList;
  }

  String convertDate(String input) {
    input = input.replaceAll(RegExp(r'(.)'), "");

    if (input.contains("오후")) {
      var splitInput = input.split(" ");
      var timeSplit = splitInput[2].split(":");
      var hour = int.parse(timeSplit[0]);
      if (hour != 12) {
        // Don't convert if it's 12 PM
        hour = hour + 12; // Convert PM hours to 24-hour format
      }
      timeSplit[0] = hour.toString();
      splitInput[2] = timeSplit.join(":");
      input = splitInput.join(" ");
      input = input.replaceAll("오후", "").trim();
    } else {
      input = input.replaceAll("오전", "").trim();
    }

    input = input.replaceAll(RegExp(' {2,}'),
        ' '); // Replace all multiple spaces with a single space

    return input;
  }

  Future<bool> loadDB() async {
    List<prefetch> prefetchFileList = await db.getPrefetchList();
    if (prefetchFileList.isNotEmpty) {
      addCount(prefetchFileList.length);
      prefetchList = prefetchFileList.map((e) {
        List<DateTime?> lastRunTimeList = [
          e.lastRunTime0,
          e.lastRunTime1,
          e.lastRunTime2,
          e.lastRunTime3,
          e.lastRunTime4,
          e.lastRunTime5,
          e.lastRunTime6,
          e.lastRunTime7
        ];
        return {
          'filename': e.filename,
          'createTime': e.createTime,
          'modifiedTime': e.modifiedTime,
          'fileSize': e.fileSize,
          'process_exe': e.process_exe,
          'process_path': e.process_path,
          'run_counter': e.run_counter,
          'lastRunTime': lastRunTimeList.join(','),
        };
      }).toList();
      isFetched = true;
      return true;
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getAllPrefetchFile() async {
    var winPrefetchViewPath = 'tools/WinPrefetchView.exe';
    var prefetchTxtData = 'prefetchData.txt';
    var process = await Process.start(winPrefetchViewPath, [
      '/stab',
      prefetchTxtData
    ]); // /stab: Save the list of files into a tab-delimited text file.
    var exitCode = await process.exitCode;

    if (exitCode != 0) {
      // If the exit code is not 0, throw an exception
      throw Exception('Error occurred. Exit code: $exitCode');
    }

    try {
      // Read the prefetchData.txt file
      var txtFile = File(prefetchTxtData);
      var bytes = await txtFile.readAsBytes();
      var utf16CodeUnits = bytes.buffer.asUint16List();
      var txtContent = String.fromCharCodes(utf16CodeUnits); // utf16 to utf8

      var lines = txtContent.split('\n');
      var Rows = lines.map((line) => line.split('\t')).toList(); // Split by tab

      List<Map<String, dynamic>> allPrefetchFile =
          Rows.where((row) => row.length >= 8).map((row) {
        return {
          'filename': row[0],
          'createTime': row[1],
          'modifiedTime': row[2],
          'fileSize': row[3],
          'process_exe': row[4],
          'process_path': row[5],
          'run_counter': row[6],
          'lastRunTime': row[7],
        };
      }).toList();
      for (var element in allPrefetchFile) {
        List<String> lastRunTime = element['lastRunTime'].split(',');
        List<DateTime?> lastRunTimeList = List.filled(8, null);
        print(element['createTime']);
        print(convertDate(element['createTime']));
        print(lastRunTime[0]);
        print(convertDate(lastRunTime[0]));
        for (int i = 0; i < lastRunTime.length; i++) {
          if (lastRunTime[i] != '') {
            lastRunTimeList[i] = DateTime.parse(convertDate(lastRunTime[i]));
          }
        }

        db.insertPrefetch(prefetch(
          filename: element['filename'],
          createTime: DateTime.parse(convertDate(element['createTime'])),
          modifiedTime: DateTime.parse(convertDate(element['modifiedTime'])),
          fileSize: element['fileSize'],
          process_exe: element['process_exe'],
          process_path: element['process_path'],
          run_counter: element['run_counter'],
          lastRunTime0: lastRunTimeList[0],
          lastRunTime1: lastRunTimeList[1],
          lastRunTime2: lastRunTimeList[2],
          lastRunTime3: lastRunTimeList[3],
          lastRunTime4: lastRunTimeList[4],
          lastRunTime5: lastRunTimeList[5],
          lastRunTime6: lastRunTimeList[6],
          lastRunTime7: lastRunTimeList[7],
          missingProcess: false,
        ));
      }

      return allPrefetchFile;
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }
}

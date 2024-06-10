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
    input = input.replaceAll(RegExp(r'\(.\)'), "").trim();

    if (input.contains("오후")) {
      var splitInput = input.split(" ");
      var timeSplit = splitInput[2].split(":");
      // print(splitInput);
      // print(timeSplit);
      var hour = int.parse(timeSplit[0]);
      if (hour != 12) {
        // Don't convert if it's 12 PM
        hour = hour + 12; // Convert PM hours to 24-hour format
      }
      timeSplit[0] = hour.toString().padLeft(2, '0');

      splitInput[2] = timeSplit.join(":");
      input = splitInput.join(" ");
      input = input.replaceAll("오후", "").trim();
    } else {
      var splitInput = input.split(" ");
      var timeSplit = splitInput[2].split(":");
      // print(splitInput);
      // print(timeSplit);
      var hour = int.parse(timeSplit[0]);

      timeSplit[0] = hour.toString().padLeft(2, '0');

      splitInput[2] = timeSplit.join(":");
      input = splitInput.join(" ");
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
        return {
          'filename': e.filename.toString(),
          'createTime': e.createTime.toString(),
          'modifiedTime': e.modifiedTime.toString(),
          'fileSize': e.fileSize.toString(),
          'process_exe': e.process_exe.toString(),
          'process_path': e.process_path.toString(),
          'run_counter': e.run_counter.toString(),
          'lastRunTime0':
              e.lastRuntime0 != null ? e.lastRuntime0.toString() : '',
          'lastRunTime1':
              e.lastRuntime1 != null ? e.lastRuntime1.toString() : '',
          'lastRunTime2':
              e.lastRuntime2 != null ? e.lastRuntime2.toString() : '',
          'lastRunTime3':
              e.lastRuntime3 != null ? e.lastRuntime3.toString() : '',
          'lastRunTime4':
              e.lastRuntime4 != null ? e.lastRuntime4.toString() : '',
          'lastRunTime5':
              e.lastRuntime5 != null ? e.lastRuntime5.toString() : '',
          'lastRunTime6':
              e.lastRuntime6 != null ? e.lastRuntime6.toString() : '',
          'lastRunTime7':
              e.lastRuntime7 != null ? e.lastRuntime7.toString() : '',
          'missingProcess': e.missingProcess ? 'Yes' : 'No',
        };
      }).toList();
      isFetched = true;
      return true;
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getAllPrefetchFile() async {
    var winPrefetchViewPath = 'tools/WinPrefetchView.exe';
    var prefetchTxtData = 'Artifacts/prefetchData.txt';
    var process = await Process.start(winPrefetchViewPath, [
      '/stab',
      prefetchTxtData
    ]); // /stab: Save the list of files into a tab-delimited text file.
    var exitCode = await process.exitCode;

    if (exitCode != 0) {
      // If the exit code is not 0, throw an exception
      throw Exception('Error occurred. Exit code: $exitCode');
    }

    // try {
    // Read the prefetchData.txt file
    var txtFile = File(prefetchTxtData);
    var bytes = await txtFile.readAsBytes();
    var utf16CodeUnits = bytes.buffer.asUint16List();
    var txtContent = String.fromCharCodes(utf16CodeUnits); // utf16 to utf8

    var lines = txtContent.split('\n');
    var Rows = lines.map((line) => line.split('\t')).toList(); // Split by tab

    List<Map<String, dynamic>> allPrefetchFile =
        Rows.where((row) => row.length >= 9).map((row) {
      return {
        'filename': row[0],
        'createTime': row[1],
        'modifiedTime': row[2],
        'fileSize': row[3],
        'process_exe': row[4],
        'process_path': row[5],
        'run_counter': row[6],
        'lastRuntime': row[7],
        'missingProcess': row[8]
      };
    }).toList();
    for (var element in allPrefetchFile) {
      List<String> lastRuntime = element['lastRuntime'].split(',');
      List<DateTime?> lastRuntimeList = List.filled(8, null);
      for (int i = 0; i < lastRuntime.length; i++) {
        if (lastRuntime[i] != '') {
          lastRuntimeList[i] = DateTime.parse(convertDate(lastRuntime[i]));
        }
      }

      db.insertPrefetch(prefetch(
        filename: element['filename'],
        createTime: DateTime.parse(convertDate(element['createTime'])),
        modifiedTime: DateTime.parse(convertDate(element['modifiedTime'])),
        fileSize: int.parse(element['fileSize'].replaceAll(",", "")),
        process_exe: element['process_exe'],
        process_path: element['process_path'],
        run_counter: int.parse(element['run_counter'].replaceAll(",", "")),
        lastRuntime0: lastRuntimeList[0],
        lastRuntime1: lastRuntimeList[1],
        lastRuntime2: lastRuntimeList[2],
        lastRuntime3: lastRuntimeList[3],
        lastRuntime4: lastRuntimeList[4],
        lastRuntime5: lastRuntimeList[5],
        lastRuntime6: lastRuntimeList[6],
        lastRuntime7: lastRuntimeList[7],
        missingProcess: element['missingProcess'] == 'Yes' ? true : false,
      ));
    }
    addCount(allPrefetchFile.length);
    prefetchList = allPrefetchFile;
    isFetched = true;
    return allPrefetchFile;
    // } catch (e) {
    //   throw Exception('Failed to read file: $e');
    // }
  }
}

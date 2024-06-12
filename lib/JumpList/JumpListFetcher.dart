import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:seldat/DatabaseManager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class JumplistFetcher {
  final DatabaseManager db;

  List<Map<String, dynamic>> allJumplistFile = [];

  bool isFetched = false;
  Function addCount = () {};

  JumplistFetcher(this.db);

  void setAddCount(Function addCount) {
    this.addCount = addCount;
  }

  List<Map<String, dynamic>> getJumplistList() {
    return allJumplistFile;
  }

  Future<bool> loadDB() async {
    List<jumplist> jumplistFileList = await db.getJumplistList();
    if (jumplistFileList.isNotEmpty) {
      addCount(jumplistFileList.length);
      allJumplistFile = jumplistFileList.map((e) {
        return {
          'filename': e.filename,
          'fullPath': e.fullPath,
          'recordTime': e.recordTime == null ? '' : e.recordTime.toString(),
          'createdTime': e.createTime == null ? '' : e.createTime.toString(),
          'modifiedTime':
              e.modifiedTime == null ? '' : e.modifiedTime.toString(),
          'accessedTime': e.accessTime == null ? '' : e.accessTime.toString(),
          'fileAttributes': e.fileAttributes,
          'fileSize': e.fileSize == -1 ? '' : e.fileSize.toString(),
          'entryID': e.entryID,
          'applicationID': e.applicationID,
          'fileExtension': e.fileExtension,
          'computerName': e.computerName,
          'jumplistsFilename': e.jumplistsFilename,
        };
      }).toList();
      addCount(allJumplistFile.length);
    }
    isFetched = true;
    return false;
  }

  String convertDate(String input) {
    if (input == "") return "";
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

  Future<List<Map<String, dynamic>>> getAllJumpListFile() async {
    var winJumpListViewPath = 'tools/JumpListsView.exe';
    var JumpListTxtData = 'Artifacts/JumpListData.txt';
    var process = await Process.start(winJumpListViewPath, [
      '/stab',
      JumpListTxtData
    ]); // /stab: Save the list of files into a tab-delimited text file.
    var exitCode = await process.exitCode;

    if (exitCode != 0) {
      // If the exit code is not 0, throw an exception
      throw Exception('Error occurred. Exit code: $exitCode');
    }

    // Read the JumpListData.txt file
    var txtFile = File(JumpListTxtData);
    var bytes = await txtFile.readAsBytes();
    var utf16CodeUnits = bytes.buffer.asUint16List();
    var txtContent = String.fromCharCodes(utf16CodeUnits); // utf16 to utf8

    var lines = txtContent.split('\n');
    var Rows = lines
        .skip(1)
        .map((line) => line.split('\t'))
        .toList(); // Skip the first line

    List<Map<String, dynamic>> allJumpListFile =
        Rows.where((row) => row.length >= 13).map((row) {
      return {
        'filename': row[0],
        'fullPath': row[1],
        'recordTime': row[2],
        'createdTime': row[3],
        'modifiedTime': row[4],
        'accessedTime': row[5],
        'fileAttributes': row[6],
        'fileSize': row[7],
        'entryID': row[8],
        'applicationID': row[9],
        'fileExtension': row[11],
        'computerName': row[12],
        'jumplistsFilename': row[13],
      };
    }).toList();
    // print(allJumpListFile);
    for (var element in allJumpListFile) {
      db.insertJumplist(jumplist(
        filename: element['filename'],
        fullPath: element['fullPath'],
        recordTime: DateTime.tryParse(convertDate(element['recordTime'] ?? "")),
        createTime:
            DateTime.tryParse(convertDate(element['createdTime'] ?? "")),
        modifiedTime:
            DateTime.tryParse(convertDate(element['modifiedTime'] ?? "")),
        accessTime:
            DateTime.tryParse(convertDate(element['accessedTime'] ?? "")),
        fileAttributes: element['fileAttributes'],
        fileSize: int.tryParse(element['fileSize'].replaceAll(",", "")) ?? -1,
        entryID: element['entryID'],
        applicationID: element['applicationID'],
        fileExtension: element['fileExtension'],
        computerName: element['computerName'],
        jumplistsFilename: element['jumplistsFilename'],
      ));
      addCount(1);
    }
    isFetched = true;
    return allJumpListFile;
  }
}

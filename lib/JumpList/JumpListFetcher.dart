import 'dart:async';
import 'dart:io';
import 'dart:convert';

class JumpListDataParser {
  Future<List<Map<String, dynamic>>> getAllJumpListFile() async {
    var winJumpListViewPath = 'tools/JumpListsView.exe';
    var JumpListTxtData = 'JumpListData.txt';
    var process = await Process.start(winJumpListViewPath, [
      '/stab',
      JumpListTxtData
    ]); // /stab: Save the list of files into a tab-delimited text file.
    var exitCode = await process.exitCode;

    if (exitCode != 0) {
      // If the exit code is not 0, throw an exception
      throw Exception('Error occurred. Exit code: $exitCode');
    }

    try {
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
      return allJumpListFile;
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:convert';

class PrefetchDataParser {
  Future<List<Map<String, String>>> getAllPrefetchFile() async {
    var winPrefetchViewPath = './tools/WinPrefetchView.exe';
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

      List<Map<String, String>> allPrefetchFile =
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
      print(allPrefetchFile);
      return allPrefetchFile;
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }
}

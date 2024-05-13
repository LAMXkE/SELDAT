import 'dart:io';

class LogFetcher {
  // Properties
  List<File> eventLogList = List.empty(growable: true);

  // Constructor
  LogFetcher() {
    // Constructor code...
    Directory(".\\Artifacts").create();
    Directory(".\\Artifacts\\EventLogs").create();
    scanFiles(Directory('C:\\Windows\\System32\\winevt\\Logs'));
  }
  // Methods
  void scanFiles(Directory dir) async {
    try {
      var dirList = dir.list();
      await for (final FileSystemEntity entity in dirList) {
        if (entity is File) {
          if (entity.path.endsWith(".evtx")) {
            eventLogList.add(entity);
            try {
              entity.copy(
                  "Artifacts\\EventLogs\\${entity.path.split('\\').last}");
            } on PathExistsException catch (_, e) {}
          }
        } else if (entity is Directory) {
          scanFiles(Directory(entity.path));
        }
      }
    } on PathAccessException {
      return;
    }
  }

  List<File> getEventLogList() {
    return eventLogList;
  }
}

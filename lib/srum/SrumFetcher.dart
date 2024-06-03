import 'dart:io';

class Srumfetcher {
  Function addCount = () {};
  Srumfetcher() {
    // Initialize your class here
    if (!Directory(".\\Artifacts").existsSync()) {
      Directory(".\\Artifacts").create();
    }

    if (!Directory(".\\Artifacts\\Srum").existsSync()) {
      Directory(".\\Artifacts\\Srum").create();
    }
  }

  void setAddCount(Function addCount) {
    this.addCount = addCount;
  }

  void fetchSrumData() {
    // Run SrumECmd in the tools directory
    print('Fetching SRUM data...');
    // Get Numbers from the output
    // EX) vfuprov count:                 4,013
    // App Resource Usage count:      148,146
    // Network Connection count:      3,343
    // Network Usage count:           74492
    RegExp regExp = RegExp("count: *?([0-9]+(,?[0-9]+)?)");
    Process.run(
      'tools/SrumECmd.exe',
      ["-d", 'C:\\Windows\\System32\\sru', "--csv", "Artifacts\\Srum"],
    ).then((ProcessResult result) {
      Iterable matchCnt = regExp.allMatches(result.stdout.toString());
      // print(matchCnt.length);
      for (var element in matchCnt) {
        // print(element.group(1));
        addCount(int.parse(element.group(1).toString().replaceAll(',', '')));
      }

      if (result.exitCode == 0) {
        // Read all CSV files in the current directory
        Directory(".\\Artifacts\\Srum").listSync().forEach((entity) {
          if (entity is File && entity.path.endsWith('.csv')) {
            // Parse the CSV file
            print('Parsing ${entity.path}');
          }
        });
      } else {
        print('SrumECmd failed with exit code ${result.exitCode}');
      }
    });
  }

  void parseSrumData() {}
}

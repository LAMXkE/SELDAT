import 'dart:io';

import 'package:seldat/DatabaseManager.dart';

class Systeminfofetcher {
  final DatabaseManager db;
  Map<String, String> data = {};

  bool isFetched = false;

  Systeminfofetcher(this.db);

  Future<void> loadSystemInfo() async {
    ProcessResult result = await Process.run('systeminfo', []);
    data = parseData(result.stdout);
    data.forEach((key, value) {
      db.insertComputerInfo(computerInfo(key: key, value: value).toMap());
      return;
    });
  }

  Map<String, String> getData() {
    return data;
  }

  Future<void> loadDB() async {
    db.getComputerInfo().then((value) {
      if (value.isNotEmpty) {
        for (var element in value) {
          data[element.key] = element.value;
        }
        isFetched = true;
      }
    });
  }

  String? selectedKey;
  int? selectedIndex;

  Map<String, String> parseData(String data) {
    var headers = [
      // headers list
      '호스트 이름',
      'OS 이름',
      'OS 버전',
      'OS 제조업체',
      'OS 구성',
      'OS 빌드 종류',
      '등록된 소유자',
      '등록된 조직',
      '제품 ID',
      '원래 설치 날짜',
      '시스템 부트 시간',
      '시스템 제조업체',
      '시스템 모델',
      '시스템 종류',
      '프로세서',
      'BIOS 버전',
      'Windows 디렉터리',
      '시스템 디렉터리',
      '부팅 장치',
      '시스템 로캘',
      '입력 로캘',
      '표준 시간대',
      '총 실제 메모리',
      '사용 가능한 실제 메모리',
      '가상 메모리: 최대 크기',
      '가상 메모리: 사용 가능',
      '가상 메모리: 사용 중',
      '페이지 파일 위치',
      '도메인',
      '로그온 서버',
      '핫픽스',
      '네트워크 카드',
      'Hyper-V 요구 사항'
    ];
    var lines = data.split('\n');
    var parsedData = <String, String>{};
    String? currentKey;
    String currentValue = '';

    for (var line in lines) {
      var trimmedLine = line.trim();
      String? foundKey = headers.firstWhere(
          (header) => trimmedLine.startsWith(header),
          orElse: () => '');

      if (foundKey.isNotEmpty) {
        if (currentKey != null) {
          parsedData[currentKey] = currentValue.trim();
        }
        currentKey = foundKey;
        currentValue = trimmedLine.replaceFirst('$foundKey:', '').trim();
      } else if (currentKey != null) {
        currentValue += '\n$trimmedLine';
      }
    }

    if (currentKey != null) {
      parsedData[currentKey] = currentValue.trim();
    }
    // var jsonData = jsonEncode(parsedData);
    // var file = File('artifact/PCspec/data.txt');
    // file.writeAsString(jsonData);
    return parsedData;
  }
}

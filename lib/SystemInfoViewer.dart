import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';

class SystemInfoViewer extends StatefulWidget {
  const SystemInfoViewer({super.key});

  @override
  _SystemInfoViewerState createState() => _SystemInfoViewerState();
}

class _SystemInfoViewerState extends State<SystemInfoViewer> {
  Map<String, String> data = {'Loading...': ''};
  ProcessResult? result;
  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    result ??= await Process.run('systeminfo', []);
    setState(() {
      data = parseData(result!.stdout.toString());
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return ParsedDataListView(parsedData: data);
  }
}

class ParsedDataListView extends StatelessWidget {
  final Map<String, String> parsedData;

  const ParsedDataListView({super.key, required this.parsedData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 253, 253, 253),
          borderRadius: BorderRadius.circular(10.0), // 모서리를 둥글게 만듭니다.
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(31, 94, 94, 94), // 그림자의 색상을 설정합니다.
              blurRadius: 5.0, // 그림자의 흐림 정도를 설정합니다.
              spreadRadius: 1.0, // 그림자의 확산 정도를 설정합니다.
            ),
          ],
        ),
        child: ListView.builder(
          itemCount: parsedData.length,
          itemBuilder: (context, index) {
            var key = parsedData.keys.elementAt(index);
            var value = parsedData[key]!;
            // var lineCount = value.split('\n').length;

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: IntrinsicHeight(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12.0, 5.0, 5.0, 5.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              key,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: SelectableText(
                          value,
                          style: const TextStyle(
                            fontSize: 15.0,
                            height: 2.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

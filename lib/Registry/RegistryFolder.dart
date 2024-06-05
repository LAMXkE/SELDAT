import 'dart:async';
import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RegistryMapping {
  // key와 registryType 매핑
  final String registryName;
  final RegistryHive registryHive;
  final int registryKey;

  RegistryMapping(this.registryName, this.registryHive, this.registryKey);
}

class RegistryFolderViewer extends StatefulWidget {
  const RegistryFolderViewer({super.key});

  @override
  _RegistryFolderViewerState createState() => _RegistryFolderViewerState();
}

class _RegistryFolderViewerState extends State<RegistryFolderViewer> {
  Future<List<Map<String, dynamic>>>? _futureRegistryValues;

  bool _isDataFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      _futureRegistryValues = fetchAllRegistryData(); // Call the function here
      _isDataFetched = true;
    }
  }

  // static Future<File> writeFileAsString({String? data, String? path}) async { // json파일로 확인해보려고 추가한 코드
  //   final file =
  //       File(path ?? 'cache\\tmp.txt'); // Use 'File' instead of '_localFile'
  //   return file.writeAsString(data ?? '');
  // }
  //   List<Map<String, dynamic>> registryValues = await _futureRegistryValues!;
  //   // String jsonString = jsonEncode(registryValues); // 내 pc에 json파일로 저장
  //   // await writeFileAsString(
  //   //     data: jsonString, path: 'D:\\test\\test.json'); // Use 'await' here
  //   return registryValues;
  // }

  Future<List<Map<String, dynamic>>> fetchAllRegistryData() async {
    if (_futureRegistryValues != null) {
      return _futureRegistryValues!;
    }
    var registryNames = [
      'HKEY_CLASSES_ROOT',
      'HKEY_CURRENT_USER',
      'HKEY_LOCAL_MACHINE',
      'HKEY_USERS',
      'HKEY_CURRENT_CONFIG',
    ];
    var futures = registryNames
        .map(fetchRegistryData)
        .toList(); // registryNames의 values와 subkeys를 가져옴
    return await Future.wait(futures); // 모든 registryName의 values와 subkeys를 가져옴
  }

  Future<Map<String, dynamic>> fetchRegistryData(String registryName) async {
    List<RegistryMapping> mappings = [
      // key와 registryType 매핑
      RegistryMapping(
          'HKEY_CLASSES_ROOT', RegistryHive.classesRoot, HKEY_CLASSES_ROOT),
      RegistryMapping(
          'HKEY_CURRENT_USER', RegistryHive.currentUser, HKEY_CURRENT_USER),
      RegistryMapping(
          'HKEY_LOCAL_MACHINE', RegistryHive.localMachine, HKEY_LOCAL_MACHINE),
      RegistryMapping('HKEY_USERS', RegistryHive.allUsers, HKEY_USERS),
      RegistryMapping('HKEY_CURRENT_CONFIG', RegistryHive.currentConfig,
          HKEY_CURRENT_CONFIG),
    ];

    for (var mapping in mappings) {
      // mapping된 registryName이 있으면 해당 registryName의 values와 subkeys를 가져옴
      if (registryName == mapping.registryName) {
        print("current registryName : ${mapping.registryHive.name}");
        var key = RegistryKey(mapping.registryKey);
        List<Map<String, dynamic>> rootValues = []; //registryRoot
        List<Map<String, dynamic>> values = [
          // values가 없으면 default
          {
            'name': '(Default)',
            'type': 'REG_SZ',
            'data': '(No Data)',
          }
        ];
        if (key.values.isNotEmpty) {
          // key의 values가 있으면 values에 추가
          for (var value in key.values) {
            rootValues.add({
              'name': value.name,
              'type': value.type.win32Type,
              'data': value.data,
            });
          }
          values = rootValues;
        }
        var futures = <Future<List<Map<String, dynamic>>>>[];
        for (var subkey in key.subkeyNames) {
          // key의 subkey가 있으면 subkey의 values와 subkeys를 가져옴
          futures.add(fetchRegistryValues(mapping.registryHive, subkey)
              .then((value) => [value]));
        }
        var results =
            await Future.wait(futures); // 모든 subkey의 values와 subkeys를 가져옴

        key.close();
        return {
          // registryName, values, subkeys를 반환
          'registryName': mapping.registryName,
          'values': {
            'directory': mapping.registryName,
            'value': values,
          },
          'subkeys': results.expand((x) => x).toList(),
        };
      }
    }

    return {
      // 예외처리
      'registryName': registryName,
      'values': {
        'directory': registryName,
        'value': [
          {
            'name': '(Default)',
            'type': 'REG_SZ',
            'data': '(No Data)',
          }
        ],
      },
      'subkeys': [],
    };
  }

  Future<Map<String, dynamic>> fetchRegistryValues(
      // key와 path를 받아서 해당 key의 values와 subkeys를 가져옴
      RegistryHive key,
      String path) async {
    try {
      final regkey = Registry.openPath(key, path: path);

      List<Map<String, dynamic>> subkeys = [];
      for (var subkey in regkey.subkeyNames) {
        // subkey가 있으면 subkey의 values와 subkeys를 가져옴
        try {
          subkeys.add(await fetchRegistryValues(key, '$path\\$subkey'));
        } catch (e) {
          // 엑세스관련 예외처리
          if (e is WindowsException) {
            print('$key에서 WindowsException 발생: ${e.message}');
            continue;
          } else {
            rethrow;
          }
        }
      }
      List<Map<String, dynamic>> values = [];
      if (regkey.values.isNotEmpty) {
        for (var reg in regkey.values) {
          // values가 있으면 values에 추가
          values.add({
            'name': reg.name != '' ? reg.name.toString() : '(Default)',
            'type': reg.type.win32Type != null
                ? reg.type.win32Type.toString()
                : 'Default type',
            'data': reg.data != null ? reg.data.toString() : '(No Data)',
          });
        }
      } else {
        // values가 없으면 default
        values.add({
          'name': '(Default)',
          'type': 'REG_SZ',
          'data': '(No Data)',
        });
      }
      return {
        // key의 registryName, values, subkeys를 반환
        'registryName': path.split('\\').last,
        'values': {
          'directory': '$key\\$path',
          'value': values,
        },
        'subkeys': subkeys,
      };
    } on WindowsException catch (e) {
      // 엑세스관련 예외처리
      print('$key에서 WindowsException 발생: ${e.message}');
      return {
        'registryName': path.split('\\').last,
        'values': {
          'directory': '$key\\$path',
          'value': [
            {
              'name': '(Default)',
              'type': 'REG_SZ',
              'data': '(No Data)',
            }
          ],
        },
        'subkeys': [],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureRegistryValues,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return buildErrorWidget(snapshot.error);
        } else {
          return SingleChildScrollView(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: snapshot.data!.map<Widget>(buildRegistryTile).toList(),
            ),
          );
        }
      },
    );
  }

  Widget buildRegistryTile(Map<String, dynamic> registry) {
    // registryName, values, subkeys를 받아서 ExpansionTile로 반환
    return ExpansionTile(
      title: Text('ㄴ ${registry['registryName']}'),
      children: <Widget>[
        ...buildRegistryValues(registry['values']).map((widget) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 1.0, 1.0, 1.0),
            child: widget,
          );
        }),
        ...registry['subkeys'].map<Widget>((subkey) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(30.0, 1.0, 1.0, 1.0),
            child: buildRegistryTile(subkey),
          );
        }).toList(),
      ],
    );
  }

  List<Widget> buildRegistryValues(Map<String, dynamic> values) {
    // values를 받아서 ListTile로 반환
    List<Widget> widgets = [];
    widgets.add(buildListTile('Directory', values['directory']));
    for (var value in values['value']) {
      widgets.add(buildListTile("Name :  ${value['name'].toString()}",
          'Type :  ${value['type'].toString()}  |  Data :  ${value['data'].toString()}'));
    }
    return widgets;
  }

  ListTile buildListTile(String title, String subtitle) {
    // title과 subtitle을 받아서 ListTile로 반환
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget buildErrorWidget(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Error: $error'),
          ElevatedButton(
            child: const Text('Retry'),
            onPressed: () {
              setState(() {
                _futureRegistryValues = fetchAllRegistryData();
              });
            },
          ),
        ],
      ),
    );
  }
}

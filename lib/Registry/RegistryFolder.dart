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

  // @override
  // bool get wantKeepAlive => true; // Keep the widget's state

  bool _isDataFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      _futureRegistryValues = fetchAllRegistryData(); // Call the function here
      _isDataFetched = true;
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _futureRegistryValues = fetchAllRegistryData();
  // }

  // static Future<File> writeFileAsString({String? data, String? path}) async {
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
    var futures = registryNames.map(fetchRegistryData).toList();
    return await Future.wait(futures);
  }

  Future<Map<String, dynamic>> fetchRegistryData(String registryName) async {
    List<RegistryMapping> mappings = [
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
      if (registryName == mapping.registryName) {
        print("current registryName : ${mapping.registryHive.name}");
        var key = RegistryKey(mapping.registryKey);
        List<Map<String, dynamic>> rootValues = [];
        List<Map<String, dynamic>> values = [
          {
            'name': '(Default)',
            'type': 'REG_SZ',
            'data': '(No Data)',
          }
        ];
        if (key.values.isNotEmpty) {
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
          futures.add(fetchRegistryValues(mapping.registryHive, subkey)
              .then((value) => [value]));
        }
        var results = await Future.wait(futures);

        key.close();
        return {
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
      RegistryHive key, String path) async {
    try {
      final regkey = Registry.openPath(key, path: path);

      List<Map<String, dynamic>> subkeys = [];
      for (var subkey in regkey.subkeyNames) {
        try {
          subkeys.add(await fetchRegistryValues(key, '$path\\$subkey'));
        } catch (e) {
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
          values.add({
            'name': reg.name != '' ? reg.name.toString() : '(Default)',
            'type': reg.type.win32Type != null
                ? reg.type.win32Type.toString()
                : 'Default type',
            'data': reg.data != null ? reg.data.toString() : '(No Data)',
          });
        }
      } else {
        values.add({
          'name': '(Default)',
          'type': 'REG_SZ',
          'data': '(No Data)',
        });
      }
      return {
        'registryName': path.split('\\').last,
        'values': {
          'directory': '$key\\$path',
          'value': values,
        },
        'subkeys': subkeys,
      };
    } on WindowsException catch (e) {
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
    //super.build(context);
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
    return ExpansionTile(
      title: Text('ㄴ ${registry['registryName']}'), // ㄴ RegistryName
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
    List<Widget> widgets = [];
    widgets.add(buildListTile('Directory', values['directory']));
    for (var value in values['value']) {
      widgets.add(buildListTile("Name :  ${value['name'].toString()}",
          'Type :  ${value['type'].toString()}  |  Data :  ${value['data'].toString()}'));
    }
    return widgets;
  }

  ListTile buildListTile(String title, String subtitle) {
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

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

class RegistryMapping {
  // key와 registryType 매핑
  final String registryName;
  final RegistryHive registryHive;
  final int registryKey;

  RegistryMapping(this.registryName, this.registryHive, this.registryKey);
}

class RegistryFetcher {
  // Add your class members and methods here
  Map<String, dynamic> registryDatas = {};
  Function addCount = () {};
  bool isFetched = false;
  final Map<String, dynamic> _RegistryValues = {};
  DatabaseManager db;
  List<REGISTRY> registryList = [];
  // Constructor
  RegistryFetcher(this.db) {
    // Initialize your class here
  }

  Function onRegistryDataChanged = () {};

  Future<void> loadDB() async {
    var registryNames = [
      'currentConfig',
      'classesRoot',
      'currentUser',
      'localMachine',
      'allusers',
    ];
    registryList = await db.getRegistryList();
    if (registryList.isNotEmpty) {
      addCount(registryList.length);
      _RegistryValues.clear();

      for (var names in registryNames) {
        _RegistryValues[names] = {
          'directory': names,
          'values': {},
          'subkeys': {},
        };
      }
    }
  }

  Map<String, dynamic> getRegistryData() {
    return _RegistryValues;
  }

  Future<void> fillChild(Map<String, dynamic> reg) async {
    print(reg['directory']);
    List<String> posList = reg['directory'].split('\\');
    Map<String, dynamic> current = _RegistryValues;
    current = current[posList[0]];
    for (int i = 1; i < posList.length; i++) {
      current = current['subkeys'][posList[i]];
    }
    if (current['subkeys'].isNotEmpty) {
      print("Already Fetched");
      return;
    }
    registryList
        .where((element) => RegExp(
                "${reg['directory'].toString().replaceAll("\\", "\\\\")}\\\\(?!.*\\\\)")
            .hasMatch(element.directory))
        .forEach((element) {
      List<String> pos = element.directory.split('\\');
      if (!current['subkeys'].containsKey(pos.last)) {
        current['subkeys'][pos.last] = {
          'directory': element.directory,
          'values': {},
          'subkeys': {},
        };
      }
      current['subkeys'][pos.last]['values'][element.key] = {
        'type': element.type,
        'data': element.value,
      };
    });
    onRegistryDataChanged();
  }

  bool getIsFetched() {
    return isFetched;
  }

  void setAddCount(Function addCount) {
    this.addCount = addCount;
  }

  fetchAllRegistryData() async {
    // db.getRegistryList().then((value) => {for (var data in value) {}});

    if (_RegistryValues.isNotEmpty) {
      return _RegistryValues;
    }
    var registryNames = [
      'currentConfig',
      'classesRoot',
      'currentUser',
      'localMachine',
      'allusers',
    ];
    // var futures = registryNames
    //     .map(fetchRegistryData)
    //     .toList(); // registryNames의 values와 subkeys를 가져옴
    for (var regName in registryNames) {
      print("current registryName : $regName");
      Map<String, dynamic> registryData =
          await compute(fetchRegistryData, regName);
      _RegistryValues[regName] = registryData;
      addCount(registryData.length);
      onRegistryDataChanged();
      db.insertRegistryList(toDBRegistry(registryData));
    }

    isFetched = true;
    // _futureRegistryValues = await compute(Future.wait, futures);
    return; // 모든 registryName의 values와 subkeys를 가져옴
  }

  List<REGISTRY> toDBRegistry(Map<String, dynamic> registry) {
    List<REGISTRY> registryList = [];
    registry['values'].forEach((key, value) {
      registryList.add(REGISTRY(
        key: key,
        directory: registry['directory'],
        value: value['data'],
        type: value['type'],
      ));
    });
    if (registry['subkeys'].isNotEmpty) {
      registry['subkeys'].forEach((key, subkey) {
        registryList.addAll(toDBRegistry(subkey));
      });
    }

    return registryList;
  }
}

List<RegistryMapping> mappings = [
  // key와 registryType 매핑
  RegistryMapping('classesRoot', RegistryHive.classesRoot, HKEY_CLASSES_ROOT),
  RegistryMapping('currentUser', RegistryHive.currentUser, HKEY_CURRENT_USER),
  RegistryMapping(
      'localMachine', RegistryHive.localMachine, HKEY_LOCAL_MACHINE),
  RegistryMapping('allUsers', RegistryHive.allUsers, HKEY_USERS),
  RegistryMapping(
      'currentConfig', RegistryHive.currentConfig, HKEY_CURRENT_CONFIG),
];
Future<Map<String, dynamic>> fetchRegistryData(String registryName) async {
  for (var mapping in mappings) {
    // mapping된 registryName이 있으면 해당 registryName의 values와 subkeys를 가져옴
    if (registryName == mapping.registryName) {
      // print("current registryName : ${mapping.registryHive.name}");
      var key = RegistryKey(mapping.registryKey);
      Map<String, dynamic> rootValues = {}; //registryRoot
      Map<String, dynamic> values = {
        // values가 없으면 default
        '(Default)': {
          'type': 'REG_SZ',
          'data': '(No Data)',
        }
      };
      if (key.values.isNotEmpty) {
        // key의 values가 있으면 values에 추가
        for (var value in key.values) {
          rootValues[value.name] = {
            'type': value.type.win32Type,
            'data': value.data,
          };
          values = rootValues;
        }
      }
      Map<String, dynamic> subkeys = {};
      for (var subkey in key.subkeyNames) {
        // key의 subkey가 있으면 subkey의 values와 subkeys를 가져옴
        subkeys[subkey] =
            await fetchRegistryValues(mapping.registryHive, subkey);
      }
      key.close();
      return {
        // registryName, values, subkeys를 반환
        'registryName': mapping.registryName,
        'directory': mapping.registryName,
        'values': values,
        'subkeys': subkeys,
      };
    }
  }

  return {
    // 예외처리
    'registryName': registryName,
    'directory': registryName,
    'values': {
      '(Default)': {
        'type': 'REG_SZ',
        'data': '(No Data)',
      }
    },
    'subkeys': {},
  };
}

Future<Map<String, dynamic>> fetchRegistryValues(
    // key와 path를 받아서 해당 key의 values와 subkeys를 가져옴
    RegistryHive key,
    String path) async {
  try {
    final regkey = Registry.openPath(key, path: path);

    Map<String, dynamic> subkeys = {};
    for (var subkey in regkey.subkeyNames) {
      // subkey가 있으면 subkey의 values와 subkeys를 가져옴
      try {
        subkeys[subkey] = await fetchRegistryValues(key, '$path\\$subkey');
      } catch (e) {
        // 엑세스관련 예외처리
        if (e is WindowsException) {
          // print('$key에서 WindowsException 발생: ${e.message}');
          continue;
        } else {
          rethrow;
        }
      }
    }
    Map<String, dynamic> values = {};
    if (regkey.values.isNotEmpty) {
      for (var reg in regkey.values) {
        // values가 있으면 values에 추가
        values[reg.name != '' ? reg.name.toString() : '(Default)'] = {
          'type': reg.type.win32Type != null
              ? reg.type.win32Type.toString()
              : 'Default type',
          'data': reg.data != null ? reg.data.toString() : '(No Data)',
        };
      }
    } else {
      // values가 없으면 default
      values['(Default)'] = {
        'type': 'REG_SZ',
        'data': '(No Data)',
      };
    }
    return {
      // key의 registryName, values, subkeys를 반환
      'registryName': path.split('\\').last,
      'directory': '${key.name}\\$path',
      'values': values,
      'subkeys': subkeys,
    };
  } on WindowsException catch (e) {
    // 엑세스관련 예외처리
    // print('$key에서 WindowsException 발생: ${e.message}');
    return {
      'registryName': path.split('\\').last,
      'directory': '$key\\$path',
      'values': {
        '(Default)': {
          'type': 'REG_SZ',
          'data': '(No Data)',
        },
      },
      'subkeys': {},
    };
  }
}

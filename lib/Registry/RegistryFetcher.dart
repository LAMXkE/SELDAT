import 'dart:collection';

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
  Future<List<Map<String, dynamic>>>? _futureRegistryValues;
  DatabaseManager db;

  // Constructor
  RegistryFetcher(this.db) {
    // Initialize your class here
  }

  bool getIsFetched() {
    return isFetched;
  }

  void setAddCount(Function addCount) {
    this.addCount = addCount;
  }

  Future<List<Map<String, dynamic>>> fetchAllRegistryData() async {
    // db.getRegistryList().then((value) => {for (var data in value) {}});

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
        // print("current registryName : ${mapping.registryHive.name}");
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
            db.insertRegistry(registry(
                directory: mapping.registryName,
                key: value.name,
                value: value.data.toString(),
                type: value.type.win32Type.toString()));
            values = rootValues;
          }
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
            // print('$key에서 WindowsException 발생: ${e.message}');
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
      // print('$key에서 WindowsException 발생: ${e.message}');
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
}

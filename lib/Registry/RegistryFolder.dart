import 'dart:async';
import 'dart:math';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'dart:convert';
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:win32_registry/win32_registry.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// void main() async {
//   runApp(const App());
// }

class RegistryFolderViewer extends StatelessWidget {
  const RegistryFolderViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('HKEY_LOCAL_MACHINE'),
        ),
        body: FutureBuilder(
          future: () async {
            const key = RegistryKey(HKEY_LOCAL_MACHINE);
            var futures = <Future>[];
            for (var subkey in key.subkeyNames) {
              futures.add(fetchRegistryValues(subkey));
            }
            return await Future.wait(futures);
          }(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              // snapshot.data는 이제 Future의 결과 리스트입니다.
              return ListView(
                children: snapshot.data
                    .map<Widget>((data) => buildRegistryTile(data))
                    .toList(),
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildRegistryTile(Map<String, dynamic> registry) {
    return ExpansionTile(
      title: Text(registry['registryName']),
      children: <Widget>[
        ...buildRegistryValues(registry['values']).map((widget) {
          return Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: widget,
          );
        }),
        ...registry['subkeys'].map<Widget>((subkey) {
          return Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: buildRegistryTile(subkey),
          );
        }).toList(),
      ],
    );
  }

  List<Widget> buildRegistryValues(Map<String, dynamic> values) {
    List<Widget> widgets = [];
    widgets.add(
      ListTile(
        title: const Text('Directory'),
        subtitle: Text(values['directory']),
      ),
    );
    for (var value in values['value']) {
      widgets.add(
        ListTile(
          title: const Text("Value"), //Text("Name :  ${value['name']}"),
          subtitle: Text(
              'Name :  ${value['name']}  |  Type :  ${value['type']}  |  Data :  ${value['data']}'),
        ),
      );
    }
    return widgets;
  }

  Future<Map<String, dynamic>> fetchRegistryValues(String path) async {
    try {
      final regkey = Registry.openPath(RegistryHive.localMachine, path: path);
      List<Map<String, dynamic>> subkeys = [];
      for (var subkey in regkey.subkeyNames) {
        try {
          subkeys.add(await fetchRegistryValues('$path\\$subkey'));
        } catch (e) {
          if (e is WindowsException) {
            print('WindowsException 발생: ${e.message}');
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
            'name': reg.name != '' ? reg.name.toString() : 'Default',
            'type': reg.type.win32Type != null
                ? reg.type.win32Type.toString()
                : 'Default type',
            'data': reg.data != null ? reg.data.toString() : '',
          });
        }
      } else {
        values.add({
          'name': 'Default',
          'type': 'REG_SZ',
          'data': '',
        });
      }
      return {
        'registryName': path.split('\\').last,
        'values': {
          'directory': path,
          'value': values,
        },
        'subkeys': subkeys,
      };
    } on WindowsException catch (e) {
      print('WindowsException 발생: ${e.message}');
      return {
        'registryName': path.split('\\').last,
        'values': {
          'directory': path,
          'value': [],
        },
        'subkeys': [],
      };
    }
  }
}

import 'dart:async';
import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:seldat/Registry/RegistryFetcher.dart';
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

class RegistryFolderViewer extends StatefulWidget {
  final RegistryFetcher registryFetcher;
  const RegistryFolderViewer({super.key, required this.registryFetcher});

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
      _futureRegistryValues = widget.registryFetcher
          .fetchAllRegistryData(); // Call the function here
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
                _futureRegistryValues =
                    widget.registryFetcher.fetchAllRegistryData();
              });
            },
          ),
        ],
      ),
    );
  }
}

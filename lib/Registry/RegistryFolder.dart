import 'dart:async';
import 'dart:math';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

class RegistryFolderViewerOfHkeyClassesRoot extends StatefulWidget {
  const RegistryFolderViewerOfHkeyClassesRoot({super.key});

  @override
  _RegistryFolderViewerOfHkeyClassesRootState createState() =>
      _RegistryFolderViewerOfHkeyClassesRootState();
}

class RegistryFolderViewerOfHkeyCurrentUser extends StatefulWidget {
  const RegistryFolderViewerOfHkeyCurrentUser({super.key});

  @override
  _RegistryFolderViewerOfHkeyCurrentUserState createState() =>
      _RegistryFolderViewerOfHkeyCurrentUserState();
}

class RegistryFolderViewerOfHkeyLocalMachine extends StatefulWidget {
  const RegistryFolderViewerOfHkeyLocalMachine({super.key});

  @override
  _RegistryFolderViewerOfHkeyLocalMachineState createState() =>
      _RegistryFolderViewerOfHkeyLocalMachineState();
}

class RegistryFolderViewerOfHkeyUsers extends StatefulWidget {
  const RegistryFolderViewerOfHkeyUsers({super.key});

  @override
  _RegistryFolderViewerOfHkeyUsersState createState() =>
      _RegistryFolderViewerOfHkeyUsersState();
}

class RegistryFolderViewerOfHkeyCurrentConfig extends StatefulWidget {
  const RegistryFolderViewerOfHkeyCurrentConfig({super.key});

  @override
  _RegistryFolderViewerOfHkeyCurrentConfigState createState() =>
      _RegistryFolderViewerOfHkeyCurrentConfigState();
}

class _RegistryFolderViewerOfHkeyClassesRootState
    extends State<RegistryFolderViewerOfHkeyClassesRoot> {
  Future<List<Map<String, dynamic>>>? _futureRegistryValues;

  @override
  void initState() {
    super.initState();
    _futureRegistryValues = fetchRegistryValue();
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValue() async {
    if (_futureRegistryValues != null) {
      return _futureRegistryValues!;
    }
    const key = RegistryKey(HKEY_CLASSES_ROOT);
    var futures = <Future<List<Map<String, dynamic>>>>[];
    try {
      for (var subkey in key.subkeyNames) {
        futures.add(fetchRegistryValues(subkey));
      }
      var results = await Future.wait(futures);
      _futureRegistryValues = Future.value(results.expand((x) => x).toList());
    } finally {
      key.close();
    }
    return _futureRegistryValues!;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: 1,
          itemBuilder: (context, index) {
            return ExpansionTile(
              title: const Text('HKEY_CLASSES_ROOT'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15.0, 1.0, 1.0, 1),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _futureRegistryValues,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return buildErrorWidget(snapshot.error);
                      } else {
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 100000),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data?.length ?? 0,
                            itemBuilder: (context, index) {
                              return buildRegistryTile(snapshot.data![index]);
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
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
      widgets.add(buildListTile("Value",
          'Name :  ${value['name'].toString()}  |  Type :  ${value['type'].toString()}  |  Data :  ${value['data'].toString()}'));
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
                _futureRegistryValues = fetchRegistryValue();
              });
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValues(String path) async {
    try {
      final regkey = Registry.openPath(RegistryHive.classesRoot, path: path);
      List<Map<String, dynamic>> subkeys = [];
      for (var subkey in regkey.subkeyNames) {
        try {
          subkeys.addAll(await fetchRegistryValues('$path\\$subkey'));
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
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_CLASSES_ROOT\\$path',
            'value': values,
          },
          'subkeys': subkeys,
        }
      ];
    } on WindowsException catch (e) {
      print('WindowsException 발생: ${e.message}');
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_CLASSES_ROOT\\$path',
            'value': [],
          },
          'subkeys': [],
        }
      ];
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////

class _RegistryFolderViewerOfHkeyCurrentUserState
    extends State<RegistryFolderViewerOfHkeyCurrentUser> {
  Future<List<Map<String, dynamic>>>? _futureRegistryValues;

  @override
  void initState() {
    super.initState();
    _futureRegistryValues = fetchRegistryValue();
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValue() async {
    if (_futureRegistryValues != null) {
      return _futureRegistryValues!;
    }
    const key = RegistryKey(HKEY_CURRENT_USER);
    var futures = <Future<List<Map<String, dynamic>>>>[];
    try {
      for (var subkey in key.subkeyNames) {
        futures.add(fetchRegistryValues(subkey));
      }
      var results = await Future.wait(futures);
      _futureRegistryValues = Future.value(results.expand((x) => x).toList());
    } finally {
      key.close();
    }
    return _futureRegistryValues!;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: 1,
          itemBuilder: (context, index) {
            return ExpansionTile(
              title: const Text('HKEY_CURRENT_USER'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15.0, 1.0, 1.0, 1),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _futureRegistryValues,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return buildErrorWidget(snapshot.error);
                      } else {
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 100000),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data?.length ?? 0,
                            itemBuilder: (context, index) {
                              return buildRegistryTile(snapshot.data![index]);
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
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
      widgets.add(buildListTile("Value",
          'Name :  ${value['name'].toString()}  |  Type :  ${value['type'].toString()}  |  Data :  ${value['data'].toString()}'));
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
                _futureRegistryValues = fetchRegistryValue();
              });
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValues(String path) async {
    try {
      final regkey = Registry.openPath(RegistryHive.currentUser, path: path);
      List<Map<String, dynamic>> subkeys = [];
      for (var subkey in regkey.subkeyNames) {
        try {
          subkeys.addAll(await fetchRegistryValues('$path\\$subkey'));
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
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_CURRENT_USER\\$path',
            'value': values,
          },
          'subkeys': subkeys,
        }
      ];
    } on WindowsException catch (e) {
      print('WindowsException 발생: ${e.message}');
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_CURRENT_USER\\$path',
            'value': [],
          },
          'subkeys': [],
        }
      ];
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////

class _RegistryFolderViewerOfHkeyLocalMachineState
    extends State<RegistryFolderViewerOfHkeyLocalMachine> {
  Future<List<Map<String, dynamic>>>? _futureRegistryValues;

  @override
  void initState() {
    super.initState();
    _futureRegistryValues = fetchRegistryValue();
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValue() async {
    if (_futureRegistryValues != null) {
      return _futureRegistryValues!;
    }
    const key = RegistryKey(HKEY_LOCAL_MACHINE);
    var futures = <Future<List<Map<String, dynamic>>>>[];
    try {
      for (var subkey in key.subkeyNames) {
        futures.add(fetchRegistryValues(subkey));
      }
      var results = await Future.wait(futures);
      _futureRegistryValues = Future.value(results.expand((x) => x).toList());
    } finally {
      key.close();
    }
    return _futureRegistryValues!;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: 1,
          itemBuilder: (context, index) {
            return ExpansionTile(
              title: const Text('HKEY_LOCAL_MACHINE'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15.0, 1.0, 1.0, 1.0),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _futureRegistryValues,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return buildErrorWidget(snapshot.error);
                      } else {
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 100000),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data?.length ?? 0,
                            itemBuilder: (context, index) {
                              return buildRegistryTile(snapshot.data![index]);
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
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
      widgets.add(buildListTile("Value",
          'Name :  ${value['name'].toString()}  |  Type :  ${value['type'].toString()}  |  Data :  ${value['data'].toString()}'));
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
                _futureRegistryValues = fetchRegistryValue();
              });
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValues(String path) async {
    try {
      final regkey = Registry.openPath(RegistryHive.localMachine, path: path);
      List<Map<String, dynamic>> subkeys = [];
      for (var subkey in regkey.subkeyNames) {
        try {
          subkeys.addAll(await fetchRegistryValues('$path\\$subkey'));
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
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_LOCAL_MACHINE\\$path',
            'value': values,
          },
          'subkeys': subkeys,
        }
      ];
    } on WindowsException catch (e) {
      print('WindowsException 발생: ${e.message}');
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_LOCAL_MACHINE\\$path',
            'value': [],
          },
          'subkeys': [],
        }
      ];
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////

class _RegistryFolderViewerOfHkeyUsersState
    extends State<RegistryFolderViewerOfHkeyUsers> {
  Future<List<Map<String, dynamic>>>? _futureRegistryValues;

  @override
  void initState() {
    super.initState();
    _futureRegistryValues = fetchRegistryValue();
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValue() async {
    if (_futureRegistryValues != null) {
      return _futureRegistryValues!;
    }
    const key = RegistryKey(HKEY_USERS);
    var futures = <Future<List<Map<String, dynamic>>>>[];
    try {
      for (var subkey in key.subkeyNames) {
        futures.add(fetchRegistryValues(subkey));
      }
      var results = await Future.wait(futures);
      _futureRegistryValues = Future.value(results.expand((x) => x).toList());
    } finally {
      key.close();
    }
    return _futureRegistryValues!;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: 1,
          itemBuilder: (context, index) {
            return ExpansionTile(
              title: const Text('HKEY_USERS'),
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _futureRegistryValues,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return buildErrorWidget(snapshot.error);
                    } else {
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 100000),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data?.length ?? 0,
                          itemBuilder: (context, index) {
                            return buildRegistryTile(snapshot.data![index]);
                          },
                        ),
                      );
                    }
                  },
                ),
              ],
            );
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
      widgets.add(buildListTile("Value",
          'Name :  ${value['name'].toString()}  |  Type :  ${value['type'].toString()}  |  Data :  ${value['data'].toString()}'));
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
                _futureRegistryValues = fetchRegistryValue();
              });
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValues(String path) async {
    try {
      final regkey = Registry.openPath(RegistryHive.allUsers, path: path);
      List<Map<String, dynamic>> subkeys = [];
      for (var subkey in regkey.subkeyNames) {
        try {
          subkeys.addAll(await fetchRegistryValues('$path\\$subkey'));
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
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_USERS\\$path',
            'value': values,
          },
          'subkeys': subkeys,
        }
      ];
    } on WindowsException catch (e) {
      print('WindowsException 발생: ${e.message}');
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_USERS\\$path',
            'value': [],
          },
          'subkeys': [],
        }
      ];
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////

class _RegistryFolderViewerOfHkeyCurrentConfigState
    extends State<RegistryFolderViewerOfHkeyCurrentConfig> {
  Future<List<Map<String, dynamic>>>? _futureRegistryValues;

  @override
  void initState() {
    super.initState();
    _futureRegistryValues = fetchRegistryValue();
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValue() async {
    if (_futureRegistryValues != null) {
      return _futureRegistryValues!;
    }
    const key = RegistryKey(HKEY_CURRENT_CONFIG);
    var futures = <Future<List<Map<String, dynamic>>>>[];
    try {
      for (var subkey in key.subkeyNames) {
        futures.add(fetchRegistryValues(subkey));
      }
      var results = await Future.wait(futures);
      _futureRegistryValues = Future.value(results.expand((x) => x).toList());
    } finally {
      key.close();
    }
    return _futureRegistryValues!;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: 1,
          itemBuilder: (context, index) {
            return ExpansionTile(
              title: const Text('HKEY_CURRENT_CONFIG'),
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _futureRegistryValues,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return buildErrorWidget(snapshot.error);
                    } else {
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 100000),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data?.length ?? 0,
                          itemBuilder: (context, index) {
                            return buildRegistryTile(snapshot.data![index]);
                          },
                        ),
                      );
                    }
                  },
                ),
              ],
            );
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
      widgets.add(buildListTile("Value",
          'Name :  ${value['name'].toString()}  |  Type :  ${value['type'].toString()}  |  Data :  ${value['data'].toString()}'));
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
                _futureRegistryValues = fetchRegistryValue();
              });
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchRegistryValues(String path) async {
    try {
      final regkey = Registry.openPath(RegistryHive.currentConfig, path: path);
      List<Map<String, dynamic>> subkeys = [];
      for (var subkey in regkey.subkeyNames) {
        try {
          subkeys.addAll(await fetchRegistryValues('$path\\$subkey'));
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
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_CURRENT_CONFIG\\$path',
            'value': values,
          },
          'subkeys': subkeys,
        }
      ];
    } on WindowsException catch (e) {
      print('WindowsException 발생: ${e.message}');
      return [
        {
          'registryName': path.split('\\').last,
          'values': {
            'directory': 'HKEY_CURRENT_CONFIG\\$path',
            'value': [],
          },
          'subkeys': [],
        }
      ];
    }
  }
}

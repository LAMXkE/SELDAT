import 'dart:async';
import 'dart:isolate';
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
  bool _isDataFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      _isDataFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.registryFetcher.onRegistryDataChanged = () {
      setState(() {
        print("Registry Data Changed");
      });
    };
    return SingleChildScrollView(
      child: buildRegistryTile(widget.registryFetcher.getRegistryData()),
    );
  }

  Widget buildRegistryTile(Map<String, dynamic> registry) {
    if (registry.isEmpty) {
      return const Center(
        child: Text("No Registry data found"),
      );
    }
    List<Padding> widgets = [];

    // registryName, values, subkeys를 받아서 ExpansionTile로 반환
    registry.forEach((key, value) {
      return widgets.add(Padding(
        padding: const EdgeInsets.only(left: 10),
        child: ExpansionTile(
          title: Text('ㄴ $key'),
          onExpansionChanged: (isExpanded) {
            if (isExpanded &&
                (value['values'].isEmpty || value['subkeys'].isEmpty)) {
              widget.registryFetcher.fillChild(value);
            }
          },
          children: [
            CustomScrollView(
              shrinkWrap: true,
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    buildChildren(value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ));
    });

    return ListView(
      shrinkWrap: true,
      children: widgets,
    );
  }

  List<Widget> buildChildren(Map<String, dynamic> registry) {
    List<Widget> widgets = [];
    widgets.add(buildListTile('Directory', registry['directory']));
    registry['values'].forEach((key, value) {
      widgets.add(buildListTile("Name :  ${key.toString()}",
          'Type :  ${value['type'].toString()}  |  Data :  ${value['data'].toString()}'));
    });
    registry['subkeys'].forEach((key, value) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: ExpansionTile(
            title: Text('ㄴ $key'),
            onExpansionChanged: (isExpanded) {
              if (isExpanded &&
                  (value['values'].isEmpty || value['subkeys'].isEmpty)) {
                widget.registryFetcher.fillChild(value);
              }
            },
            children: [
              CustomScrollView(
                shrinkWrap: true,
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(
                      buildChildren(value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  ListTile buildListTile(String title, String subtitle) {
    // title과 subtitle을 받아서 ListTile로 반환
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

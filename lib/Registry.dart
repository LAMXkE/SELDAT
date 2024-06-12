import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:seldat/Registry/RegistryDirectory.dart';
import 'package:seldat/Registry/RegistryFetcher.dart';
import 'package:seldat/Registry/RegistryFolder.dart';
import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

class RegistryUI extends StatefulWidget {
  final RegistryFetcher registryFetcher;
  const RegistryUI({super.key, required this.registryFetcher});

  @override
  State<RegistryUI> createState() => _RegistryUIState();
}

class _RegistryUIState extends State<RegistryUI>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic> selected = {};
  int selectedIdx = 0;
  Map<String, dynamic> registryDatas = {};
  List<REGISTRY> modifiedRegistryDatas = [];

  late Future registryFuture;

  void setSelected(Map<String, dynamic> selected) {
    setState(() {
      this.selected = selected;
    });
  }

  void setSelectedIdx(int idx) {
    setState(() {
      selectedIdx = idx;
    });
  }

  @override
  void initState() {
    super.initState();
    print("Registry UI");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Row(
      children: [
        Expanded(
          // RegistryFolderViewer() 위젯의 높이를 건드리지 않고 화면을 분할하기 위해 Expanded 위젯 사용
          child: Align(
            alignment: Alignment.topCenter,
            child:
                RegistryFolderViewer(registryFetcher: widget.registryFetcher),
          ),
        ),
        Expanded(child: modifiedRegistryView()),
      ],
    );
  }

  Widget modifiedRegistryView() {
    if (widget.registryFetcher.Modified.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 100.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No Malicious Registry Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        const Text(
          'Malicious Registry Data',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.registryFetcher.Modified.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(widget.registryFetcher.Modified[index].directory),
                subtitle: Text(widget.registryFetcher.Modified[index].value),
              );
            },
          ),
        ),
      ],
    );
  }
}

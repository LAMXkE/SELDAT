import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
        const Expanded(
          child: Center(
            child: Text('Empty Registry Data'),
          ),
        ),
      ],
    );
  }
}

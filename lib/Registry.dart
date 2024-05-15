import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:seldat/Registry/RegistryDirectory.dart';
import 'package:seldat/Registry/RegistryFetcher.dart';
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
    return Column(
      children: [
        Row(children: [
          Column(
            children: [
              SizedBox(
                  height: 400,
                  child: RegistryDirectory(
                      directory: widget.registryFetcher.getRegistry(),
                      selectReg: setSelected,
                      selectIdx: setSelectedIdx)),
              const SizedBox(
                height: 40,
                width: 300,
              ),
              const Text("Registry data place holder")
            ],
          ),
        ]),
      ],
    );
  }
}

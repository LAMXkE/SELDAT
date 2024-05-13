import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:seldat/Registry/RegistryDirectory.dart';
import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

class RegistryUI extends StatefulWidget {
  const RegistryUI({super.key});

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

  Future fetchRegistryValues(String curKey, Map<String, dynamic> regCur) async {
    try {
      Queue<String> regQueue = Queue();
      RegistryKey reg =
          Registry.openPath(RegistryHive.localMachine, path: curKey);
      for (var reg in reg.values) {
        setState(() {
          regCur[reg.name] = reg.data;
        });
      }
      Iterable<String> subkeys = reg.subkeyNames;
      for (var element in subkeys) {
        regCur[element] = <String, dynamic>{};
        regQueue.add(element);
      }
      reg.close();

      while (regQueue.isNotEmpty) {
        String cur = regQueue.removeFirst();
        if (curKey == '') {
          Future.delayed(const Duration(milliseconds: 300))
              .then((value) => fetchRegistryValues(cur, regCur[cur]));
        } else {
          Future.delayed(const Duration(milliseconds: 400)).then(
              (value) => fetchRegistryValues('$curKey\\$cur', regCur[cur]));
        }
      }
    } on WindowsException catch (e) {
      print("Error! $e");
    }
    return regCur;
  }

  @override
  void initState() {
    super.initState();
    print("Registry UI");
    registryFuture = fetchRegistryValues('', registryDatas);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Row(children: [
          Column(
            children: [
              FutureBuilder(
                  future: registryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData == false) {
                      print("Fetching registry data...");
                      return const Text("Fetching registry data...");
                    } else {
                      print(selected[selected.keys.elementAt(selectedIdx)]);
                      return RegistryDirectory(
                          directory: registryDatas,
                          selectReg: setSelected,
                          selectIdx: setSelectedIdx);
                    }
                  }),
              // RegistryDirectory(directory: registryDatas, selected: selected),
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

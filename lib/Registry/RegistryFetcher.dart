import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

class RegistryFetcher {
  // Add your class members and methods here
  Map<String, dynamic> registryDatas = {};
  Function addCount = () {};
  bool isFetched = false;

  // Constructor
  RegistryFetcher() {
    // Initialize your class here
  }

  bool getIsFetched() {
    return isFetched;
  }

  void setAddCount(Function addCount) {
    this.addCount = addCount;
  }

  // Example method
  void fetchRegistry() {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('Caught an error: $details');
    };
    fetchRegistryValues('', registryDatas);
    isFetched = true;
  }

  Map<String, dynamic> getRegistry() {
    return registryDatas;
  }

  Future fetchRegistryValues(String curKey, Map<String, dynamic> regCur) async {
    try {
      Queue<String> regQueue = Queue();
      RegistryKey regkey =
          Registry.openPath(RegistryHive.localMachine, path: curKey);
      for (var reg in regkey.values) {
        regCur[reg.name] = reg.data;
      }
      Iterable<String> subkeys = regkey.subkeyNames;
      for (var element in subkeys) {
        regCur[element] = <String, dynamic>{};
        regQueue.add(element);
      }
      regkey.close();

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
      print("Error?! $e");
    }
    return regCur;
  }
}

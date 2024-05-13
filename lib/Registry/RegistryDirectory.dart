import 'package:flutter/material.dart';
import 'package:win32/winsock2.dart';

class RegistryDirectory extends StatelessWidget {
  final Map<String, dynamic> directory;
  final Function(Map<String, dynamic>) selectReg;
  final Function(int) selectIdx;

  const RegistryDirectory(
      {super.key,
      required this.directory,
      required this.selectReg,
      required this.selectIdx});

  Widget _buildNestedList(Map<String, dynamic> directory) {
    Iterable<String> folderName = directory.keys;
    // for (var element in folderName) {
    //   if (directory[element] is Map<String, dynamic>) {
    //     print("directory $element");
    //     _buildNestedList(directory[element]);
    //   } else {
    //     print("not directory ${directory[element]}");
    //   }
    // }
    // return const Text("data");

    return Container(
      padding: const EdgeInsets.all(0.0),
      margin: const EdgeInsets.all(0.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black54,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        child: Wrap(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(0.0),
              itemCount: directory.length,
              controller: ScrollController(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                if (directory[folderName.elementAt(index)]
                    is Map<String, dynamic>) {
                  // print(folderName.elementAt(index));
                  return ExpansionTile(
                      onExpansionChanged: (expanded) {
                        selectReg(directory);
                      },
                      childrenPadding: const EdgeInsets.all(0.0),
                      title: Text(folderName.elementAt(index)),
                      children: [
                        _buildNestedList(
                            directory[folderName.elementAt(index)]),
                      ]);
                }
                return ListTile(
                  title: Text(folderName.elementAt(index)),
                  onTap: () {
                    selectIdx(index);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 500,
      child: _buildNestedList(directory),
    );
  }
}

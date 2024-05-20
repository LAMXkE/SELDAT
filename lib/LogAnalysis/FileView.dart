import 'dart:io';
import 'package:flutter/material.dart';

class FileView extends StatelessWidget {
  final List files;
  final Function setSelected;
  final int selected;

  const FileView(
      {super.key,
      required this.files,
      required this.setSelected,
      required this.selected});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (con, index) {
        return ListTile(
          title: Text(
            // Uri.decodeFull(
            files[index]
                .path
                .toString()
                .split('\\')
                .last
                .replaceAll(".csv", "")
                .replaceAll("%4", "/"),
            // ),
            style:
                const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
          ),
          onTap: () {
            setSelected(files[index].path.toString(), index);
          },
          selected: index == selected,
          selectedTileColor: Colors.blue[100],
        );
      },
    );
  }
}

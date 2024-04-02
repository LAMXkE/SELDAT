import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FileView extends StatelessWidget {
  final List<File> files;

  const FileView({required this.files});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(child: Text("Files")),
        Expanded(
          child: ListView.builder(
            itemCount: files.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(files[index].path),
                onTap: () {
                  // Handle file tap event
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

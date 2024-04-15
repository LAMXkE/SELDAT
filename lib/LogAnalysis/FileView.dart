import 'dart:io';
import 'package:flutter/material.dart';

class FileView extends StatelessWidget {
  final List files;

  const FileView({super.key, required this.files});

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
                title: Text(
                  // Uri.decodeFull(
                  files[index]
                      .path
                      .toString()
                      .split('/')
                      .last
                      .replaceAll(".csv", ""),
                  // ),
                  style: const TextStyle(fontSize: 12),
                ),
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

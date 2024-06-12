import 'package:flutter/material.dart';

class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text('Generating Report...', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DashboardSkeleton extends StatelessWidget {
  final Function startAnalysis;
  const DashboardSkeleton({super.key, required this.startAnalysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SizedBox(
        width: 200,
        height: 100,
        child: ElevatedButton(
          onPressed: () {
            startAnalysis();
          },
          child: const Text("Dashboard Skeleton"),
        ),
      ),
    );
  }
}

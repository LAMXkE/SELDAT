import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Artifacts extends StatelessWidget {
  final PieChartData data;
  final int totalArtifactsCount;
  const Artifacts(
      {super.key, required this.data, required this.totalArtifactsCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const Text("Artifacts"),
          Column(
            children: [
              Text("$totalArtifactsCount Artifacts"),
              SizedBox(width: 300, height: 300, child: PieChart(data)),
            ],
          ),
        ],
      ),
    );
  }
}

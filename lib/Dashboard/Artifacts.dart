import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Artifacts extends StatelessWidget {
  final PieChartData data;
  const Artifacts({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const Text("Artifacts"),
          Container(
            child: Column(
              children: [const Text("108223"), PieChart(data)],
            ),
          ),
        ],
      ),
    );
  }
}

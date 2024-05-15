import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:seldat/Dashboard/Artifacts.dart';

class Dashboard extends StatelessWidget {
  final int evtxCount;
  final int regCount;
  final int srumCount;
  final int prefetchCount;
  final int jumplistCount;

  const Dashboard({
    super.key,
    required this.evtxCount,
    required this.regCount,
    required this.srumCount,
    required this.prefetchCount,
    required this.jumplistCount,
  });

  @override
  Widget build(BuildContext context) {
    PieChartData artifactsData = PieChartData(sections: [
      PieChartSectionData(
        color: Colors.red,
        value: evtxCount.toDouble(),
        title: "EventLog",
        radius: 100,
      ),
      PieChartSectionData(
        color: Colors.green,
        value: regCount.toDouble(),
        title: "Registry",
        radius: 100,
      ),
      PieChartSectionData(
        color: Colors.blue,
        value: srumCount.toDouble(),
        title: "SRUM",
        radius: 100,
      ),
      PieChartSectionData(
        color: Colors.yellow,
        value: prefetchCount.toDouble(),
        title: "Prefetch",
        radius: 100,
      ),
      PieChartSectionData(
        color: Colors.purple,
        value: jumplistCount.toDouble(),
        title: "Jumplist",
        radius: 100,
      ),
    ], centerSpaceRadius: 0);

    return Container(
      child: Column(
        children: [
          const Text("Artifacts Analysis"),
          Row(
            children: [
              Artifacts(
                data: artifactsData,
                totalArtifactsCount: evtxCount +
                    regCount +
                    srumCount +
                    prefetchCount +
                    jumplistCount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

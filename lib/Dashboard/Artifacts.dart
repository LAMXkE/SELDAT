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
          const Text(
            "Artifacts",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 71, 71, 71),
            ),
          ),
          Column(
            children: [
              Text(
                "$totalArtifactsCount Artifacts",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 60,
              ),
              SizedBox(
                width: 250,
                height: 250,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 100, 100, 100)
                            .withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 3,
                        offset:
                            const Offset(1, 1), // changes position of shadow
                      ),
                    ],
                  ),
                  child: PieChart(data),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

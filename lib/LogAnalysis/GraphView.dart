import 'dart:ffi';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';

class GraphView extends StatelessWidget {
  const GraphView({super.key, required this.data});

  final List<eventLog> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No Data"));
    }
    // seperate logs with timestamp 1min
    int maxy = 0;
    List<String> timedata = List.empty(growable: true);
    List<bool> anomalydata = List.empty(growable: true);
    List<int> countdata = List.empty(growable: true);
    for (var item in data) {
      if (timedata.isEmpty) {
        timedata.add(item.timestamp.toString().substring(0, 16));
        countdata.add(1);
        anomalydata.add(false);
      } else if (timedata.last == item.timestamp.toString().substring(0, 16)) {
        countdata.last += 1;
        if (item.isMalicious || item.sigmaLevel > 0) {
          anomalydata.last = true;
        }
      } else {
        if (maxy < countdata.last) {
          maxy = countdata.last;
        }
        if (item.isMalicious || item.sigmaLevel > 0) {
          anomalydata.add(true);
        } else {
          anomalydata.add(false);
        }
        timedata.add(item.timestamp.toString().substring(0, 16));
        countdata.add(1);
      }
    }

    if (maxy < countdata.last) {
      maxy = countdata.last;
    }
    List<FlSpot> anomalylist = List.generate(anomalydata.length, (index) {
      if (anomalydata[index]) {
        return FlSpot(index.toDouble(), countdata[index].toDouble());
      }
      return FlSpot(index.toDouble(), 0);
    });

    final chartdata = LineChartData(
      clipData: const FlClipData.all(),
      lineBarsData: [
        LineChartBarData(
          barWidth: 0.3,
          color: Colors.green,
          spots: List.generate(timedata.length, (index) {
            return FlSpot(index.toDouble(), countdata[index].toDouble());
          }),
        ),
        LineChartBarData(
          dotData: FlDotData(checkToShowDot: (spot, barData) {
            return spot.y != 0;
          }),
          color: Colors.red,
          barWidth: 0.0,
          spots: anomalylist,
        )
      ],
      minY: 0,
      maxY: (maxy * 1.3 + 2).round().toDouble(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Transform.rotate(
              angle: -3.14 / 10,
              child: Transform.translate(
                offset: const Offset(0, 20),
                child: Text(
                  timedata[value.toInt()],
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
    );

    return Container(
        padding: const EdgeInsets.fromLTRB(40, 10, 10, 30),
        child: LineChart(chartdata));
  }

  Widget _chart() {
    // return const LineChart();
    return const Text("Chart");
  }

  Widget bottomTitleWidget(double value, TitleMeta meta) {
    return Text(value.toString());
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';

class GraphView extends StatelessWidget {
  const GraphView({super.key, required this.data});

  final PaginatedList<eventLog>? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Center(child: Text("No Data"));
    }

    if (data!.items.isEmpty) {
      return const Center(child: Text("No Data"));
    }
    // seperate logs with timestamp 1min
    int maxy = 0;
    List<String> timedata = List.empty(growable: true);
    List<int> countdata = List.empty(growable: true);
    for (var item in data!.items) {
      if (timedata.isEmpty) {
        timedata.add(item.timestamp.toString().substring(0, 19));
        countdata.add(1);
      } else if (timedata.last == item.timestamp.toString().substring(0, 19)) {
        countdata.last += 1;
      } else {
        if (maxy < countdata.last) {
          maxy = countdata.last;
        }
        timedata.add(item.timestamp.toString().substring(0, 19));
        countdata.add(1);
      }
    }
    print(countdata);
    print(timedata);

    final chartdata = LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(timedata.length, (index) {
            return FlSpot(index.toDouble(), countdata[index].toDouble());
          }),
        ),
      ],
      maxY: maxy.toDouble() + 3,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          axisNameWidget:
              Text("Time ${timedata[0].toString().substring(0, 16)}"),
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) =>
                Text(timedata[value.toInt()].toString().substring(17)),
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
        padding: const EdgeInsets.all(10), child: LineChart(chartdata));
  }

  Widget _chart() {
    // return const LineChart();
    return const Text("Chart");
  }

  Widget bottomTitleWidget(double value, TitleMeta meta) {
    return Text(value.toString());
  }
}

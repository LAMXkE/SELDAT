import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:seldat/Dashboard/Artifacts.dart';
import 'SystemInfoViewer.dart';

class Dashboard extends StatefulWidget {
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
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with AutomaticKeepAliveClientMixin {
  late final SystemInfoViewer _systemInfoViewer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _systemInfoViewer = const SystemInfoViewer();
  }

  @override
  Widget build(BuildContext context) {
    PieChartData artifactsData = PieChartData(sections: [
      PieChartSectionData(
        color: Colors.red,
        value: widget.evtxCount.toDouble(),
        title: "EventLog",
        radius: 100,
      ),
      PieChartSectionData(
        color: Colors.green,
        value: widget.regCount.toDouble(),
        title: "Registry",
        radius: 100,
      ),
      PieChartSectionData(
        color: Colors.blue,
        value: widget.srumCount.toDouble(),
        title: "SRUM",
        radius: 100,
      ),
      PieChartSectionData(
        color: Colors.yellow,
        value: widget.prefetchCount.toDouble(),
        title: "Prefetch",
        radius: 100,
      ),
      PieChartSectionData(
        color: Colors.purple,
        value: widget.jumplistCount.toDouble(),
        title: "Jumplist",
        radius: 100,
      ),
    ], centerSpaceRadius: 0);

    return Container(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text("Artifacts Analysis"),
                Artifacts(
                  data: artifactsData,
                  totalArtifactsCount: widget.evtxCount +
                      widget.regCount +
                      widget.srumCount +
                      widget.prefetchCount +
                      widget.jumplistCount,
                ),
              ],
            ),
          ),
          Expanded(
            child: _systemInfoViewer,
          ),
        ],
      ),
    );
  }
}

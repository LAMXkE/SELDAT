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

    int getArtifactCount(String title) {
      switch (title) {
        case 'EventLog':
          return widget.evtxCount;
        case 'Registry':
          return widget.regCount;
        case 'SRUM':
          return widget.srumCount;
        case 'Prefetch':
          return widget.prefetchCount;
        case 'Jumplist':
          return widget.jumplistCount;
        default:
          return 0;
      }
    }

    return Container(
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(25.0),
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
                  Expanded(
                    child: ListView(
                      children: [
                        for (int i = 0;
                            i < artifactsData.sections.length;
                            i += 2)
                          Row(
                            children: [
                              for (int j = 0; j < 2; j++)
                                if (i + j < artifactsData.sections.length)
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.fromLTRB(
                                          15.0, 8.0, 15.0, 8.0),
                                      padding: const EdgeInsets.fromLTRB(
                                          15.0, 20.0, 15.0, 20.0),
                                      decoration: BoxDecoration(
                                        // border: Border.all(
                                        //     color: Colors.blueAccent),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: Colors
                                            .white, // Set the background color
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromARGB(31, 94, 94,
                                                94), // 그림자의 색상을 설정합니다.
                                            blurRadius:
                                                5.0, // 그림자의 흐림 정도를 설정합니다.
                                            spreadRadius:
                                                1.0, // 그림자의 확산 정도를 설정합니다.
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            artifactsData.sections[i + j].title,
                                            style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 71, 71, 71),
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10.0),
                                          Text(
                                            '${getArtifactCount(artifactsData.sections[i + j].title)}',
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              if (i + 1 >= artifactsData.sections.length &&
                                  artifactsData.sections.length % 2 != 0)
                                Expanded(
                                    child:
                                        Container()), // Add an empty Expanded widget to fill the space
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: _systemInfoViewer,
          ),
        ],
      ),
    );
  }
}

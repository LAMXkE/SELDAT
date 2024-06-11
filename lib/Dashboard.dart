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
  final List<int> loadingStatus;

  const Dashboard({
    super.key,
    required this.evtxCount,
    required this.regCount,
    required this.srumCount,
    required this.prefetchCount,
    required this.jumplistCount,
    required this.loadingStatus,
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
                  Flexible(
                      child: ListView.builder(
                    itemCount: 3, // Adjust as needed.
                    itemBuilder: (context, rowIndex) {
                      return Row(
                        children: List.generate(2, (colIndex) {
                          int index = rowIndex * 2 + colIndex;

                          // Define the titles
                          List<String> titles = [
                            'EventLog',
                            'Registry',
                            'SRUM',
                            'Prefetch',
                            'Jumplist',
                            'Annomaly',
                          ];

                          String title =
                              titles[index]; // Get the title from the list
                          String count =
                              '${getArtifactCount(title)}'; // Get the count for this title

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(
                                  15.0, 8.0, 15.0, 8.0),
                              padding: const EdgeInsets.fromLTRB(
                                  15.0, 20.0, 15.0, 20.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(255, 94, 94, 94),
                                    blurRadius: 5.0,
                                    spreadRadius: 1.0,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 71, 71, 71),
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  if (widget.loadingStatus[index] == 1)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          count,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 10.0),
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      count,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  )),
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

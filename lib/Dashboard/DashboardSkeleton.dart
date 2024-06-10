import 'package:flutter/material.dart';

class DashboardSkeleton extends StatelessWidget {
  final Function startAnalysis;
  final bool loadfromDB;
  final List<int> loadingStatus;
  final List<String> dbList;
  final Function chooseDB;
  final bool chosen;

  const DashboardSkeleton(
      {super.key,
      required this.startAnalysis,
      required this.loadfromDB,
      required this.loadingStatus,
      required this.dbList,
      required this.chooseDB,
      required this.chosen});

  @override
  Widget build(BuildContext context) {
    if (loadfromDB) {
      if (!chosen) {
        return _chooseDBView();
      }
      return _loadFromDBStatusView();
    } else {
      return Container(
        child: Column(
          children: [
            const Text("Artifacts Analysis"),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => startAnalysis(),
                  child: const Text("Start Analysis"),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _chooseDBView() {
    return Column(
      children: [
        const Text("Choose Database"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (String db in dbList)
              ElevatedButton(
                onPressed: () {
                  chooseDB(db);
                },
                child: Text(db),
              ),
          ],
        ),
      ],
    );
  }

  Widget _loadFromDBStatusView() {
    return Center(
      child: Column(
        children: [
          const Text("Loading data from database..."),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Event Logs"),
              loadingStatus[0] == 0
                  ? const Icon(Icons.check)
                  : loadingStatus[0] == 1
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.error),
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Registry"),
            loadingStatus[1] == 0
                ? const Icon(Icons.check)
                : loadingStatus[1] == 1
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.error),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("SRUM"),
            loadingStatus[2] == 0
                ? const Icon(Icons.check)
                : loadingStatus[2] == 1
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.error),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Jump Lists"),
              loadingStatus[3] == 0
                  ? const Icon(Icons.check)
                  : loadingStatus[3] == 1
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.error),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Prefetch"),
              loadingStatus[4] == 0
                  ? const Icon(Icons.check)
                  : loadingStatus[4] == 1
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.error),
            ],
          ),
        ],
      ),
    );
  }
}

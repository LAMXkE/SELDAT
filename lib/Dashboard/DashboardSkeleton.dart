import 'package:flutter/material.dart';

class DashboardSkeleton extends StatefulWidget {
  final Function startAnalysis;
  final bool loadfromDB;
  final List<int> loadingStatus;
  final List<String> dbList;
  final Function chooseDB;
  final bool chosen;
  final Function setLoadfromDB;

  const DashboardSkeleton(
      {super.key,
      required this.startAnalysis,
      required this.loadfromDB,
      required this.loadingStatus,
      required this.dbList,
      required this.chooseDB,
      required this.chosen,
      required this.setLoadfromDB});

  @override
  _DashboardSkeletonState createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton> {
  // Your existing variables and methods here
  bool dialogShown = false;
  @override
  Widget build(BuildContext context) {
    if (widget.loadfromDB && !widget.chosen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: SizedBox(
                width: 700, // Set the width
                height: 400,
                child: SingleChildScrollView(
                  child: _chooseDBView(context),
                ),
              ),
            );
          },
        );
      });
    }

    bool allOne = widget.loadingStatus.every((status) => status == 1);
    // Check if the first 5 values in loadingStatus are 0
    bool firstFiveZero =
        widget.loadingStatus.take(5).every((status) => status == 0);

    if (widget.loadfromDB && widget.chosen) {
      if (allOne && !dialogShown) {
        // If all values are 1 and the dialog has not been shown yet, show the dialog
        dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                child: SizedBox(
                  width: 700, // Set the width
                  height: 400,
                  child: _loadFromDBStatusView(),
                ),
              );
            },
          );
        });
      } else if (firstFiveZero) {
        // If the first 5 values are 0, close the popup
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    }

    if (!widget.loadfromDB) {
      // If loadfromDB is false and chosen is true, show the dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: SizedBox(
                width: 700, // Set the width
                height: 400,
                // padding: const EdgeInsets.all(8.0), // Set the padding
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Set the size to minimum
                      children: [
                        const Text(
                          "Artifacts Analysis",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        const SizedBox(
                          width: 400,
                          child: Text(
                            "If you want to collect and analyze all the artifacts in the new database, press the 'Start Analysis' button below",
                            style: TextStyle(
                              height: 2,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.startAnalysis();
                                  Navigator.pop(
                                      context); // Close the popup when the button is clicked
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                      255,
                                      236,
                                      236,
                                      236), // This is the color of the button
                                ),
                                child: const Text(
                                  "Start Analysis",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      });
    } else if (widget.loadfromDB && firstFiveZero) {
      // If the first 5 values are 0, close the popup
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
    return Container(
        alignment: Alignment.center,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(),
        ));
  }

  Widget _chooseDBView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: IntrinsicWidth(
        child: Column(
          // mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Choose Database",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15.0),
            for (String db in widget.dbList)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          widget.chooseDB(db);
                          Navigator.pop(context); // Close the dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 236, 236,
                              236), // This is the color of the button
                        ),
                        child: Text(db),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5.0),
                ],
              ),
            const SizedBox(height: 10.0),
            ElevatedButton(
                onPressed: () {
                  widget
                      .chooseDB("${DateTime.now().millisecondsSinceEpoch}.db");
                  widget.setLoadfromDB(false);
                  Navigator.pop(context); // Close the dialog
                },
                child: const Text("Fetch New Artifacts")),
          ],
        ),
      ),
    );
  }

  Widget _loadFromDBStatusView() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: SingleChildScrollView(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Loading data from database...",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 25.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Event Logs",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  widget.loadingStatus[0] == 0
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      : widget.loadingStatus[0] == 1
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                          : const Icon(Icons.error),
                ],
              ),
              const SizedBox(height: 10.0),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text(
                  "Registry",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10.0),
                widget.loadingStatus[1] == 0
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                    : widget.loadingStatus[1] == 1
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          )
                        : const Icon(Icons.error),
              ]),
              const SizedBox(height: 10.0),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text(
                  "SRUM",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10.0),
                widget.loadingStatus[2] == 0
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                    : widget.loadingStatus[2] == 1
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          )
                        : const Icon(Icons.error),
              ]),
              const SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Jump Lists",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  widget.loadingStatus[3] == 0
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      : widget.loadingStatus[3] == 1
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                          : const Icon(Icons.error),
                ],
              ),
              const SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Prefetch",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  widget.loadingStatus[4] == 0
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      : widget.loadingStatus[4] == 1
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                          : const Icon(Icons.error),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:seldat/Dashboard/Artifacts.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Column(
        children: [
          Text("Artifacts Analysis"),
          Row(
            children: [Artifacts()],
          )
        ],
      ),
    );
  }
}

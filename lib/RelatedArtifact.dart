import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';

class RelatedArtifactWidget extends StatelessWidget {
  final DatabaseManager databaseManager;
  final DateTime date;
  final String exclude;

  const RelatedArtifactWidget(
      {super.key,
      required this.databaseManager,
      required this.date,
      required this.exclude});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: databaseManager.getRelatedArtifacts(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No related artifacts found.');
        } else {
          return Column(
            children: [
              if (exclude != 'evtx')
                ExpansionTile(
                  enabled: snapshot.data!['evtx'].isNotEmpty,
                  title: Text(
                      'Event Logs (${snapshot.data!['evtx']?.length ?? 0})'),
                  children: [
                    snapshot.data!['evtx'].isEmpty
                        ? const Text('No event logs found.')
                        : SizedBox(
                            width: 400,
                            height: 300.0,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: snapshot.data!['evtx'].length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                    title: Text(snapshot.data!['evtx'][index]
                                            ['event_record_id']
                                        .toString()),
                                    trailing: Text(snapshot.data!['evtx'][index]
                                            ['filename']
                                        .toString()
                                        .split('\\')
                                        .last
                                        .replaceAll('%4', '/')));
                              },
                            ),
                          ),
                  ],
                ),
              if (exclude != 'srum')
                ExpansionTile(
                  title: Text('SRUM (${snapshot.data!['srum']?.length ?? 0})'),
                  enabled: snapshot.data!['srum'].isNotEmpty,
                  children: [
                    snapshot.data!['srum'].isEmpty
                        ? const Text('No SRUM data found.')
                        : SizedBox(
                            width: 400,
                            height: 300.0,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: snapshot.data!['srum'].length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                    title: Text(snapshot.data!['srum'][index]
                                            ['exeinfo']
                                        .toString()),
                                    subtitle: Text(snapshot.data!['srum'][index]
                                            ['Sid']
                                        .toString()),
                                    trailing: Text(snapshot.data!['srum'][index]
                                        ['SidType']));
                              },
                            ),
                          ),
                  ],
                ),
              if (exclude != 'jumplist')
                ExpansionTile(
                  enabled: snapshot.data!['jumplist'].isNotEmpty,
                  title: Text(
                      'Jumplist (${snapshot.data!['jumplist']?.length ?? 0})'),
                  children: [
                    snapshot.data!['jumplist'].isEmpty
                        ? const Text('No jumplists found.')
                        : SizedBox(
                            width: 400,
                            height: 300.0,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: snapshot.data!['jumplist'].length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                    title: Text(snapshot.data!['jumplist']
                                            [index]['filename']
                                        .toString()
                                        .split('\\')
                                        .last
                                        .replaceAll('%4', '/')),
                                    subtitle: Text(snapshot.data!['jumplist']
                                            [index]['fullPath']
                                        .toString()),
                                    trailing: Text(snapshot.data!['jumplist']
                                            [index]['computerName']
                                        .toString()));
                              },
                            ),
                          ),
                  ],
                ),
              if (exclude != 'prefetch')
                ExpansionTile(
                  title: Text(
                      'Prefetch (${snapshot.data!['prefetch']?.length ?? 0})'),
                  enabled: snapshot.data!['prefetch'].isNotEmpty,
                  children: [
                    snapshot.data!['prefetch'].isEmpty
                        ? const Text('No prefetch files found.')
                        : SizedBox(
                            width: 400,
                            height: 300.0,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: snapshot.data!['prefetch'].length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                    title: Text(snapshot.data!['prefetch']
                                            [index]['filename']
                                        .toString()
                                        .split('\\')
                                        .last
                                        .replaceAll('%4', '/')),
                                    subtitle: Text(snapshot.data!['prefetch']
                                            [index]['process_path']
                                        .toString()),
                                    trailing: Text(snapshot.data!['prefetch']
                                                [index]['missingProcess'] ==
                                            1
                                        ? 'Deleted'
                                        : 'Present'));
                              },
                            ),
                          ),
                  ],
                ),
            ],
          );
        }
      },
    );
  }
}

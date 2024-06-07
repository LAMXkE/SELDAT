import 'package:flutter/material.dart';
import 'PrefetchFetcher.dart';
import 'package:flutter/material.dart';

class PrefetchViewer extends StatelessWidget {
  final Future<List<Map<String, String>>> allPrefetchFile =
      PrefetchDataParser().getAllPrefetchFile();

  PrefetchViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: allPrefetchFile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return _PrefetchViewerContent(allPrefetchFile: snapshot.data!);
        }
      },
    );
  }
}

class _PrefetchViewerContent extends StatefulWidget {
  final List<Map<String, String>> allPrefetchFile;

  const _PrefetchViewerContent({required this.allPrefetchFile});

  @override
  _PrefetchViewerContentState createState() => _PrefetchViewerContentState();
}

class _PrefetchViewerContentState extends State<_PrefetchViewerContent> {
  List<Map<String, String>> filteredList = [];
  String filter = '';
  String sortKey = 'filename';
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    filteredList = widget.allPrefetchFile;
  }

  void updateFilter(String value) {
    if (mounted) {
      setState(() {
        filter = value;
        filteredList = widget.allPrefetchFile
            .where((item) => item.values.any((v) => v.contains(filter)))
            .toList();
      });
    }
  }

  void updateSort(String key) {
    if (mounted) {
      setState(() {
        sortKey = key;
        sortAscending = !sortAscending;
        filteredList.sort((a, b) {
          var aValue = a[sortKey];
          var bValue = b[sortKey];
          if (aValue == null) return sortAscending ? -1 : 1;
          if (bValue == null) return sortAscending ? 1 : -1;
          return sortAscending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the flex factors for each key
    final flexFactors = {
      // 컬럼 너비 비율 조정
      'filename': 4,
      'createTime': 5,
      'modifiedTime': 5,
      'fileSize': 3,
      'process_exe': 4,
      'process_path': 6,
      'run_counter': 3,
      'lastRunTime': 7
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 5.0, top: 0.0, right: 1.0, bottom: 1.0),
          child: TextField(
            onChanged: updateFilter,
            decoration: const InputDecoration(labelText: 'Search'),
          ),
        ),
        SizedBox(
          height: 50.0,
          child: Row(
            children: [
              for (var key in flexFactors.keys)
                Expanded(
                  flex: flexFactors[key] ??
                      1, // Provide a default value in case the key is not in the map
                  child: TextButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(key),
                        ),
                        if (sortKey == key) ...[
                          const SizedBox(
                              width:
                                  8.0), // Add space between the text and the icon
                          Icon(
                            sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16.0,
                          ),
                        ],
                      ],
                    ),
                    onPressed: () => updateSort(key),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            addAutomaticKeepAlives: false,
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              var item = filteredList[index];
              return Container(
                height: 60.0,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var key in flexFactors.keys)
                      Expanded(
                        flex: flexFactors[key] ??
                            1, // Provide a default value in case the key is not in the map
                        child: (key == 'run_counter' ||
                                key == 'fileSize' ||
                                key == 'createTime' ||
                                key == 'modifiedTime' ||
                                key == 'lastRunTime')
                            ? Center(
                                child: SelectableText(
                                  item[key] ?? '',
                                  key: ValueKey(key),
                                ),
                              )
                            : Row(
                                children: [
                                  const SizedBox(
                                      width: 8.0), // Add space to the left
                                  Flexible(
                                    child: SelectableText(
                                      item[key] ?? '',
                                      key: ValueKey(key),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

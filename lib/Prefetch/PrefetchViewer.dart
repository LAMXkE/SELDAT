import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';
import 'PrefetchFetcher.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

class PrefetchViewer extends StatefulWidget {
  final Prefetchfetcher prefetchFetcher;

  const PrefetchViewer({super.key, required this.prefetchFetcher});

  @override
  State<PrefetchViewer> createState() => _PrefetchViewerState();
}

class _PrefetchViewerState extends State<PrefetchViewer>
    with AutomaticKeepAliveClientMixin<PrefetchViewer> {
  List<Map<String, dynamic>> fullList = [];
  List<Map<String, dynamic>> filteredList = [];
  String filter = '';
  String sortKey = 'filename';
  bool sortAscending = true;
  String sortColumn = '';
  final _filterController = TextEditingController();
  @override
  bool get wantKeepAlive => true; // Add this line

  @override
  void initState() {
    super.initState();
    fullList = widget.prefetchFetcher.getPrefetchList();
    filteredList = fullList;
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void updateFilter(String value) {
    if (mounted) {
      setState(() {
        filter = value;
        filteredList = fullList
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
          if (key == 'fileSize' || key == 'run_counter') {
            aValue = num.tryParse((aValue ?? '').replaceAll(",", ""));
            bValue = num.tryParse((bValue ?? '').replaceAll(",", ""));
          }
          if (aValue == null) return sortAscending ? -1 : 1;
          if (bValue == null) return sortAscending ? 1 : -1;
          return sortAscending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        });
      });
    }
  }

  Future<Widget> buildTable() async {
    var columnWidths = {
      'filename': 350,
      'createTime': 270,
      'modifiedTime': 270,
      'fileSize': 150,
      'process_exe': 300,
      'process_path': 500,
      'run_counter': 180,
      'lastRunTime0': 250,
      'lastRunTime1': 250,
      'lastRunTime2': 250,
      'lastRunTime3': 250,
      'lastRunTime4': 250,
      'lastRunTime5': 250,
      'lastRunTime6': 250,
      'lastRunTime7': 250,
      'missingProcess': 300,
      // ... 나머지 컬럼의 너비를 설정하세요
    };
    var columns = [
      'filename',
      'createTime',
      'modifiedTime',
      'fileSize',
      'process_exe',
      'process_path',
      'run_counter',
      'missingProcess',
      'lastRunTime0',
      'lastRunTime1',
      'lastRunTime2',
      'lastRunTime3',
      'lastRunTime4',
      'lastRunTime5',
      'lastRunTime6',
      'lastRunTime7',
    ]
        .map((key) => DataColumn2(
              label: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      key,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          wordSpacing: BorderSide.strokeAlignCenter),
                    ),
                    const SizedBox(width: 8.0), // Add space to the right
                    if (sortColumn ==
                        key) // Only show the icon for the sorted column
                      Icon(
                        sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12.0,
                      ),
                  ],
                ),
              ),
              onSort: (columnIndex, ascending) {
                setState(() {
                  sortColumn = key;
                  //sortAscending = ascending;
                });
                updateSort(key);
              },
              fixedWidth: (columnWidths[key] ?? 100)
                  .toDouble(), // Set the fixed width of each column
            ))
        .toList();

    List<DataRow> rows = filteredList.map((map) {
      return DataRow(
        cells: [
          'filename',
          'createTime',
          'modifiedTime',
          'fileSize',
          'process_exe',
          'process_path',
          'run_counter',
          'missingProcess',
          'lastRunTime0',
          'lastRunTime1',
          'lastRunTime2',
          'lastRunTime3',
          'lastRunTime4',
          'lastRunTime5',
          'lastRunTime6',
          'lastRunTime7',
        ].map((key) {
          final value = map.containsKey(key) ? map[key] : 'N/A';
          return DataCell(
            SizedBox(
              width: (columnWidths[key] ?? 100).toDouble(),
              child: SelectableText(
                value ?? 'N/A',
                textAlign: key == 'filename' ||
                        key == 'process_path' ||
                        key == 'lastRunTime'
                    ? TextAlign.left
                    : TextAlign.center,
              ),
            ),
          );
        }).toList(),
      );
    }).toList();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      child: PaginatedDataTable2(
        headingRowDecoration: const BoxDecoration(
          color: Colors.black12,
        ),
        minWidth: MediaQuery.of(context).size.width * 4,
        wrapInCard: false,
        showFirstLastButtons: true,
        fixedLeftColumns: 1,
        rowsPerPage: 100,
        header: TextField(
          controller: _filterController,
          onSubmitted: (value) {
            updateFilter(value);
          },
          decoration: InputDecoration(
            labelText: "Search",
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                updateFilter(_filterController.text);
              },
            ),
          ),
        ),
        columns: columns,
        source: _PrefetchDataSource(rows),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Widget>(
      future: buildTable(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class _PrefetchDataSource extends DataTableSource {
  final List<DataRow> rows;

  _PrefetchDataSource(this.rows);

  @override
  DataRow getRow(int index) {
    return rows[index];
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}

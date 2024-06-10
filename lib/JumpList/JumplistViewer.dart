import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'JumpListFetcher.dart';

class JumplistViewer extends StatefulWidget {
  final JumplistFetcher jumplistFetcher;

  const JumplistViewer({super.key, required this.jumplistFetcher});

  @override
  State<JumplistViewer> createState() => _JumplistViewerContentState();
}

class _JumplistViewerContentState extends State<JumplistViewer>
    with AutomaticKeepAliveClientMixin<JumplistViewer> {
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
    fullList = widget.jumplistFetcher.getJumplistList();
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
          if (key == 'fileSize') {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    var columnWidths = {
      'filename': 500,
      'fullPath': 600,
      'recordTime': 270,
      'createdTime': 270,
      'modifiedTime': 270,
      'accessedTime': 270,
      'fileAttributes': 180,
      'fileSize': 150,
      'entryID': 150,
      'applicationID': 200,
      'fileExtension': 180,
      'computerName': 200,
      'jumplistsFilename': 700,
      // ... 나머지 컬럼의 너비를 설정하세요
    };
    var columns = [
      'filename',
      'fullPath',
      'recordTime',
      'createdTime',
      'modifiedTime',
      'accessedTime',
      'fileAttributes',
      'fileSize',
      'entryID',
      'applicationID',
      'fileExtension',
      'computerName',
      'jumplistsFilename',
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
          'fullPath',
          'recordTime',
          'createdTime',
          'modifiedTime',
          'accessedTime',
          'fileAttributes',
          'fileSize',
          'entryID',
          'applicationID',
          'fileExtension',
          'computerName',
          'jumplistsFilename'
        ].map((key) {
          final value = map.containsKey(key) ? map[key] : 'N/A';
          return DataCell(
            SizedBox(
              width: (columnWidths[key] ?? 100).toDouble(),
              child: SelectableText(
                value ?? 'N/A',
                textAlign: key == 'filename' ||
                        key == 'fullPath' ||
                        key == 'jumplistsFilename'
                    ? TextAlign.left
                    : TextAlign.center,
              ),
            ),
          );
        }).toList(),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
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
          source: _JumplistDataSource(rows),
        ),
      ),
    );
  }
}

class _JumplistDataSource extends DataTableSource {
  final List<DataRow> rows;

  _JumplistDataSource(this.rows);

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

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';

class SrumDataSource extends DataTableSource {
  List<SRUM> srumData = [];
  List<SRUM> filteredData = [];

  SrumDataSource({required this.srumData}) {
    filteredData = srumData;
  }
  void updateFilter(String filter) {
    filteredData = srumData
        .where((item) =>
            item.toMap().values.any((v) => v.toString().contains(filter)))
        .toList();
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= filteredData.length) {
      return null;
    }

    final row = filteredData[index];
    List<String> cells = row.full.replaceAll("`-1`", "``").split("`");
    return DataRow2.byIndex(
      index: index,
      cells: cells.map((cell) => DataCell(Text(cell))).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => filteredData.length;

  @override
  int get selectedRowCount => 0;
}

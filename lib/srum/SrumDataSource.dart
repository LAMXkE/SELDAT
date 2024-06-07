import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';

class SrumDataSource extends DataTableSource {
  List<SRUM> srumData = [];

  SrumDataSource({required this.srumData});

  @override
  DataRow? getRow(int index) {
    if (index >= srumData.length) {
      return null;
    }

    final row = srumData[index];
    List<String> cells = row.full.replaceAll("`-1`", "``").split("`");
    return DataRow2.byIndex(
      index: index,
      cells: cells.map((cell) => DataCell(Text(cell))).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => srumData.length;

  @override
  int get selectedRowCount => 0;
}

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:seldat/DatabaseManager.dart';
import 'package:seldat/srum/SrumDataSource.dart';
import 'package:seldat/srum/SrumFetcher.dart';

class SrumView extends StatefulWidget {
  const SrumView({super.key, required this.srumfetcher});
  final Srumfetcher srumfetcher;

  @override
  State<SrumView> createState() => _SrumViewState();
}

class _SrumViewState extends State<SrumView>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<SrumView> {
  int selectedTabIndex = 0;
  late TabController srumTabController = TabController(length: 7, vsync: this);
  List<bool> loaded = List.filled(7, false);
  List<SRUM> srumData = [];
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    srumData = widget.srumfetcher.getSrumData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (srumData.isEmpty) {
      return const Center(
        child: Text("No SRUM data found"),
      );
    }
    return Column(
      children: [
        TabBar(
          controller: srumTabController,
          isScrollable: true,
          tabs: SRUMType.values.map((type) {
            return Tab(text: widget.srumfetcher.toSrumName(type));
          }).toList(),
        ),
        Expanded(
          child: TabBarView(
              controller: srumTabController,
              children: SRUMType.values.map((type) {
                return FutureBuilder<Widget>(
                  future: srumTable(srumData, type),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return snapshot.data!;
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );
              }).toList()),
        ),
      ],
    );
  }

  Future<Widget> srumTable(List<SRUM> data, SRUMType type) async {
    if (data.isEmpty) {
      return const Center(
        child: Text("No SRUM data found"),
      );
    }
    SrumDataSource datasource = SrumDataSource(
      srumData: data.where((srum) => srum.type == type).toList(),
    );

    return PaginatedDataTable2(
        headingRowDecoration: const BoxDecoration(
          color: Colors.black12,
        ),
        minWidth: MediaQuery.of(context).size.width * 5,
        wrapInCard: false,
        // autoRowsToHeight: true,
        rowsPerPage: 100,
        showFirstLastButtons: true,
        fixedLeftColumns: 2,
        header: TextField(
          onChanged: datasource.updateFilter,
          decoration: const InputDecoration(
            labelText: "Search",
            suffixIcon: Icon(Icons.search),
          ),
        ),
        columns: srumColumns(type)
            .map((column) => DataColumn2(
                fixedWidth: column == "Id"
                    ? 90
                    : column == "Timestamp" || column == "ExeTimeStamp"
                        ? 200
                        : column == "ExeInfo"
                            ? 700
                            : column.toLowerCase().contains("sid") ||
                                    column.contains("Background") ||
                                    column.contains("Foreground")
                                ? 300
                                : column.toLowerCase().contains("interface")
                                    ? 250
                                    : 170,
                label: Text(
                  column,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.center,
                )))
            .toList(),
        source: datasource);
  }

  List<String> srumColumns(SRUMType type) {
    if (type == SRUMType.AppResourceUseInfo) {
      return [
        "Id",
        "Timestamp",
        "ExeInfo",
        "ExeInfoDescription",
        "ExeTimeStamp",
        "SidType",
        "Sid",
        "Username",
        "UserSid",
        "AppId",
        "BackgroundBytesRead",
        "BackgroundBytesWritten",
        "BackgroundContextSwitches",
        "BackgroundCycleTime",
        "BackgroundNumberOfFlushes",
        "BackgroundNumReadOperations",
        "BackgroundNumWriteOperations",
        "FaceTime",
        "ForegroundBytesRead",
        "ForegroundBytesWritten",
        "ForegroundContextSwitches",
        "ForegroundCycleTime",
        "ForegroundNumberOfFlushes",
        "ForegroundNumReadOperations",
        "ForegroundNumWriteOperations"
      ];
    }
    if (type == SRUMType.AppTimeline) {
      return [
        "Id",
        "Timestamp",
        "ExeInfo",
        "ExeInfoDescription",
        "ExeTimeStamp",
        "SIDType",
        "SID",
        "Username",
        "UserSid",
        "AppId",
        "EndTime",
        "DurationMs"
      ];
    }
    if (type == SRUMType.EnergyUsage) {
      //Id	Timestamp	ExeInfo	ExeInfoDescription	ExeTimestamp	SidType	Sid	UserName	UserId	AppId	IsLt	ConfigurationHash	EventTimestamp	StateTransition	ChargeLevel	CycleCount	DesignedCapacity	FullChargedCapacity	ActiveAcTime	ActiveDcTime	ActiveDischargeTime	ActiveEnergy	CsAcTime	CsDcTime	CsDischargeTime	CsEnergy
      return [
        "Id",
        "Timestamp",
        "ExeInfo",
        "ExeInfoDescription",
        "ExeTimeStamp",
        "SidType",
        "Sid",
        "Username",
        "UserSid",
        "AppId",
        "IsLt",
        "ConfigurationHash",
        "EventTimestamp",
        "StateTransition",
        "ChargeLevel",
        "CycleCount",
        "DesignedCapacity",
        "FullChargedCapacity",
        "ActiveAcTime",
        "ActiveDcTime",
        "ActiveDischargeTime",
        "ActiveEnergy",
        "CsAcTime",
        "CsDcTime",
        "CsDischargeTime",
        "CsEnergy"
      ];
    }
    if (type == SRUMType.NetworkConnections) {
      //Id	Timestamp	ExeInfo	ExeInfoDescription	ExeTimestamp	SidType	Sid	UserName	UserId	AppId	ConnectedTime	ConnectStartTime	InterfaceLuid	InterfaceType	L2ProfileFlags	L2ProfileId	ProfileName
      return [
        "Id",
        "Timestamp",
        "ExeInfo",
        "ExeInfoDescription",
        "ExeTimeStamp",
        "SidType",
        "Sid",
        "Username",
        "UserSid",
        "AppId",
        "ConnectedTime",
        "ConnectStartTime",
        "InterfaceLuid",
        "InterfaceType",
        "L2ProfileFlags",
        "L2ProfileId",
        "ProfileName"
      ];
    }

    if (type == SRUMType.NetworkUsage) {
      //Id	Timestamp	ExeInfo	ExeInfoDescription	ExeTimestamp	SidType	Sid	UserName	UserId	AppId	BytesReceived	BytesSent	InterfaceLuid	InterfaceType	L2ProfileFlags	L2ProfileId	ProfileName
      return [
        "Id",
        "Timestamp",
        "ExeInfo",
        "ExeInfoDescription",
        "ExeTimeStamp",
        "SidType",
        "Sid",
        "Username",
        "UserSid",
        "AppId",
        "BytesReceived",
        "BytesSent",
        "InterfaceLuid",
        "InterfaceType",
        "L2ProfileFlags",
        "L2ProfileId",
        "ProfileName"
      ];
    }
    if (type == SRUMType.PushNotifications) {
      //Id	Timestamp	ExeInfo	ExeInfoDescription	ExeTimestamp	SidType	Sid	UserName	UserId	AppId	NetworkType	NotificationType	PayloadSize
      return [
        "Id",
        "Timestamp",
        "ExeInfo",
        "ExeInfoDescription",
        "ExeTimeStamp",
        "SidType",
        "Sid",
        "Username",
        "UserSid",
        "AppId",
        "NetworkType",
        "NotificationType",
        "PayloadSize"
      ];
    }
    if (type == SRUMType.VFUProv) {
      //Id	Timestamp	UserId	AppId	ExeInfo	ExeInfoDescription	ExeTimestamp	SidType	Sid	UserName	StartTime	EndTime	Flags	Duration

      return [
        "Id",
        "Timestamp",
        "UserId",
        "AppId",
        "ExeInfo",
        "ExeInfoDescription",
        "ExeTimeStamp",
        "SidType",
        "Sid",
        "Username",
        "StartTime",
        "EndTime",
        "Flags",
        "Duration"
      ];
    }

    return [];
  }

  Widget srumRow(SRUM data) {
    List<String> cells = data.full.replaceAll("`-1`", "``").split("`");
    cells.removeAt(0);

    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: cells
            .map((cell) => Text(cell, style: const TextStyle(fontSize: 12)))
            .toList());
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ping_o_meter/pinger.dart';
import 'package:ping_o_meter/tools/helpers.dart';

class HistoryTable extends StatefulWidget {
  final List<PingTestHistoryItemData> history;
  final Pinger pinger;

  const HistoryTable({super.key, required this.history, required this.pinger});
  @override
  State<StatefulWidget> createState() {
    return HistoryTableState();
  }
}

class HistoryTableState extends State<HistoryTable> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: buildHistoryRows(),
    );
  }

  buildHistoryRows() {
    if (widget.history!.isNotEmpty) {
      return <Widget>[
        for (PingTestHistoryItemData item in widget.history)
          Container(
            height: 32,
            color: item.index % 2 == 0 ? Colors.transparent : Colors.white.withAlpha(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  child: Icon(
                    item.isSuccess ? Icons.done_all : Icons.error,
                    color: Helpers.generatLatencyLevelColor(item.timeout, item.isSuccess, widget.pinger),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    item.hostUrl,
                    textAlign: TextAlign.left,
                    style: TextStyle(overflow: TextOverflow.ellipsis, color: Helpers.generatLatencyLevelColor(item.timeout, item.isSuccess, widget.pinger)),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      item.timeout.toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(overflow: TextOverflow.ellipsis, color: Helpers.generatLatencyLevelColor(item.timeout, item.isSuccess, widget.pinger)),
                    ),
                  ),
                )
              ],
            ),
          )
      ];
    } else {
      return <Widget>[
        for (int i = 0; i < widget.pinger.maxHistoryLogLength; i++)
          const SizedBox(
            height: 32,
            child: Divider(),
          )
      ];
    }
  }
}

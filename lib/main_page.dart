import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';

extension TextEditingControllerExt on TextEditingController {
  void selectAll() {
    if (text.isEmpty) return;
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}

const String defaultHost = "https://google.com";

class PingCheckData {
  String host = defaultHost;
  bool isSuccess = false;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class PingTestHistoryItemData {
  bool isSuccess = false;
  double timeout = 0;
  String hostUrl;

  PingTestHistoryItemData(
      {required this.isSuccess, required this.timeout, required this.hostUrl});
}

class MainPageState extends State<MainPage> {
  String targetHostUrl = "google.com";
  final int timeout = 2;
  bool isPingTestRunning = false;
  late List<PingTestHistoryItemData> pingLog;
  Ping? ping;

  int bestPingValue = 0;
  int worstPingValue = 1000;

  int maxHistoryLogLength = 10;
  late TextEditingController hostInputTextContoller;

  @override
  void initState() {
    hostInputTextContoller = TextEditingController(text: targetHostUrl);
    pingLog = <PingTestHistoryItemData>[];
    super.initState();
  }

  @override
  void deactivate() {
    stopTest();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    ;

    return Scaffold(
      backgroundColor: Colors.black26,
      appBar: AppBar(
        title: const Text('Ping`O`Meter'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 24,
                ),
                TextField(
                  controller: hostInputTextContoller,
                  onTap: () {
                    // hostInputTextContoller.clear();
                    hostInputTextContoller.selectAll();
                  },
                  onSubmitted: (String value) {
                    targetHostUrl = value;
                    if (isPingTestRunning) {
                      startTest();
                    }
                    // clearHistory();
                  },
                  obscureText: false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Host',
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const <DataColumn>[
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                '#',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                'Host',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                'Time',
                                style: TextStyle(
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                        rows: buildHistoryItemsDataRows(),
                      ),
                    ))
              ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          isPingTestRunning = !isPingTestRunning;
          if (isPingTestRunning) {
            startTest();
          } else {
            stopTest();
          }
          // Add your onPressed code here!
        },
        backgroundColor: isPingTestRunning ? Colors.red : Colors.amber,
        child: isPingTestRunning
            ? const Icon(Icons.stop)
            : const Icon(Icons.play_arrow),
      ),
    );
  }

  void startTest() {
    if (ping != null) {
      stopTest();
    }
    ping = Ping(targetHostUrl, timeout: timeout);

    print("start pinging $targetHostUrl");
    //Begin ping process and listen for output
    ping?.stream.listen((event) {
      if (isPingTestRunning) {
        print(event.response?.time?.inMilliseconds.toString());
        pingLog.insert(
            0,
            PingTestHistoryItemData(
                isSuccess: event.response?.time != null,
                timeout: event.response?.time?.inMilliseconds.toDouble() ?? 0,
                hostUrl: targetHostUrl));

        if (pingLog.length > maxHistoryLogLength) {
          pingLog.removeAt(pingLog.length - 1);
        }
        setState(() {});
      }
    });

    setState(() {});
  }

  void stopTest() {
    print("stop pinging $targetHostUrl");
    ping?.stop();
    ping = null;
    setState(() {});
  }

  clearHistory() {
    pingLog = <PingTestHistoryItemData>[];
    setState(() {});
  }

  Container buildHistoryItem(dynamic item) {
    return Container(
      child: Text(item.toString()),
    );
  }

  buildHistoryItemsDataRows() {
    List<DataRow> ret = [];

    if (pingLog.isNotEmpty) {
      for (PingTestHistoryItemData item in pingLog) {
        ret.add(DataRow(
          cells: <DataCell>[
            DataCell(
              Icon(
                item.isSuccess ? Icons.done_all : Icons.error,
                color: generateColor(item.timeout, item.isSuccess),
              ),
            ),
            DataCell(Text(
              item.hostUrl,
              style:
                  TextStyle(color: generateColor(item.timeout, item.isSuccess)),
            )),
            DataCell(Text(
              item.timeout.toString(),
              style:
                  TextStyle(color: generateColor(item.timeout, item.isSuccess)),
            )),
          ],
        ));
      }
    } else {
      for (int i = 0; i < maxHistoryLogLength; i++) {
        ret.add(const DataRow(
          cells: <DataCell>[
            DataCell(Text("")),
            DataCell(Text("")),
            DataCell(Text("")),
          ],
        ));
      }
    }

    return ret;
  }

  Color generateColor(double pingValue, bool isSuccess) {
    if (!isSuccess) {
      return Colors.redAccent.shade200;
    } else {
      double badness = clampDouble(
          (pingValue - bestPingValue) / (worstPingValue - bestPingValue), 0, 1);
      print("badness: $badness");

      badness = pow(badness, 0.5) as double;
      // badness = 1;

      return Color.lerp(Colors.white, Colors.orangeAccent.shade400, badness)!;
    }
  }
}

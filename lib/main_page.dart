import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:just_audio/just_audio.dart';

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
  static int count = 0;
  int index = 0;
  bool isSuccess = false;
  double timeout = 0;
  String hostUrl;
  PingTestHistoryItemData({required this.isSuccess, required this.timeout, required this.hostUrl}) {
    index = PingTestHistoryItemData.count;
    PingTestHistoryItemData.count++;
  }
}

class MainPageState extends State<MainPage> {
  String targetHostUrl = "google.com";
  final int pingCommandTimeout = 2;
  bool isPingTestRunning = false;
  late List<PingTestHistoryItemData> pingLog;
  Ping? ping;
  bool soundEnabled = true;

  int bestPingValue = 0;
  int worstPingValue = 1000;

  int maxHistoryLogLength = 24;
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
    return Scaffold(
      backgroundColor: Colors.black26,
      appBar: AppBar(
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Text(
            "Ping'O'Meter",
          )
        ]),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
              onPressed: () {
                soundEnabled = !soundEnabled;
              },
              icon: Icon(soundEnabled ? Icons.volume_up_outlined : Icons.volume_mute_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline))
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 32, left: 16, right: 16),
              child: TextField(
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
            ),
            Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            '№',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            'Status',
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
                            'Ping (ms)',
                            style: TextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight.bold),
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
        backgroundColor: isPingTestRunning ? Colors.amber : Colors.lightGreen,
        child: isPingTestRunning ? const Icon(Icons.stop) : const Icon(Icons.play_arrow),
      ),
    );
  }

  void startTest() {
    if (ping != null) {
      stopTest();
    }
    ping = Ping(targetHostUrl, timeout: pingCommandTimeout);

    print("start pinging $targetHostUrl");
    //Begin ping process and listen for output
    ping?.stream.listen((event) {
      if (isPingTestRunning) {
        print(event.response?.time?.inMilliseconds.toString());
        pingLog.insert(
            0,
            PingTestHistoryItemData(
                isSuccess: event.response?.time != null, timeout: event.response?.time?.inMilliseconds.toDouble() ?? 0, hostUrl: targetHostUrl));

        if (pingLog.length > maxHistoryLogLength) {
          pingLog.removeAt(pingLog.length - 1);
        }

        if (soundEnabled) {
          playSound(event.response?.time != null, event.response?.time?.inMilliseconds.toDouble() ?? 0);
        }

        setState(() {});
      }
    });

    setState(() {});
  }

  playSound(bool isSuccess, double timeout) async {}

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
          selected: item.index % 2 == 0,
          cells: <DataCell>[
            DataCell(Text(
              item.index.toString(),
              style: TextStyle(color: generateColor(item.timeout, item.isSuccess)),
            )),
            DataCell(Icon(
              item.isSuccess ? Icons.done_all : Icons.error,
              color: generateColor(item.timeout, item.isSuccess),
            )),
            DataCell(Text(
              item.hostUrl,
              style: TextStyle(color: generateColor(item.timeout, item.isSuccess)),
            )),
            DataCell(Text(
              item.timeout.toString(),
              style: TextStyle(color: generateColor(item.timeout, item.isSuccess)),
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
            DataCell(Text("")),
          ],
        ));
      }
    }

    return ret;
  }

  double getPingBadness(double pingValue) {
    double badness = clampDouble((pingValue - bestPingValue) / (worstPingValue - bestPingValue), 0, 1);
    badness = pow(badness, 0.5) as double;
    return badness;
  }

  Color generateColor(double pingValue, bool isSuccess) {
    if (!isSuccess) {
      return Colors.redAccent.shade200;
    } else {
      return Color.lerp(Colors.white, Colors.orangeAccent.shade400, getPingBadness(pingValue))!;
    }
  }
}

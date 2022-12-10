// author: @sanyabeast. Fri 9 Dec 2022

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';
import "package:ping_o_meter/beeper.dart";
import 'package:ping_o_meter/mixins/persistent_module.dart';

const String appVersion = "0.9.0";
const String defaultTargetHostUrl = "example.com";

extension TextEditingControllerExt on TextEditingController {
  void selectAll() {
    if (text.isEmpty) return;
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> with PersistentModule {
  String targetHostUrl = defaultTargetHostUrl;
  final int pingCommandTimeout = 2;
  bool isPingTestRunning = false;
  late List<PingTestHistoryItemData> pingLog;
  Ping? ping;
  int bestPingValue = 0;
  int worstPingValue = 999;
  int maxHistoryLogLength = 32;
  late TextEditingController hostInputTextContoller;
  Beeper beeper = Beeper();

  @override
  void initState() {
    loadState();
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
  void dispose() {
    stopTest();
    super.dispose();
  }

  @override
  onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(left: 24, right: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Expanded(
                flex: 1,
                child: Text("Ping'O'Meter", style: TextStyle(fontSize: 18)),
              ),
              if (beeper.isAudioPaybackSupported)
                IconButton(
                  onPressed: () {
                    beeper.toggleMute();
                    notifyChanged(save: true);
                  },
                  icon: Icon(!beeper.muted ? Icons.volume_up_rounded : Icons.volume_mute_rounded),
                  color: !beeper.muted ? Colors.white : Colors.white,
                ),
              IconButton(
                  onPressed: () => showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Center(
                              child: Text("Pingo'O'Meter | $appVersion",
                                  style: TextStyle(fontSize: 16))),
                          content: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('Author: @sanyabeast'),
                                Text('2022, Kyiv, Ukraine')
                              ]),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'OK'),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                  icon: const Icon(Icons.question_mark_rounded))
            ]),
          ),
          backgroundColor: Colors.black),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
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
                      notifyChanged(save: true);
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
                  child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 0),
                      child: SingleChildScrollView(
                          child: Column(
                        children: buildHistoryItemsDataRows(),
                      ))),
                )
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
        child: isPingTestRunning
            ? const Icon(Icons.cancel_rounded)
            : const Icon(Icons.play_arrow_rounded),
      ),
    );
  }

  void startTest() {
    if (ping != null) {
      stopTest();
    }
    ping = Ping(targetHostUrl, timeout: pingCommandTimeout, interval: 2, count: 99);
    ping?.stream.listen((event) {
      if (isPingTestRunning) {
        pingLog.insert(
            0,
            PingTestHistoryItemData(
                isSuccess: event.response?.time != null,
                timeout: event.response?.time?.inMilliseconds.toDouble() ?? 0,
                hostUrl: targetHostUrl));

        if (pingLog.length > maxHistoryLogLength) {
          pingLog.removeAt(pingLog.length - 1);
        }
        beeper.beepLatencyQuality(
            computeLatencyQualityFactor(event.response?.time?.inMilliseconds.toDouble() ?? 0),
            event.response?.time != null);
        notifyChanged();
      }
    });
    notifyChanged();
  }

  void stopTest() {
    print("stop pinging $targetHostUrl");
    ping?.stop();
    ping = null;
    notifyChanged();
  }

  clearHistory() {
    pingLog = <PingTestHistoryItemData>[];
    notifyChanged();
  }

  Text buildHistoryItem(dynamic item) {
    return Text(item.toString());
  }

  buildHistoryItemsDataRows() {
    if (pingLog.isNotEmpty) {
      return <Widget>[
        for (PingTestHistoryItemData item in pingLog)
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
                    color: generateColor(item.timeout, item.isSuccess),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    item.hostUrl,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: generateColor(item.timeout, item.isSuccess)),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      item.timeout.toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: generateColor(item.timeout, item.isSuccess)),
                    ),
                  ),
                )
              ],
            ),
          )
      ];
    } else {
      return <Widget>[
        for (int i = 0; i < maxHistoryLogLength; i++)
          const SizedBox(
            height: 32,
            child: Divider(),
          )
      ];
    }
  }

  double computeLatencyQualityFactor(double latency) {
    double latencyQuality =
        1 - clampDouble((latency - bestPingValue) / (worstPingValue - bestPingValue), 0, 1);
    latencyQuality = pow(latencyQuality, 2) as double;
    return latencyQuality;
  }

  Color generateColor(double latency, bool isSuccess) {
    if (!isSuccess) {
      return Colors.redAccent.shade200;
    } else {
      return Color.lerp(const Color.fromARGB(255, 255, 119, 0), Colors.white,
          computeLatencyQualityFactor(latency))!;
    }
  }

  @override
  loadState() async {
    var settings = await loadData();
    if (settings != null) {
      beeper.muted = settings["audioMuted"] ?? false;
      targetHostUrl = settings["targetHostUrl"] ?? defaultTargetHostUrl;
      hostInputTextContoller.text = targetHostUrl;
      notifyChanged();
      if (kDebugMode) {
        print(settings);
      }
    }
  }

  @override
  saveState() {
    saveData({"targetHostUrl": targetHostUrl, "audioMuted": beeper.muted});
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
    PingTestHistoryItemData.count = (PingTestHistoryItemData.count + 1) % 99;
  }
}

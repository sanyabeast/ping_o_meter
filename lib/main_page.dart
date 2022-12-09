import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

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
    PingTestHistoryItemData.count = (PingTestHistoryItemData.count + 1) % 99;
  }
}

class MainPageState extends State<MainPage> {
  String targetHostUrl = "google.com";
  final int pingCommandTimeout = 1;
  bool isPingTestRunning = false;
  late List<PingTestHistoryItemData> pingLog;
  Ping? ping;
  bool soundEnabled = false;
  int bestPingValue = 0;
  int worstPingValue = 999;
  int maxHistoryLogLength = 32;
  late TextEditingController hostInputTextContoller;
  AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    hostInputTextContoller = TextEditingController(text: targetHostUrl);
    pingLog = <PingTestHistoryItemData>[];
    player.setVolume(0.025);
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
              if (isAudioPaybackSupported())
                IconButton(
                  onPressed: () {
                    soundEnabled = !soundEnabled;
                    setState(() {});
                  },
                  icon: Icon(soundEnabled ? Icons.volume_up_rounded : Icons.volume_mute_rounded),
                  color: soundEnabled ? Colors.white : Colors.white,
                ),
              IconButton(
                  onPressed: () => showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Center(
                              child: Text("Pingo'O'Meter", style: TextStyle(fontSize: 12))),
                          content: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('created by @sanyabeast'),
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
        playBadnessLevelSoundEffect(
            event.response?.time != null, event.response?.time?.inMilliseconds.toDouble() ?? 0);
        setState(() {});
      }
    });
    setState(() {});
  }

  playBadnessLevelSoundEffect(bool isSuccess, double pingValue) async {
    if (!soundEnabled) {
      return;
    }

    if (isAudioPaybackSupported()) {
      double pitch =
          !isSuccess ? 0.1 : lerpDouble(1, 0.25, pow(getPingBadness(pingValue), 1).toDouble())!;

      if (Platform.isAndroid) {
        await player.setUrl('asset:assets/audio/level_5.ogg');
        player.setPitch(pitch);
        player.play();
      } else if (Platform.isMacOS) {
        int audioIndex = clampDouble(lerpDouble(0, 6, pitch)!, 0, 5).toInt();
        await player.setUrl('asset:assets/audio/level_$audioIndex.mp3');
        player.play();
      }
    }
  }

  bool isAudioPaybackSupported() {
    return Platform.isAndroid || Platform.isMacOS;
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

  double getPingBadness(double pingValue) {
    double badness =
        clampDouble((pingValue - bestPingValue) / (worstPingValue - bestPingValue), 0, 1);
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

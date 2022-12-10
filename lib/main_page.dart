// author: @sanyabeast. Fri 9 Dec 2022

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:ping_o_meter/beeper.dart";
import 'package:ping_o_meter/mixins/persistent_module.dart';
import 'package:ping_o_meter/pinger.dart';
import 'package:ping_o_meter/widgets/settings_and_about.dart';

const String appVersion = "0.9.0";

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
  late TextEditingController hostInputTextContoller;
  late Pinger pinger;
  Beeper beeper = Beeper();

  @override
  void initState() {
    pinger = Pinger(onUpdate: () {
      notifyChanged();
    }, onPingEvent: (bool isSuccess, double latency) {
      beeper.beepLatencyQuality(isSuccess, pinger.computeLatencyQualityFactor(latency));
      notifyChanged();
    });
    loadState();
    hostInputTextContoller = TextEditingController(text: pinger.host);
    super.initState();
  }

  @override
  void deactivate() {
    pinger.stopTest();
    super.deactivate();
  }

  @override
  void dispose() {
    pinger.stopTest();
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
                          content: SettingsAndAboutWidget(
                            onUpdated: () => notifyChanged(),
                            pinger: pinger,
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'OK'),
                              child: const Text('Done'),
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
                      pinger.host = value;
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
          pinger.running = !pinger.running;

          // Add your onPressed code here!
        },
        backgroundColor: pinger.running ? Colors.amber : Colors.lightGreen,
        child: pinger.running
            ? const Icon(Icons.cancel_rounded)
            : const Icon(Icons.play_arrow_rounded),
      ),
    );
  }

  Text buildHistoryItem(dynamic item) {
    return Text(item.toString());
  }

  buildHistoryItemsDataRows() {
    if (pinger.history!.isNotEmpty) {
      return <Widget>[
        for (PingTestHistoryItemData item in pinger.history)
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
        for (int i = 0; i < pinger.maxHistoryLogLength; i++)
          const SizedBox(
            height: 32,
            child: Divider(),
          )
      ];
    }
  }

  Color generateColor(double latency, bool isSuccess) {
    if (!isSuccess) {
      return Colors.redAccent.shade200;
    } else {
      return Color.lerp(const Color.fromARGB(255, 255, 119, 0), Colors.white,
          pinger.computeLatencyQualityFactor(latency))!;
    }
  }

  @override
  loadState() async {
    var settings = await loadSavedData();
    if (settings != null) {
      await pinger.loadState();
      beeper.muted = settings["muted"] ?? false;
      hostInputTextContoller.text = pinger.host;
      notifyChanged();
      if (kDebugMode) {
        print(settings);
      }
    }
  }

  @override
  saveState() {
    saveData({"muted": beeper.muted});
  }
}

// author: @sanyabeast. Fri 9 Dec 2022

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:ping_o_meter/beeper.dart";
import 'package:ping_o_meter/mixins/persistent_module.dart';
import 'package:ping_o_meter/pinger.dart';
import 'package:ping_o_meter/tools/helpers.dart';
import 'package:ping_o_meter/widgets/settings_and_about.dart';
import 'package:ping_o_meter/widgets/history_table.dart';

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
      beeper.beepLatencyQuality(isSuccess, Helpers.computeLatencyQualityFactor(latency, pinger));
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
      backgroundColor: Colors.black,
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
                            beeper: beeper,
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
                          child: HistoryTable(history: pinger.history, pinger: pinger))),
                )
              ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          pinger.running = !pinger.running;

          // Add your onPressed code here!
        },
        backgroundColor: pinger.running ? Colors.red : Colors.amber,
        child: pinger.running
            ? const Icon(Icons.cancel_rounded)
            : const Icon(Icons.network_check_rounded),
      ),
    );
  }

  Text buildHistoryItem(dynamic item) {
    return Text(item.toString());
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

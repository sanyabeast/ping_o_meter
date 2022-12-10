import 'package:flutter/material.dart';
import 'package:ping_o_meter/beeper.dart';
import 'package:ping_o_meter/mixins/persistent_module.dart';
import 'package:ping_o_meter/pinger.dart';

class SettingsAndAboutWidget extends StatefulWidget {
  final Function onUpdated;
  final Pinger pinger;
  final Beeper beeper;
  const SettingsAndAboutWidget({super.key, required this.onUpdated, required this.pinger, required this.beeper});

  @override
  State<StatefulWidget> createState() {
    return SettingsAndAboutWidgetState();
  }
}

class SettingsAndAboutWidgetState extends State<SettingsAndAboutWidget> with PersistentModule {
  @override
  void initState() {
    super.initState();
  }

  @override
  onChanged() {
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle smallTextStyle = const TextStyle(fontSize: 10);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("Ping'O'Meter 0.9.0", style: TextStyle(fontSize: 18)),
      const Divider(),
      const SizedBox(
        height: 16,
      ),
      const Divider(),
      Text("Author: @sanyabeast", style: smallTextStyle),
      Text("2022 / Ukraine", style: smallTextStyle)
    ]);
  }
}

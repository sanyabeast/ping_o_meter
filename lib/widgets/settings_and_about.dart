import 'package:flutter/material.dart';
import 'package:ping_o_meter/mixins/persistent_module.dart';
import 'package:ping_o_meter/pinger.dart';

class SettingsAndAboutWidget extends StatefulWidget {
  final Function onUpdated;
  final Pinger pinger;
  const SettingsAndAboutWidget({super.key, required this.onUpdated, required this.pinger});

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
    return Column(
      children: [Text("Hi")],
    );
  }
}

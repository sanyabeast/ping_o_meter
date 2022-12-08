import 'package:flutter/material.dart';
import 'package:ping_o_meter/main_page.dart';

void main() {
  runApp(const PingOMeter());
}

class PingOMeter extends StatelessWidget {
  const PingOMeter({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ping`O`Meter',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
      ),
      home: const MainPage(),
    );
  }
}

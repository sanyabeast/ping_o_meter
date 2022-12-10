import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:ping_o_meter/mixins/persistent_module.dart';
import 'package:dart_ping/dart_ping.dart';

const String defaultTargetHostUrl = "example.com";

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

class Pinger with PersistentModule {
  final Function onUpdate;
  final Function(bool, double) onPingEvent;
  Pinger({required this.onUpdate, required this.onPingEvent}) {
    history = <PingTestHistoryItemData>[];
  }

  String _host = defaultTargetHostUrl;
  set host(value) {
    _host = value;
    running = running;
    notifyChanged(save: true);
  }

  get host {
    return _host;
  }

  final int pingCommandTimeout = 2;
  bool _running = false;
  set running(bool value) {
    if (value) {
      if (_running) {
        running = false;
      }
      _running = true;
      startTest();
    } else {
      _running = false;
      stopTest();
    }

    notifyChanged();
  }

  bool get running => _running;

  late List<PingTestHistoryItemData> history;
  Ping? ping;
  int bestPingValue = 0;
  int worstPingValue = 999;
  int maxHistoryLogLength = 32;

  @override
  onChanged() {
    onUpdate();
    return super.onChanged();
  }

  void startTest() {
    ping = Ping(host, timeout: pingCommandTimeout, interval: 2, count: 99);
    ping?.stream.listen((event) {
      if (running) {
        history.insert(
            0,
            PingTestHistoryItemData(
                isSuccess: event.response?.time != null,
                timeout: event.response?.time?.inMilliseconds.toDouble() ?? 0,
                hostUrl: host));

        if (history.length > maxHistoryLogLength) {
          history.removeAt(history.length - 1);
        }

        onPingEvent(
            event.response?.time != null, event.response?.time?.inMilliseconds.toDouble() ?? 0);
        notifyChanged();
      }
    });
    notifyChanged();
  }

  void stopTest() {
    if (kDebugMode) {
      print("stop pinging $host");
    }
    ping?.stop();
    ping = null;
    notifyChanged();
  }

  double computeLatencyQualityFactor(double latency) {
    double latencyQuality =
        1 - clampDouble((latency - bestPingValue) / (worstPingValue - bestPingValue), 0, 1);
    latencyQuality = pow(latencyQuality, 2) as double;
    return latencyQuality;
  }

  @override
  loadState() async {
    var settings = await loadSavedData();
    if (settings != null) {
      host = settings["host"] ?? defaultTargetHostUrl;
      notifyChanged();
    }
  }

  @override
  saveState() {
    saveData({"host": host});
  }
}

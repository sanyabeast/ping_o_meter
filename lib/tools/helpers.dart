import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_o_meter/pinger.dart';

class Helpers {
  static Color generatLatencyLevelColor(double latency, bool isSuccess, Pinger pinger,
      {Color errorColor = Colors.redAccent, Color bestLatencyColor = Colors.white, Color worstLatencyColor = const Color.fromARGB(255, 255, 80, 0)}) {
    if (!isSuccess) {
      return errorColor;
    } else {
      return Color.lerp(worstLatencyColor, bestLatencyColor, computeLatencyQualityFactor(latency, pinger))!;
    }
  }

  static double computeLatencyQualityFactor(double latency, Pinger pinger) {
    double latencyQuality = 1 - clampDouble((latency - pinger.bestPingValue) / (pinger.worstPingValue - pinger.bestPingValue), 0, 1);
    latencyQuality = pow(latencyQuality, 2) as double;
    return latencyQuality;
  }
}

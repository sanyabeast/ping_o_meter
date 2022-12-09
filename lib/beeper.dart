// author: @sanyabeast. Fri 9 Dec 2022

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'dart:math';

class Beeper {
  String audioNamePitched = "beep_a.ogg";
  List<String> audioNamesLeveled = [
    "level_0.mp3",
    "level_1.mp3",
    "level_2.mp3",
    "level_3.mp3",
    "level_4.mp3",
    "level_5.mp3",
  ];

  bool muted = true;
  double volume = 0.1;
  AudioPlayer player = AudioPlayer();

  double pitchForNetworkError = 0.1;
  double putchForBigLatency = 0.25;
  double pitchForSmallLatency = 1;

  Beeper() {
    player.setVolume(0.025);
  }

  bool get isAudioPaybackSupported {
    return Platform.isAndroid || Platform.isMacOS;
  }

  toggleMute() {
    muted = !muted;
  }

  beepLatencyQuality(double latencyQuality, bool isSuccess) async {
    if (muted) {
      return;
    }

    if (isAudioPaybackSupported) {
      double pitch = !isSuccess
          ? pitchForNetworkError
          : lerpDouble(
              putchForBigLatency, pitchForSmallLatency, pow(latencyQuality, 1).toDouble())!;

      if (Platform.isAndroid) {
        await player.setUrl('asset:assets/audio/$audioNamePitched');
        player.setPitch(pitch);
        player.play();
      } else if (Platform.isMacOS) {
        int audioIndex = clampDouble(lerpDouble(0, 6, pitch)!, 0, 5).toInt();
        String audioName = audioNamesLeveled[audioIndex];
        await player.setUrl('asset:assets/audio/$audioName');
        player.play();
      }
    }
  }
}

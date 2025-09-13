import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

class AlarmService {
  static Future<void> init() async {
    await Alarm.init();
  }

  // agenda múltiplos alarmes
  static Future<void> setAlarms({
    required TimeOfDay selectedTime,
    required List<bool> selectedDays,
  }) async {
    final now = DateTime.now();

    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        DateTime dateTime = DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        while (dateTime.weekday % 7 != i) {
          dateTime = dateTime.add(const Duration(days: 1));
        }

        if (dateTime.isBefore(now)) {
          dateTime = dateTime.add(const Duration(days: 7));
        }

        final alarmSettings = AlarmSettings(
          id: i + 1,
          dateTime: dateTime,
          assetAudioPath: 'assets/alarm/alarm.mp3',
          loopAudio: true,
          vibrate: true,
          volumeSettings: VolumeSettings.fade(
            volume: 0.8,
            fadeDuration: const Duration(seconds: 25),
            volumeEnforced: true,
          ),
          notificationSettings: NotificationSettings(
            title: 'Lembrete',
            body: 'Não esqueça de dar uma olhada em suas notificações',
            stopButton: 'Encerrar',
            icon: 'notification_icon',
            iconColor: Colors.green[700],
          ),
        );

        await Alarm.set(alarmSettings: alarmSettings);
      }
    }
  }

  // para todos os alarmes
  static Future<void> stopAllAlarms() async {
    await Alarm.stopAll();
  }
}

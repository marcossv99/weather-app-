import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String city, double temperature, String forecast) async {
    String title = "Clima atual em $city";
    String body = "Temperatura: $temperature°C, Previsão: $forecast";

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'weather_channel_id', // ID do canal
      'Weather Updates', // Nome do canal
      channelDescription: 'Receba notificações de clima',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0, // ID da notificação
      title, // Título da notificação
      body, // Corpo da notificação com a temperatura
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleNotification(
      String city, double temperature, String forecast, Duration interval) async {
    String title = "Clima atual em $city";
    String body = "Temperatura: $temperature°C, Previsão: $forecast";

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID da notificação
      title,
      body,
      tz.TZDateTime.now(tz.local).add(interval),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weather_channel_id', // ID do canal
          'Weather Updates', // Nome do canal
          channelDescription: 'Receba notificações de clima',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
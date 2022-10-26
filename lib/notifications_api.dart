import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsAPI {
  // Single instance only
  NotificationsAPI._constructor();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationsAPI _notificationsAPI =
      NotificationsAPI._constructor();

  factory NotificationsAPI() {
    return _notificationsAPI;
  }

  _constructor() {
    print('calling _constructor');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            // onDidReceiveLocalNotification: (int resp){}
            );
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            macOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (resp) {});
  }

  sendNotification(String title,
      {String body = '', String payload = ''}) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'calendarAlarms', 'Calendar alarms',
      channelDescription: 'Makes alarm sound on the important calendar events',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      // Make notification notisable with fullscreen intent and gentle long alarm sound
      ongoing: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      fullScreenIntent: true,
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await _flutterLocalNotificationsPlugin
        .show(0, title, body, notificationDetails, payload: payload);
  }
}

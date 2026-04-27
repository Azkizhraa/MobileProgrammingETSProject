import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {}

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ccws_channel',
    'CCWS Room Alerts',
    description: 'Notifications about CCWS room activity',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    await _fcm.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    await _local.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) {
        _local.show(
          n.hashCode,
          n.title,
          n.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
                _channel.id, _channel.name,
                importance: Importance.high, priority: Priority.high),
          ),
        );
      }
    });

    await _fcm.subscribeToTopic('ccws_alerts');
  }

  Future<void> showRoomActiveNotification(String name) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🏢 Someone just arrived at CCWS!',
      '$name just checked in. The room is now active.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentSound: true),
      ),
    );
  }

  Future<void> showNewCommentNotification(String name) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '💬 New CCWS update',
      '$name just posted about the room.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }
}

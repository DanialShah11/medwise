import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Optional: Handle tap action
      },
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'medstock_channel',
      'Medicine Alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medstock_channel',
          'MedStock Alerts',
          channelDescription: 'Notification for medicine expiry alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> scheduleExpiryNotifications(
      List<Map<String, dynamic>> medicines) async {
    final now = DateTime.now();
    final daysToNotify = [7, 15, 30];

    for (var med in medicines) {
      final expiry = _getExpiryDate(med);
      if (expiry == null) continue;

      for (int days in daysToNotify) {
        final notifyDate = expiry.subtract(Duration(days: days));
        if (notifyDate.isAfter(now)) {
          await scheduleNotification(
            id: _generateUniqueId(med['id'], days),
            title: 'Expiry Alert: ${med['name']}',
            body: '${med['name']} expires in $days days!',
            scheduledDate: notifyDate,
          );
        }
      }
    }
  }

  DateTime? _getExpiryDate(Map<String, dynamic> med) {
    final raw = med['expiryDate'];
    if (raw == null) return null;

    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (e) {
        print("Invalid expiry date format for ${med['name']}");
        return null;
      }
    }
    return null;
  }

  int _generateUniqueId(String medicineId, int daysBefore) {
    return medicineId.hashCode + daysBefore;
  }
}

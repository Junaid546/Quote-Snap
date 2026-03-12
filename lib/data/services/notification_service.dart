import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/quote_entity.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static const _channelId = 'quotesnap_channel';
  static const _channelName = 'QuoteSnap Alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ─── Initialization ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // flutter_local_notifications v21 uses named parameters
    await _plugin.initialize(settings: initSettings);

    // Request permissions for Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    debugPrint('[NotificationService] Initialized');
  }

  // ─── Quote Expiry Reminders ──────────────────────────────────────────────────
  /// Schedule a notification 3 days before the 30-day validity expires (day 27).
  Future<void> scheduleQuoteExpiryReminders(QuoteEntity quote) async {
    final createdAt = quote.createdAt;
    final reminderDate = createdAt.add(const Duration(days: 27));

    if (reminderDate.isBefore(DateTime.now())) {
      debugPrint('[NotificationService] Reminder date in the past, skipping');
      return;
    }

    final scheduledTime = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9, // 9:00 AM
      0,
    );

    final notifId = _quoteNotifId(quote.id);
    final amountStr = '\$${quote.totalAmount.toStringAsFixed(2)}';

    await _plugin.zonedSchedule(
      id: notifId,
      title: 'Quote #${quote.quoteNumber} expiring soon!',
      body:
          '${quote.clientName} quote for $amountStr expires in 3 days. Send a follow-up!',
      scheduledDate: scheduledTime,
      notificationDetails: _channelDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: quote.id,
    );

    debugPrint(
      '[NotificationService] Scheduled expiry reminder for quote #${quote.quoteNumber}',
    );
  }

  // ─── Weekly Summary ──────────────────────────────────────────────────────────
  /// Schedule a recurring Monday 8:00 AM summary notification.
  Future<void> scheduleWeeklySummary() async {
    final now = tz.TZDateTime.now(tz.local);

    // Find next Monday
    int daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    if (daysUntilMonday == 0) daysUntilMonday = 7;
    final next = now.add(Duration(days: daysUntilMonday));

    final scheduledTime = tz.TZDateTime(
      tz.local,
      next.year,
      next.month,
      next.day,
      8, // 8:00 AM
      0,
    );

    await _plugin.zonedSchedule(
      id: 9999,
      title: 'Your Weekly QuoteSnap Summary',
      body: 'Check in to see your weekly performance at a glance.',
      scheduledDate: scheduledTime,
      notificationDetails: _channelDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    debugPrint(
      '[NotificationService] Weekly summary scheduled for $scheduledTime',
    );
  }

  // ─── Cancel Reminder ─────────────────────────────────────────────────────────
  /// Cancel the reminder for a quote when its status changes from pending.
  Future<void> cancelQuoteReminder(String quoteId) async {
    await _plugin.cancel(id: _quoteNotifId(quoteId));
    debugPrint('[NotificationService] Cancelled reminder for quote $quoteId');
  }

  Future<void> cancelWeeklySummary() async {
    await _plugin.cancel(id: 9999);
  }

  // ─── Immediate Notification ──────────────────────────────────────────────────
  /// For instant feedback (quote saved, sync complete, etc.)
  Future<void> showImmediateNotification(String title, String body) async {
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: _channelDetails(),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  NotificationDetails _channelDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Alerts and reminders from QuoteSnap',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(android: android, iOS: ios);
  }

  /// Generates a stable int ID from a string quoteId (uses hashCode).
  int _quoteNotifId(String quoteId) => quoteId.hashCode.abs() % 100000;
}

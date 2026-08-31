import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/document_record.dart';

/// Handles scheduling local push notifications for document expiries.
///
/// NOTE: this file targets flutter_local_notifications 22.3.0, which
/// uses FULLY NAMED parameters for initialize(), zonedSchedule(),
/// cancel(), and show() — including 'id' and 'notificationDetails',
/// which are positional in most tutorials for older versions. This
/// was confirmed directly against the Dart analyzer's errors for the
/// installed package, not assumed from documentation. Do not "fix"
/// this back to positional-style calls.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const List<int> _reminderDaysBefore = [30, 14, 7, 1];

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'document_expiry_channel',
        'Document Expiry Reminders',
        channelDescription: 'Reminders for upcoming vehicle document expiries',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  /// Initializes local notifications plugin and timezones safely.
  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(settings: initSettings);

      // Android 13+ runtime permissions for notifications & exact alarms.
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Deterministic notification ID so the same document + interval
  /// always maps to the same ID — lets us overwrite cleanly on edit.
  static int _notificationId(String documentId, int daysBefore) {
    return ('${documentId}_$daysBefore').hashCode & 0x7FFFFFFF;
  }

  /// Schedules (or re-schedules) all reminder notifications for one
  /// document. Call this whenever a document is added or edited.
  static Future<void> scheduleForDocument(
    DocumentRecord doc,
    String vehicleName,
  ) async {
    try {
      // Clear any existing notifications for this document first.
      await cancelForDocument(doc.id);

      for (final daysBefore in _reminderDaysBefore) {
        final notifyDate = doc.expiryDate.subtract(Duration(days: daysBefore));

        // Don't schedule notifications in the past.
        if (notifyDate.isBefore(DateTime.now())) continue;

        final scheduledTime = tz.TZDateTime(
          tz.local,
          notifyDate.year,
          notifyDate.month,
          notifyDate.day,
          9, // 9 AM local time
        );

        final typeLabel = _typeLabel(doc.type);
        final title = daysBefore == 1
            ? '$typeLabel expires tomorrow'
            : '$typeLabel expires in $daysBefore days';

        await _plugin.zonedSchedule(
          id: _notificationId(doc.id, daysBefore),
          notificationDetails: _notificationDetails,
          title: title,
          body: '$vehicleName — renew soon to stay compliant',
          scheduledDate: scheduledTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notifications for document ${doc.id}: $e');
    }
  }

  /// Cancels all scheduled reminders for one document — call before
  /// re-scheduling, or when a document is deleted.
  static Future<void> cancelForDocument(String documentId) async {
    try {
      for (final daysBefore in _reminderDaysBefore) {
        await _plugin.cancel(id: _notificationId(documentId, daysBefore));
      }
    } catch (e) {
      debugPrint('Error canceling notifications for document $documentId: $e');
    }
  }

  /// Helper to trigger an immediate test notification — useful for
  /// verifying notifications work at all without waiting on real dates.
  static Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id: 0,
        notificationDetails: _notificationDetails,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }

  static String _typeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.license:
        return 'Driving License';
      case DocumentType.revenueLicense:
        return 'Revenue License';
      case DocumentType.emissionTest:
        return 'Emission Test';
    }
  }
}

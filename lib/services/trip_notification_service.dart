import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:santa_clara/models/trip_model.dart';
import 'package:santa_clara/models/trip_reminder_option.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local trip reminders from the user's selected offsets.
class TripNotificationService {
  TripNotificationService._();

  static final TripNotificationService instance = TripNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'trip_start_reminders';
  static const String _channelName = 'Trip reminders';
  static const String _channelDescription =
      'Notifications before your trip begins';

  static const int _maxNotificationSlots = 3;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _configureLocalTimeZone();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb || !_initialized) return;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> syncTrips(List<Trip> trips) async {
    if (kIsWeb || !_initialized) return;
    await requestPermissions();
    for (final trip in trips) {
      await scheduleForTrip(trip);
    }
  }

  Future<void> scheduleForTrip(Trip trip) async {
    if (kIsWeb || !_initialized) return;
    if (trip.completed != 0) {
      await cancelForTrip(trip.id);
      return;
    }

    await cancelForTrip(trip.id);
    if (trip.reminderOptions.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    final tripStart = _tripStartTime(trip);

    for (final option in trip.reminderOptions) {
      final scheduledDate = tripStart.subtract(option.offsetBeforeStart);
      if (!scheduledDate.isAfter(now)) continue;

      await _schedule(
        id: _notificationId(trip.id, option.notificationSlot),
        scheduledDate: scheduledDate,
        title: option.notificationTitle(trip.name),
        body: option.notificationBody(trip.name),
      );
    }
  }

  Future<void> cancelForTrip(String tripId) async {
    if (kIsWeb || !_initialized) return;
    for (var slot = 0; slot < _maxNotificationSlots; slot++) {
      await _plugin.cancel(_notificationId(tripId, slot));
    }
  }

  tz.TZDateTime _tripStartTime(Trip trip) {
    return tz.TZDateTime(
      tz.local,
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
      trip.startDate.hour,
      trip.startDate.minute,
    );
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('TripNotificationService: using UTC ($e)');
      tz.setLocalLocation(tz.UTC);
    }
  }

  int _notificationId(String tripId, int slot) {
    return (tripId.hashCode.abs() % 50000) * _maxNotificationSlots + slot;
  }
}

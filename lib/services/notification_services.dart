import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:quest_key/services/reminder_scheduler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Quest reminder notifications backed by `flutter_local_notifications`.
///
/// Use [NotificationService.instance] in the app; tests inject a fake
/// [ReminderScheduler] into `QuestListProvider` instead.
class NotificationService implements ReminderScheduler {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Shared instance used by the app.
  static final NotificationService instance = NotificationService();

  static const String channelId = 'quest_channel_id';
  static const String channelName = 'Quest Reminders';
  static const String channelDescription = 'Reminders to complete quests';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialises the shared instance. Call once from `main()`.
  static Future<void> initialize() => instance.init();

  /// Loads the timezone database, sets the device's local timezone (so that
  /// scheduled times are interpreted as local wall-clock time rather than
  /// UTC), creates the notification channel and initialises the plugin.
  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const androidNotificationChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );

    await _android?.createNotificationChannel(androidNotificationChannel);
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );
    _initialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (error) {
      // Unknown zone name or platform channel unavailable (e.g. tests).
      debugPrint(
        'NotificationService: could not determine local timezone ($error); '
        'falling back to UTC. Reminders may fire at the wrong local time.',
      );
      tz.setLocalLocation(tz.UTC);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  /// Requests the Android 13+ `POST_NOTIFICATIONS` runtime permission.
  ///
  /// Returns `true` when notifications are allowed. On Android versions
  /// without the runtime permission (or other platforms) this resolves to
  /// `true`.
  @override
  Future<bool> requestPermission() async {
    final android = _android;
    if (android == null) return true;

    try {
      final granted = await android.requestNotificationsPermission();
      if (granted != null) return granted;
      // Older Android: no runtime permission, check the app-level switch.
      return await android.areNotificationsEnabled() ?? true;
    } catch (error) {
      debugPrint('NotificationService: permission request failed ($error)');
      return false;
    }
  }

  /// Schedules an inexact one-off notification at [scheduledAt], interpreted
  /// in the device's local timezone. Uses [AndroidScheduleMode.inexact] so
  /// no exact-alarm permission is required.
  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);
}

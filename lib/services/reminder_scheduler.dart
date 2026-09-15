/// Abstraction over the platform notification plugin so that the quest
/// provider can schedule/cancel reminders and tests can inject a fake.
abstract class ReminderScheduler {
  /// Asks the OS for permission to post notifications (Android 13+).
  ///
  /// Returns `true` when notifications may be shown. Platforms that need no
  /// runtime permission return `true`.
  Future<bool> requestPermission();

  /// Schedules a one-off notification with [id] at [scheduledAt] (local
  /// wall-clock time). Scheduling an [id] that already exists replaces it.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  });

  /// Cancels the pending notification with [id]. No-op if none exists.
  Future<void> cancel(int id);
}

import 'package:quest_key/services/reminder_scheduler.dart';

/// Records every schedule/cancel call instead of touching the platform.
class FakeReminderScheduler implements ReminderScheduler {
  final List<({int id, String title, String body, DateTime scheduledAt})>
  scheduled = [];
  final List<int> cancelled = [];
  bool permissionGranted = true;
  int permissionRequests = 0;

  /// Ids with a pending (scheduled and not since cancelled) reminder.
  final Set<int> pending = {};

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    scheduled.add((id: id, title: title, body: body, scheduledAt: scheduledAt));
    pending.add(id);
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending.remove(id);
  }
}

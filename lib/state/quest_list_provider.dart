import 'package:flutter/foundation.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/notification_services.dart';
import 'package:quest_key/services/reminder_scheduler.dart';
import 'package:quest_key/services/storage.dart';

/// Result of [QuestListProvider.saveQuest].
enum QuestSaveOutcome {
  /// Saved; no reminder requested (any previous reminder was cancelled).
  saved,

  /// Saved and a reminder was scheduled.
  reminderScheduled,

  /// Saved, but the reminder time was already in the past so nothing was
  /// scheduled and `remindMe` was stored as `false`.
  reminderInPast,
}

/// Holds the quest list, persists every change, owns reminder scheduling
/// and notifies listeners.
class QuestListProvider with ChangeNotifier {
  QuestListProvider({
    QuestStorage? storage,
    ReminderScheduler? scheduler,
    DateTime Function()? now,
  }) : _storage = storage,
       _scheduler = scheduler,
       _now = now ?? DateTime.now;

  /// How long before the due date a reminder fires.
  static const Duration reminderLeadTime = Duration(minutes: 30);

  final QuestStorage? _storage;
  final ReminderScheduler? _scheduler;
  final DateTime Function() _now;

  /// Storage used for persistence; defaults to [StorageService.instance].
  QuestStorage get storage => _storage ?? StorageService.instance;

  /// Scheduler used for reminders; defaults to [NotificationService.instance].
  ReminderScheduler get scheduler => _scheduler ?? NotificationService.instance;

  final List<Quest> _quests = [];

  /// Quest currently being edited on the create/edit page, if any.
  Quest? selectedQuest;

  /// Read-only view of all quests in insertion order.
  List<Quest> get quests => List.unmodifiable(_quests);

  /// Quests still in progress that are past their due date.
  List<Quest> get overdueQuests {
    final now = _now();
    return _quests.where((q) => q.isOverdueAt(now)).toList()..sort(_byDueDate);
  }

  /// Number of quests completed on the calendar day of [day] (today by
  /// default).
  int completedOn([DateTime? day]) {
    final d = day ?? _now();
    return _quests.where((q) => q.wasCompletedOn(d)).length;
  }

  int get completedTodayCount => completedOn();

  static int _byDueDate(Quest a, Quest b) => a.dueDate.compareTo(b.dueDate);

  static int _byCompletedDesc(Quest a, Quest b) {
    final ca = a.completedAt;
    final cb = b.completedAt;
    if (ca == null && cb == null) return _byDueDate(a, b);
    if (ca == null) return 1;
    if (cb == null) return -1;
    return cb.compareTo(ca);
  }

  List<Quest> get inProgressQuests => getFilteredQuests(QuestStatus.inProgress);

  List<Quest> get completedQuests => getFilteredQuests(QuestStatus.completed);

  /// Nullable for reset.
  void setSelectedQuest(Quest? quest) {
    selectedQuest = quest;
    notifyListeners();
  }

  /// Returns the next free quest id: (highest existing id) + 1, or 1 when
  /// the list is empty. Derived from the loaded list; nothing extra is stored.
  int nextQuestId() {
    if (_quests.isEmpty) return 1;
    return _quests.map((q) => q.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  Quest? questById(int id) {
    for (final quest in _quests) {
      if (quest.id == id) return quest;
    }
    return null;
  }

  /// When the reminder for [quest] would fire.
  static DateTime reminderTimeFor(Quest quest) =>
      quest.dueDate.subtract(reminderLeadTime);

  /// Adds [quest] (new id) or replaces the quest with the same id, persists
  /// the list and schedules or cancels its reminder as requested.
  Future<QuestSaveOutcome> saveQuest(Quest quest) async {
    var outcome = QuestSaveOutcome.saved;
    var toSave = quest;

    if (quest.remindMe && !quest.isCompleted) {
      final reminderAt = reminderTimeFor(quest);
      if (reminderAt.isAfter(_now())) {
        outcome = QuestSaveOutcome.reminderScheduled;
      } else {
        outcome = QuestSaveOutcome.reminderInPast;
        toSave = quest.copyWith(remindMe: false);
      }
    }

    final index = _quests.indexWhere((q) => q.id == toSave.id);
    if (index == -1) {
      _quests.add(toSave);
    } else {
      _quests[index] = toSave;
    }
    notifyListeners();
    await saveQuestsToStorage();

    // Always clear any previous reminder for this id, then (re)schedule.
    await scheduler.cancel(toSave.id);
    if (outcome == QuestSaveOutcome.reminderScheduled) {
      await scheduler.schedule(
        id: toSave.id,
        title: 'Quest Reminder',
        body: '“${toSave.title}” is due soon. Don’t forget to complete it!',
        scheduledAt: reminderTimeFor(toSave),
      );
    }
    return outcome;
  }

  Future<void> addQuest(Quest quest) async {
    _quests.add(quest);
    notifyListeners();
    await saveQuestsToStorage();
  }

  Future<void> removeQuest(Quest quest) => removeQuestById(quest.id);

  Future<void> removeQuestById(int id) async {
    final before = _quests.length;
    _quests.removeWhere((q) => q.id == id);
    if (_quests.length == before) return;
    notifyListeners();
    await saveQuestsToStorage();
    await scheduler.cancel(id);
  }

  /// Replaces the quest with the same id as [quest]. No-op if not found.
  Future<void> updateQuest(Quest quest) async {
    final index = _quests.indexWhere((q) => q.id == quest.id);
    if (index == -1) return;
    _quests[index] = quest;
    notifyListeners();
    await saveQuestsToStorage();
  }

  Future<void> updateQuestStatus(int questId, QuestStatus status) async {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index == -1) return;
    final completed = status == QuestStatus.completed;
    _quests[index] = _quests[index].copyWith(
      status: status,
      completedAt: completed ? _now() : null,
      clearCompletedAt: !completed,
    );
    notifyListeners();
    await saveQuestsToStorage();
    if (status == QuestStatus.completed) {
      await scheduler.cancel(questId);
    }
  }

  Future<void> markQuestCompleted(Quest quest) =>
      updateQuestStatus(quest.id, QuestStatus.completed);

  /// Quests with [filterStatus], or all quests when it is `null`.
  ///
  /// In-progress quests are sorted by due date (soonest first) and completed
  /// quests by completion time (latest first). The "all" view lists
  /// in-progress quests before completed ones.
  List<Quest> getFilteredQuests(QuestStatus? filterStatus) {
    switch (filterStatus) {
      case QuestStatus.inProgress:
        return _quests.where((q) => !q.isCompleted).toList()..sort(_byDueDate);
      case QuestStatus.completed:
        return _quests.where((q) => q.isCompleted).toList()
          ..sort(_byCompletedDesc);
      case null:
        return [
          ...getFilteredQuests(QuestStatus.inProgress),
          ...getFilteredQuests(QuestStatus.completed),
        ];
    }
  }

  Future<void> loadQuestsFromStorage() async {
    final loadedQuests = await storage.loadQuests();
    _quests
      ..clear()
      ..addAll(loadedQuests);
    notifyListeners();
  }

  Future<void> saveQuestsToStorage() => storage.saveQuests(_quests);
}

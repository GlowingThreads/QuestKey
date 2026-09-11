import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/quest_list_provider.dart';

import 'helpers/fake_reminder_scheduler.dart';

void main() {
  final now = DateTime(2030, 6, 1, 12, 0);
  late FakeReminderScheduler scheduler;
  late InMemoryQuestStorage storage;
  late QuestListProvider provider;

  Quest quest({
    int id = 1,
    required DateTime dueDate,
    bool remindMe = true,
    QuestStatus status = QuestStatus.inProgress,
  }) {
    return Quest(
      id: id,
      title: 'Quest $id',
      description: 'desc',
      dueDate: dueDate,
      remindMe: remindMe,
      status: status,
    );
  }

  setUp(() {
    scheduler = FakeReminderScheduler();
    storage = InMemoryQuestStorage();
    provider = QuestListProvider(
      storage: storage,
      scheduler: scheduler,
      now: () => now,
    );
  });

  group('saveQuest reminders', () {
    test('schedules 30 minutes before a future due date', () async {
      final due = now.add(const Duration(hours: 2));

      final outcome = await provider.saveQuest(quest(dueDate: due));

      expect(outcome, QuestSaveOutcome.reminderScheduled);
      expect(scheduler.scheduled.length, 1);
      expect(scheduler.scheduled.single.id, 1);
      expect(
        scheduler.scheduled.single.scheduledAt,
        due.subtract(QuestListProvider.reminderLeadTime),
      );
      expect(scheduler.scheduled.single.body, contains('Quest 1'));
      expect(provider.quests.single.remindMe, isTrue);
      expect((await storage.loadQuests()).single.remindMe, isTrue);
    });

    test('does not schedule when the reminder time is already past', () async {
      // Due in 10 minutes → reminder would be 20 minutes ago.
      final due = now.add(const Duration(minutes: 10));

      final outcome = await provider.saveQuest(quest(dueDate: due));

      expect(outcome, QuestSaveOutcome.reminderInPast);
      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.pending, isEmpty);
      // The flag is persisted as false so the edit form does not lie.
      expect(provider.quests.single.remindMe, isFalse);
      expect((await storage.loadQuests()).single.remindMe, isFalse);
    });

    test('does not schedule when the due date itself is in the past', () async {
      final outcome = await provider.saveQuest(
        quest(dueDate: now.subtract(const Duration(days: 1))),
      );
      expect(outcome, QuestSaveOutcome.reminderInPast);
      expect(scheduler.scheduled, isEmpty);
    });

    test('a reminder exactly 30 minutes out is treated as past', () async {
      final outcome = await provider.saveQuest(
        quest(dueDate: now.add(QuestListProvider.reminderLeadTime)),
      );
      expect(outcome, QuestSaveOutcome.reminderInPast);
    });

    test(
      'unticked reminder cancels any previous one and schedules nothing',
      () async {
        final due = now.add(const Duration(days: 1));
        await provider.saveQuest(quest(dueDate: due));
        expect(scheduler.pending, {1});

        final outcome = await provider.saveQuest(
          quest(dueDate: due, remindMe: false),
        );

        expect(outcome, QuestSaveOutcome.saved);
        expect(scheduler.pending, isEmpty);
        expect(scheduler.scheduled.length, 1); // no new schedule
        expect(provider.quests.length, 1); // updated in place, not duplicated
      },
    );

    test('editing with reminder ticked cancels then reschedules', () async {
      final due = now.add(const Duration(days: 1));
      await provider.saveQuest(quest(dueDate: due));

      final newDue = now.add(const Duration(days: 2));
      await provider.saveQuest(quest(dueDate: newDue));

      expect(scheduler.cancelled, [1, 1]);
      expect(scheduler.scheduled.length, 2);
      expect(
        scheduler.scheduled.last.scheduledAt,
        newDue.subtract(QuestListProvider.reminderLeadTime),
      );
      expect(scheduler.pending, {1});
    });

    test('completed quests never get a reminder', () async {
      final outcome = await provider.saveQuest(
        quest(
          dueDate: now.add(const Duration(days: 1)),
          status: QuestStatus.completed,
        ),
      );
      expect(outcome, QuestSaveOutcome.saved);
      expect(scheduler.scheduled, isEmpty);
    });

    test('uses nextQuestId-compatible ids for new quests', () async {
      await provider.saveQuest(
        quest(id: 1, dueDate: now.add(const Duration(days: 1))),
      );
      await provider.saveQuest(
        quest(id: 2, dueDate: now.add(const Duration(days: 1))),
      );
      expect(provider.nextQuestId(), 3);
    });
  });

  group('cancellation', () {
    test('completing a quest cancels its reminder', () async {
      final q = quest(dueDate: now.add(const Duration(days: 1)));
      await provider.saveQuest(q);
      expect(scheduler.pending, {1});

      await provider.markQuestCompleted(q);

      expect(scheduler.pending, isEmpty);
      expect(scheduler.cancelled.last, 1);
      expect(provider.quests.single.isCompleted, isTrue);
    });

    test('deleting a quest cancels its reminder', () async {
      final q = quest(dueDate: now.add(const Duration(days: 1)));
      await provider.saveQuest(q);

      await provider.removeQuest(q);

      expect(scheduler.pending, isEmpty);
      expect(scheduler.cancelled.last, 1);
      expect(provider.quests, isEmpty);
    });

    test('deleting an unknown quest cancels nothing', () async {
      await provider.removeQuestById(42);
      expect(scheduler.cancelled, isEmpty);
    });
  });
}

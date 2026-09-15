import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/quest_list_provider.dart';

import 'helpers/fake_reminder_scheduler.dart';

Quest _quest(
  int id, {
  String title = 'Quest',
  int difficulty = 1,
  DateTime? dueDate,
}) {
  return Quest(
    id: id,
    title: '$title $id',
    description: 'Description $id',
    difficulty: difficulty,
    dueDate: dueDate ?? DateTime(2030, 1, 1, 12),
  );
}

void main() {
  late InMemoryQuestStorage storage;
  late FakeReminderScheduler scheduler;
  late QuestListProvider provider;
  final now = DateTime(2029, 12, 31, 15);

  setUp(() {
    storage = InMemoryQuestStorage();
    scheduler = FakeReminderScheduler();
    provider = QuestListProvider(
      storage: storage,
      scheduler: scheduler,
      now: () => now,
    );
  });

  group('QuestListProvider', () {
    test('updateQuest only changes the quest with the matching id', () async {
      await provider.addQuest(_quest(1));
      await provider.addQuest(_quest(2));
      await provider.addQuest(_quest(3));

      await provider.updateQuest(_quest(3).copyWith(title: 'Updated'));

      expect(provider.quests.map((q) => q.id), [1, 2, 3]);
      expect(provider.quests[0].title, 'Quest 1');
      expect(provider.quests[1].title, 'Quest 2');
      expect(provider.quests[2].title, 'Updated');
    });

    test('updateQuest with an unknown id is a no-op', () async {
      await provider.addQuest(_quest(1));
      final saves = storage.questSaveCount;

      await provider.updateQuest(_quest(99));

      expect(provider.quests.length, 1);
      expect(storage.questSaveCount, saves);
    });

    test('removeQuest removes only the given quest', () async {
      final second = _quest(2);
      await provider.addQuest(_quest(1));
      await provider.addQuest(second);
      await provider.addQuest(_quest(3));

      await provider.removeQuest(second);

      expect(provider.quests.map((q) => q.id), [1, 3]);
    });

    test('nextQuestId produces unique, increasing ids', () async {
      expect(provider.nextQuestId(), 1);

      final ids = <int>{};
      for (var i = 0; i < 100; i++) {
        final id = provider.nextQuestId();
        expect(ids.add(id), isTrue, reason: 'id $id was generated twice');
        await provider.addQuest(_quest(id));
      }

      expect(ids.length, 100);
      expect(provider.nextQuestId(), 101);
    });

    test('nextQuestId skips gaps left by deleted quests', () async {
      await provider.addQuest(_quest(1));
      await provider.addQuest(_quest(5));
      await provider.removeQuestById(1);
      expect(provider.nextQuestId(), 6);
    });

    test('markQuestCompleted and getFilteredQuests', () async {
      await provider.addQuest(_quest(1));
      await provider.addQuest(_quest(2));

      await provider.markQuestCompleted(_quest(1));

      expect(provider.getFilteredQuests(null).length, 2);
      expect(
        provider.getFilteredQuests(QuestStatus.completed).map((q) => q.id),
        [1],
      );
      expect(
        provider.getFilteredQuests(QuestStatus.inProgress).map((q) => q.id),
        [2],
      );
      expect(provider.completedQuests.length, 1);
      expect(provider.inProgressQuests.length, 1);
    });

    test('persists through storage and reloads', () async {
      await provider.addQuest(_quest(1, difficulty: 3));
      await provider.addQuest(_quest(2));
      await provider.markQuestCompleted(_quest(2));

      final reloaded = QuestListProvider(storage: storage);
      await reloaded.loadQuestsFromStorage();

      expect(reloaded.quests, provider.quests);
      expect(reloaded.quests[0].xpReward, 150);
      expect(reloaded.quests[1].isCompleted, isTrue);
    });

    test('completing stamps completedAt and counts toward today', () async {
      await provider.addQuest(_quest(1));
      await provider.addQuest(_quest(2));

      await provider.markQuestCompleted(_quest(1));

      expect(provider.questById(1)!.completedAt, now);
      expect(provider.completedTodayCount, 1);
      expect(provider.completedOn(now.subtract(const Duration(days: 1))), 0);

      // Reopening clears the stamp.
      await provider.updateQuestStatus(1, QuestStatus.inProgress);
      expect(provider.questById(1)!.completedAt, isNull);
      expect(provider.completedTodayCount, 0);
    });

    test(
      'in-progress quests are sorted by due date, completed by recency',
      () async {
        await provider.addQuest(_quest(1, dueDate: DateTime(2030, 3, 1)));
        await provider.addQuest(_quest(2, dueDate: DateTime(2030, 1, 1)));
        await provider.addQuest(_quest(3, dueDate: DateTime(2030, 2, 1)));
        await provider.addQuest(_quest(4, dueDate: DateTime(2030, 2, 2)));

        expect(
          provider.getFilteredQuests(QuestStatus.inProgress).map((q) => q.id),
          [2, 3, 4, 1],
        );

        await provider.markQuestCompleted(_quest(4));
        await provider.updateQuest(
          provider
              .questById(3)!
              .copyWith(
                status: QuestStatus.completed,
                completedAt: now.add(const Duration(hours: 1)),
              ),
        );

        expect(provider.completedQuests.map((q) => q.id), [3, 4]);
        // "All": in-progress first (by due date), then completed (latest first).
        expect(provider.getFilteredQuests(null).map((q) => q.id), [2, 1, 3, 4]);
        // Insertion order is still available.
        expect(provider.quests.map((q) => q.id), [1, 2, 3, 4]);
      },
    );

    test('overdueQuests lists in-progress quests past due', () async {
      await provider.addQuest(
        _quest(1, dueDate: now.subtract(const Duration(hours: 1))),
      );
      await provider.addQuest(
        _quest(2, dueDate: now.add(const Duration(hours: 1))),
      );
      await provider.addQuest(
        _quest(3, dueDate: now.subtract(const Duration(days: 2))),
      );
      await provider.markQuestCompleted(_quest(3));

      expect(provider.overdueQuests.map((q) => q.id), [1]);
    });
    test('deleteQuest on storage removes only the given quest', () async {
      await storage.saveQuests([_quest(1), _quest(2), _quest(3)]);

      await storage.deleteQuest(_quest(2));

      final remaining = await storage.loadQuests();
      expect(remaining.map((q) => q.id), [1, 3]);
    });
  });
}

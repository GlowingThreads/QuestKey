import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Creating a quest adds it to storage', () async {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance = SharedPrefsQuestStorage();

    final quest = Quest(
      id: 1,
      title: 'Test Quest',
      description: 'Defeat the dragon',
      difficulty: 1,
      dueDate: DateTime(2024, 4, 19),
    );

    await StorageService.saveQuests([quest]);

    final loaded = await StorageService.loadQuests();

    expect(loaded.length, greaterThan(0));
    expect(loaded.first.title, equals('Test Quest'));
    expect(loaded.first.status, equals(QuestStatus.inProgress));
    expect(loaded.first, equals(quest));
  });

  test('Completing a quest updates its status', () {
    final quest = Quest(
      id: 2,
      title: 'Slay the beast',
      description: 'Vanquish evil',
      difficulty: 2,
      dueDate: DateTime(2030),
    );

    final updated = quest.copyWith(status: QuestStatus.completed);

    expect(updated.status, equals(QuestStatus.completed));
    expect(updated.isCompleted, isTrue);
    expect(updated.title, equals('Slay the beast'));
    expect(quest.status, equals(QuestStatus.inProgress));
  });

  test('xpReward is derived from difficulty', () {
    final quest = Quest(
      id: 3,
      title: 'Hard',
      description: '',
      difficulty: 4,
      dueDate: DateTime(2030),
    );
    expect(quest.xpReward, 200);
    expect(quest.copyWith(difficulty: 1).xpReward, 50);
    // Out-of-range difficulties are clamped.
    expect(quest.copyWith(difficulty: 9).difficulty, maxDifficulty);
    expect(quest.copyWith(difficulty: 0).difficulty, minDifficulty);
  });

  test('QuestStatus.fromString falls back to inProgress', () {
    expect(QuestStatus.fromString('Completed'), QuestStatus.completed);
    expect(QuestStatus.fromString('completed'), QuestStatus.completed);
    expect(QuestStatus.fromString('In Progress'), QuestStatus.inProgress);
    expect(QuestStatus.fromString('garbage'), QuestStatus.inProgress);
    expect(QuestStatus.fromString(null), QuestStatus.inProgress);
  });
}

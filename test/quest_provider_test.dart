import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Quest _quest(int id, {String title = 'Quest'}) {
  return Quest(
    id: id,
    title: '$title $id',
    description: 'Description $id',
    status: 'In Progress',
    xpReward: 50,
    startDate: '2030-01-01 12:00:00.000',
    endDate: '2030-01-01 12:00:00.000',
    timeRemaining: '1 day',
    questImageUrl: 'assets/images/app_assets/todo.png',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuestListProvider', () {
    test('updateQuest only changes the quest with the matching id', () {
      final provider = QuestListProvider();
      provider.addQuest(_quest(1));
      provider.addQuest(_quest(2));
      provider.addQuest(_quest(3));

      provider.updateQuest(_quest(3).copyWith(title: 'Updated'));

      expect(provider.quests.map((q) => q.id), [1, 2, 3]);
      expect(provider.quests[0].title, 'Quest 1');
      expect(provider.quests[1].title, 'Quest 2');
      expect(provider.quests[2].title, 'Updated');
    });

    test('removeQuest removes only the given quest', () {
      final provider = QuestListProvider();
      final second = _quest(2);
      provider.addQuest(_quest(1));
      provider.addQuest(second);
      provider.addQuest(_quest(3));

      provider.removeQuest(second);

      expect(provider.quests.map((q) => q.id), [1, 3]);
    });

    test('nextQuestId produces unique, increasing ids', () {
      final provider = QuestListProvider();
      expect(provider.nextQuestId(), 1);

      final ids = <int>{};
      for (var i = 0; i < 100; i++) {
        final id = provider.nextQuestId();
        expect(ids.add(id), isTrue, reason: 'id $id was generated twice');
        provider.addQuest(_quest(id));
      }

      expect(ids.length, 100);
      expect(provider.nextQuestId(), 101);
    });
  });

  group('StorageService', () {
    test('deleteQuest removes only the given quest', () async {
      await StorageService.saveQuests([_quest(1), _quest(2), _quest(3)]);

      await StorageService.deleteQuest(_quest(2));

      final remaining = await StorageService.loadQuests();
      expect(remaining.map((q) => q.id), [1, 3]);
    });
  });
}

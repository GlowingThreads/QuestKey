import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/services/storage.dart';
import 'package:quest_key/models/quest.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Creating a quest adds it to storage', () async {
    SharedPreferences.setMockInitialValues({});

    final quest = Quest(
      id: 1,
      title: 'Test Quest',
      description: 'Defeat the dragon',
      status: 'In Progress',
      xpReward: 50,
      startDate: '2024-04-18',
      endDate: '2024-04-19',
      timeRemaining: '1 day',
      questImageUrl: 'assets/images/app_assets/todo.png',
    );

    await StorageService.saveQuests([quest]);

    final loaded = await StorageService.loadQuests();

    expect(loaded.length, greaterThan(0));
    expect(loaded.first.title, equals('Test Quest'));
    expect(loaded.first.status, equals('In Progress'));
  });

  test('Completing a quest updates its status', () {
    final quest = Quest(
      id: 2,
      title: 'Slay the beast',
      description: 'Vanquish evil',
      status: 'In Progress',
      xpReward: 20,
      startDate: 'now',
      endDate: 'later',
      timeRemaining: '?',
      questImageUrl: '',
    );

    final updated = quest.copyWith(status: 'Completed');

    expect(updated.status, equals('Completed'));
    expect(updated.title, equals('Slay the beast'));
  });
}

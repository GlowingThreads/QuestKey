import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/level_up.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/widgets/quest_list.dart';

import '../helpers/fake_reminder_scheduler.dart';
import '../helpers/pump_app.dart';

void main() {
  late InMemoryQuestStorage storage;
  late FakeReminderScheduler scheduler;
  late QuestListProvider questProvider;
  late AppState appState;

  Quest quest(int id) => Quest(
    id: id,
    title: 'Quest $id',
    description: 'Description $id',
    dueDate: DateTime(2030, 1, 1),
    remindMe: true,
  );

  setUp(() async {
    storage = InMemoryQuestStorage();
    scheduler = FakeReminderScheduler();
    questProvider = QuestListProvider(storage: storage, scheduler: scheduler);
    appState = AppState(storage: storage);
    await appState.saveHero(
      HeroCharacter(
        name: 'Hero',
        motto: 'm',
        classes: fighter,
        description: '',
        imageUrl: 'assets/images/character_images/hero_1.png',
        levelUp: const LevelUp(level: 1, exp: 0, maxExp: 100),
      ),
    );
    await questProvider.saveQuest(quest(1));
    await questProvider.saveQuest(quest(2));
  });

  Future<void> pumpList(WidgetTester tester, {QuestStatus? filter}) {
    return pumpApp(
      tester,
      appState: appState,
      questProvider: questProvider,
      child: QuestList(filterStatus: filter),
    );
  }

  testWidgets('shows the quests for the filter', (tester) async {
    await pumpList(tester, filter: QuestStatus.inProgress);

    expect(find.text('Quest 1'), findsOneWidget);
    expect(find.text('Quest 2'), findsOneWidget);
    expect(find.byType(Dismissible), findsNWidgets(2));
  });

  testWidgets('shows an empty message when there is nothing to show', (
    tester,
  ) async {
    await pumpList(tester, filter: QuestStatus.completed);
    expect(find.text('No quests available'), findsOneWidget);
  });

  testWidgets('swiping right completes the quest and awards XP', (
    tester,
  ) async {
    await pumpList(tester, filter: QuestStatus.inProgress);

    await tester.drag(find.text('Quest 1'), const Offset(600, 0));
    await tester.pumpAndSettle();

    final completed = questProvider.questById(1)!;
    expect(completed.isCompleted, isTrue);
    expect(questProvider.completedQuests.map((q) => q.id), [1]);
    // Quest 1 left the in-progress list, quest 2 is still there.
    expect(find.text('Quest 1'), findsNothing);
    expect(find.text('Quest 2'), findsOneWidget);
    // Hero got the XP, its reminder was cancelled, and it was persisted.
    expect(appState.hero!.levelUp.exp, quest(1).xpReward);
    expect(appState.hero!.questsCompleted, 1);
    expect(scheduler.pending, {2});
    expect(
      (await storage.loadQuests()).firstWhere((q) => q.id == 1).isCompleted,
      isTrue,
    );
    expect(find.textContaining('Completed "Quest 1"'), findsOneWidget);
  });

  testWidgets('swiping left removes the quest', (tester) async {
    await pumpList(tester, filter: QuestStatus.inProgress);

    await tester.drag(find.text('Quest 2'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(questProvider.questById(2), isNull);
    expect(questProvider.quests.map((q) => q.id), [1]);
    expect(find.text('Quest 2'), findsNothing);
    expect(find.text('Quest 1'), findsOneWidget);
    expect(scheduler.pending, {1});
    expect(appState.hero!.levelUp.exp, 0, reason: 'no XP for deleting');
    expect(find.textContaining('Deleted "Quest 2"'), findsOneWidget);
  });

  testWidgets('the "All" list only allows deleting, not completing', (
    tester,
  ) async {
    await pumpList(tester);

    final dismissible = tester.widget<Dismissible>(
      find.byType(Dismissible).first,
    );
    expect(dismissible.direction, DismissDirection.endToStart);
  });

  testWidgets('tapping an in-progress quest selects it for editing', (
    tester,
  ) async {
    await pumpList(tester, filter: QuestStatus.inProgress);

    await tester.tap(find.text('Quest 1'));
    await tester.pump();

    expect(questProvider.selectedQuest?.id, 1);
    expect(appState.currentIndex, 2);
  });
}

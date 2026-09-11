import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/pages/create_quest.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';

import '../helpers/fake_reminder_scheduler.dart';
import '../helpers/pump_app.dart';

void main() {
  late InMemoryQuestStorage storage;
  late FakeReminderScheduler scheduler;
  late QuestListProvider questProvider;
  late AppState appState;

  setUp(() {
    storage = InMemoryQuestStorage();
    scheduler = FakeReminderScheduler();
    questProvider = QuestListProvider(storage: storage, scheduler: scheduler);
    appState = AppState(storage: storage);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      appState: appState,
      questProvider: questProvider,
      child: const CreateQuestPage(),
    );
  }

  /// Opens the date picker then the time picker and accepts both defaults.
  Future<void> pickDueDate(WidgetTester tester) async {
    await tester.tap(find.text('Pick Due Date & Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('submitting with an empty title shows a validation error', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('Create Quest'));
    await tester.pumpAndSettle();

    expect(find.text('Every good quest needs a name!'), findsOneWidget);
    expect(
      find.text('Write an objective to complete the quest!'),
      findsOneWidget,
    );
    expect(questProvider.quests, isEmpty);
  });

  testWidgets('a valid submit adds exactly one quest', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quest Name'),
      'Walk the dog',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quest Description'),
      'Around the block',
    );
    await pickDueDate(tester);
    expect(find.textContaining('Due:'), findsOneWidget);

    await tester.tap(find.text('Create Quest'));
    await tester.pumpAndSettle();

    expect(questProvider.quests.length, 1);
    final quest = questProvider.quests.single;
    expect(quest.id, 1);
    expect(quest.title, 'Walk the dog');
    expect(quest.description, 'Around the block');
    expect(quest.status, QuestStatus.inProgress);
    expect(quest.difficulty, minDifficulty);
    expect(quest.remindMe, isFalse);
    expect(scheduler.scheduled, isEmpty);
    expect((await storage.loadQuests()).length, 1);
    // Navigates to the Quest Log tab and resets the form.
    expect(appState.currentIndex, 1);
    expect(find.text('Walk the dog'), findsNothing);
  });

  testWidgets('a quick-start template fills the form and category', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('💧 Drink water'));
    await tester.pump();
    await tester.tap(find.text('Today 6 pm'));
    await tester.pump();
    await tester.ensureVisible(find.text('Create Quest'));
    await tester.tap(find.text('Create Quest'));
    await tester.pumpAndSettle();

    final quest = questProvider.quests.single;
    expect(quest.title, 'Drink water');
    expect(quest.description, 'Drink 8 glasses of water today');
    expect(quest.category, QuestCategory.health);
    expect(quest.dueDate.hour, 18);
  });

  testWidgets('a category can be chosen', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quest Name'),
      'Essay',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quest Description'),
      'Write the intro',
    );
    await tester.ensureVisible(find.text('📚 Study'));
    await tester.tap(find.text('📚 Study'));
    await tester.pump();
    await tester.ensureVisible(find.text('Tomorrow 9 am'));
    await tester.tap(find.text('Tomorrow 9 am'));
    await tester.pump();
    await tester.ensureVisible(find.text('Create Quest'));
    await tester.tap(find.text('Create Quest'));
    await tester.pumpAndSettle();

    expect(questProvider.quests.single.category, QuestCategory.study);
  });

  testWidgets('submitting without a due date does nothing', (tester) async {
    await pumpPage(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quest Name'),
      'No date',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quest Description'),
      'desc',
    );

    await tester.tap(find.text('Create Quest'));
    await tester.pumpAndSettle();

    expect(questProvider.quests, isEmpty);
  });

  testWidgets('ticking "Remind me" asks for permission; denial unticks it', (
    tester,
  ) async {
    scheduler.permissionGranted = false;
    await pumpPage(tester);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.value, isFalse);
    expect(find.textContaining('Notifications are turned off'), findsOneWidget);
  });

  testWidgets('ticking "Remind me" with permission keeps it ticked', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.value, isTrue);
  });

  testWidgets('editing a selected quest pre-fills the form', (tester) async {
    await questProvider.saveQuest(
      Quest(
        id: 7,
        title: 'Existing',
        description: 'Already here',
        difficulty: 4,
        dueDate: DateTime(2031, 5, 6, 7, 8),
        remindMe: true,
      ),
    );
    questProvider.setSelectedQuest(questProvider.questById(7));

    await pumpPage(tester);

    expect(find.text('Edit Quest'), findsOneWidget);
    expect(find.text('Update Quest'), findsOneWidget);
    expect(find.text('Existing'), findsOneWidget);
    expect(find.text('Already here'), findsOneWidget);
    expect(find.textContaining('2031-05-06'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 4);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
  });
}

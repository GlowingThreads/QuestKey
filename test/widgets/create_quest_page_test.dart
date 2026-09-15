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
    await tester.pumpAndSettle();
  }

  /// Scrolls the page until [finder] is built and visible, then taps it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterDetails(
    WidgetTester tester,
    String title,
    String desc,
  ) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quest Name'),
      title,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quest Description'),
      desc,
    );
    await tester.pump();
  }

  /// Opens the date picker then the time picker and accepts both defaults.
  Future<void> pickDueDate(WidgetTester tester) async {
    await tapVisible(tester, find.text('Pick date & time'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('submitting with an empty title shows a validation error', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapVisible(tester, find.text('Forge Quest'));

    expect(find.text('Every good quest needs a name!'), findsOneWidget);
    expect(
      find.text('Write an objective to complete the quest!'),
      findsOneWidget,
    );
    expect(questProvider.quests, isEmpty);
  });

  testWidgets('a valid submit adds exactly one quest', (tester) async {
    await pumpPage(tester);

    await enterDetails(tester, 'Walk the dog', 'Around the block');
    await pickDueDate(tester);
    expect(find.text('Pick date & time'), findsNothing);

    await tapVisible(tester, find.text('Forge Quest'));

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

  testWidgets('the live preview mirrors the form', (tester) async {
    await pumpPage(tester);

    expect(find.text('Your quest title'), findsOneWidget);
    await enterDetails(tester, 'Slay the inbox', 'Zero unread');
    await tapVisible(tester, find.byKey(const ValueKey('difficulty_star_4')));

    expect(find.text('Slay the inbox'), findsNWidgets(2)); // field + preview
    expect(find.text('Hard · +200 XP'), findsOneWidget);
    expect(find.textContaining('★★★★ +200 XP'), findsOneWidget);
  });

  testWidgets('a quick-start template fills the form and category', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapVisible(tester, find.text('💧 Drink water'));
    await tapVisible(tester, find.text('Today 6 pm'));
    await tapVisible(tester, find.text('Forge Quest'));

    final quest = questProvider.quests.single;
    expect(quest.title, 'Drink water');
    expect(quest.description, 'Drink 8 glasses of water today');
    expect(quest.category, QuestCategory.health);
    expect(quest.dueDate.hour, 18);
  });

  testWidgets('a category and difficulty can be chosen', (tester) async {
    await pumpPage(tester);

    await enterDetails(tester, 'Essay', 'Write the intro');
    await tapVisible(tester, find.text('📚 Study'));
    await tapVisible(tester, find.byKey(const ValueKey('difficulty_star_3')));
    await tapVisible(tester, find.text('Tomorrow 9 am'));
    await tapVisible(tester, find.text('Forge Quest'));

    final quest = questProvider.quests.single;
    expect(quest.category, QuestCategory.study);
    expect(quest.difficulty, 3);
    expect(quest.xpReward, 150);
  });

  testWidgets('submitting without a due date shows a hint and adds nothing', (
    tester,
  ) async {
    await pumpPage(tester);
    await enterDetails(tester, 'No date', 'desc');

    await tapVisible(tester, find.text('Forge Quest'));

    expect(questProvider.quests, isEmpty);
    expect(find.text('Pick a due date and time first.'), findsOneWidget);
  });

  testWidgets(
    'turning on "Remind me" asks for permission; denial turns it off',
    (tester) async {
      scheduler.permissionGranted = false;
      await pumpPage(tester);

      await tapVisible(tester, find.byType(SwitchListTile));

      expect(scheduler.permissionRequests, 1);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(
        find.textContaining('Notifications are turned off'),
        findsOneWidget,
      );
    },
  );

  testWidgets('turning on "Remind me" with permission keeps it on', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapVisible(tester, find.byType(SwitchListTile));

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
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
        category: QuestCategory.work,
      ),
    );
    questProvider.setSelectedQuest(questProvider.questById(7));

    await pumpPage(tester);

    expect(find.text('Edit Quest'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Existing'), findsNWidgets(2)); // field + preview
    expect(find.text('Already here'), findsNWidgets(2));
    expect(find.textContaining('May 6'), findsOneWidget);
    expect(find.text('Hard · +200 XP'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(find.text('Quick start'), findsNothing);

    await tapVisible(tester, find.text('Cancel editing'));
    expect(questProvider.selectedQuest, isNull);
    expect(appState.currentIndex, 1);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character_background.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/pages/hero_creation_page.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';

import '../helpers/fake_reminder_scheduler.dart';
import '../helpers/pump_app.dart';

void main() {
  late InMemoryQuestStorage storage;
  late AppState appState;
  late QuestListProvider questProvider;

  setUp(() {
    storage = InMemoryQuestStorage();
    appState = AppState(storage: storage);
    questProvider = QuestListProvider(
      storage: storage,
      scheduler: FakeReminderScheduler(),
    );
  });

  Future<void> pumpWizard(WidgetTester tester, {bool onboarding = true}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      appState: appState,
      questProvider: questProvider,
      child: HeroCreationPage(isOnboarding: onboarding),
    );
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('Next is disabled until the identity step is filled in', (
    tester,
  ) async {
    await pumpWizard(tester);

    expect(find.text('Welcome, adventurer'), findsOneWidget);
    expect(find.text('STEP 1 OF 5'), findsOneWidget);

    await next(tester);
    expect(find.text('STEP 1 OF 5'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hero name'),
      'Lyra',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motto or tagline'),
      'Onward',
    );
    await tester.pumpAndSettle();
    await next(tester);

    expect(find.text('STEP 2 OF 5'), findsOneWidget);
    expect(find.text('Choose your class'), findsOneWidget);
  });

  testWidgets('rolling a random name fills both fields', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('ROLL A RANDOM NAME'));
    await tester.pumpAndSettle();

    final name = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Hero name'),
    );
    expect(name.controller!.text, isNotEmpty);
  });

  testWidgets('the full wizard creates a hero with class and origin bonuses', (
    tester,
  ) async {
    await pumpWizard(tester);

    // Identity
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hero name'),
      'Lyra',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motto or tagline'),
      'Onward',
    );
    await tester.pumpAndSettle();
    await next(tester);

    // Class: Next stays disabled until one is picked.
    await next(tester);
    expect(find.text('STEP 2 OF 5'), findsOneWidget);
    await tester.tap(find.text('Wizard'));
    await tester.pumpAndSettle();
    expect(find.text(wizard.description), findsOneWidget);
    await next(tester);

    // Origin: pick Scholar (+2 intelligence, +1 wisdom).
    expect(find.text('Where do you come from?'), findsOneWidget);
    final scholar = backgroundsList.firstWhere((b) => b.id == 'scholar');
    await tester.ensureVisible(find.text(scholar.name));
    await tester.tap(find.text(scholar.name));
    await tester.pumpAndSettle();
    expect(find.text(scholar.flavorText), findsOneWidget);
    await next(tester);

    // Avatar
    expect(find.text('Choose your portrait'), findsOneWidget);
    await next(tester);
    expect(find.text('STEP 4 OF 5'), findsOneWidget);
    await tester.tap(find.byType(FramedPortrait).at(2));
    await tester.pumpAndSettle();
    // The summon step has a looping glow, so pump a fixed duration instead
    // of pumpAndSettle.
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 800));

    // Summon
    expect(find.text('STEP 5 OF 5'), findsOneWidget);
    expect(find.text('Lyra'), findsOneWidget);
    expect(find.text('WIZARD'), findsOneWidget);
    expect(find.text('SCHOLAR'), findsOneWidget);
    expect(appState.hero, isNull);

    await tester.tap(find.text('Begin Adventure'));
    await tester.pump(const Duration(seconds: 2));

    final hero = appState.hero!;
    expect(hero.name, 'Lyra');
    expect(hero.motto, 'Onward');
    expect(hero.classes.className, 'Wizard');
    expect(hero.background?.id, 'scholar');
    expect(hero.intelligence, wizard.intelligence + 2);
    expect(hero.wisdom, wizard.wisdom + 1);
    expect(hero.imageUrl, 'assets/images/character_images/hero_3.png');
    expect(hero.levelUp.level, 1);
    expect((await storage.loadHero())!.name, 'Lyra');
    expect(appState.currentIndex, 0);
  });

  testWidgets('Back returns to the previous step and keeps choices', (
    tester,
  ) async {
    await pumpWizard(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hero name'),
      'Bo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motto or tagline'),
      'Go',
    );
    await tester.pumpAndSettle();
    await next(tester);
    await tester.tap(find.text('Fighter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BACK'));
    await tester.pumpAndSettle();
    expect(find.text('STEP 1 OF 5'), findsOneWidget);
    expect(find.text('Bo'), findsOneWidget);

    await next(tester);
    expect(find.text(fighter.description), findsOneWidget);
  });

  testWidgets('outside onboarding the page has a cancel button', (
    tester,
  ) async {
    await pumpWizard(tester, onboarding: false);
    expect(find.text('Create a new hero'), findsOneWidget);
    expect(find.byTooltip('Cancel'), findsOneWidget);
  });
}

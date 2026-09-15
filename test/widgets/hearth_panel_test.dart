import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/models/familiar.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/widgets/familiar/familiar_sprite.dart';
import 'package:quest_key/widgets/familiar/hearth_panel.dart';

import '../helpers/fake_reminder_scheduler.dart';
import '../helpers/heroes.dart';
import '../helpers/pump_app.dart';

void main() {
  final now = DateTime(2030, 6, 1, 12);

  testWidgets('a stray can be adopted, named and petted', (tester) async {
    final storage = InMemoryQuestStorage();
    final appState = AppState(
      storage: storage,
      now: () => now,
      roll: () => 0.99,
    );
    await appState.saveHero(makeHero(restedOn: now));
    final quests = QuestListProvider(
      storage: storage,
      scheduler: FakeReminderScheduler(),
      now: () => now,
    );

    await pumpApp(
      tester,
      appState: appState,
      questProvider: quests,
      child: Consumer<AppState>(
        builder: (_, state, _) => HearthPanel(hero: state.hero!),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('The Hearth'), findsOneWidget);

    await tester.tap(find.text('Adopt a familiar'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ADOPT A FAMILIAR'), findsOneWidget);

    await tester.tap(find.text('OWL'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'Quill');
    await tester.tap(find.text('Adopt'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(appState.hero!.familiar!.species, FamiliarSpecies.owl);
    expect(appState.hero!.familiar!.name, 'Quill');
    expect(appState.hero!.hasAchievement('hearth_friend'), isTrue);
    expect((await storage.loadHero())!.familiar!.name, 'Quill');

    // The honour dialog appears; dismiss it.
    expect(find.text('Hearth Friend'), findsOneWidget);
    await tester.tap(find.text('Nice!'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Quill'), findsOneWidget);
    expect(find.text('SHADOW OWL · STRAY'), findsOneWidget);
    expect(find.text('BOND 0/10'), findsOneWidget);

    await tester.tap(find.byType(FamiliarSprite));
    await tester.pump(const Duration(milliseconds: 700));
    expect(appState.hero!.familiar!.timesPetted, 1);
    // The adoption toast is dismissed first, then the reply shows.
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('fluffs up'), findsOneWidget);
  });
}

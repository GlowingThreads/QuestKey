import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/encounter.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/encounter_provider.dart';
import 'package:quest_key/state/quest_list_provider.dart';

import 'helpers/fake_reminder_scheduler.dart';
import 'package:quest_key/models/level_up.dart';

import 'helpers/heroes.dart';

void main() {
  final now = DateTime(2030, 6, 1, 12);

  /// A day on which the deterministic roll produces an encounter.
  DateTime dayWithEncounter() {
    var day = now;
    for (var i = 0; i < 30; i++) {
      if (rollEncounter(day, makeHero()) != null) return day;
      day = day.add(const Duration(days: 1));
    }
    fail('no encounter in 30 days');
  }

  test('rolling is deterministic per day and hero', () {
    final day = dayWithEncounter();
    final a = rollEncounter(day, makeHero());
    final b = rollEncounter(day, makeHero());
    expect(a!.templateId, b!.templateId);
    expect(a.day, DateTime(day.year, day.month, day.day));
  });

  test('templates respect level gates', () {
    final low = makeHero(levelUp: const LevelUp(level: 1));
    for (var i = 0; i < 60; i++) {
      final e = rollEncounter(now.add(Duration(days: i)), low);
      if (e != null) expect(e.template.minLevel, lessThanOrEqualTo(1));
    }
  });

  test('accept creates a bonus quest and persists the encounter', () async {
    final day = dayWithEncounter();
    final storage = InMemoryQuestStorage();
    final appState = AppState(
      storage: storage,
      now: () => day,
      roll: () => 0.99,
    );
    await appState.saveHero(makeHero());
    final quests = QuestListProvider(
      storage: storage,
      scheduler: FakeReminderScheduler(),
      now: () => day,
    );
    final provider = EncounterProvider(
      appState: appState,
      quests: quests,
      storage: storage,
    );

    await provider.refresh();
    expect(provider.open, isNotNull);
    final template = provider.open!.template;

    final outcome = await provider.accept();
    expect(outcome.success, isTrue);
    expect(provider.open, isNull);
    expect(quests.quests.single.xpBonusPercent, template.bonusPercent);
    expect(quests.quests.single.title, template.questTitle);

    // Reloading the same day keeps it resolved; a new day rolls afresh.
    final again = EncounterProvider(
      appState: appState,
      quests: quests,
      storage: storage,
    );
    await again.refresh();
    expect(again.encounter!.status, EncounterStatus.accepted);
  });

  test('slip past needs Stealth and pays a little XP', () async {
    final day = dayWithEncounter();
    final storage = InMemoryQuestStorage();
    final appState = AppState(
      storage: storage,
      now: () => day,
      roll: () => 0.99,
    );
    await appState.saveHero(makeHero(skills: ['stealth']));
    final quests = QuestListProvider(
      storage: storage,
      scheduler: FakeReminderScheduler(),
      now: () => day,
    );
    final provider = EncounterProvider(
      appState: appState,
      quests: quests,
      storage: storage,
    );
    await provider.refresh();

    final outcome = await provider.slipPast();
    expect(outcome.success, isTrue);
    expect(outcome.xpGained, 25);
    expect(appState.hero!.encountersResolved, 1);
    expect(appState.hero!.stamina, lessThan(appState.hero!.maxStamina));
    expect(
      outcome.unlocked.map((a) => a.id),
      containsAll(['encounter_victor', 'spell_caster']),
    );
  });

  test('confront: luck decides, failure burns the torch', () async {
    final day = dayWithEncounter();
    final storage = InMemoryQuestStorage();
    final lose = AppState(storage: storage, now: () => day, roll: () => 0.95);
    await lose.saveHero(makeHero(skills: ['fireball']));
    final quests = QuestListProvider(
      storage: storage,
      scheduler: FakeReminderScheduler(),
      now: () => day,
    );
    final provider = EncounterProvider(
      appState: lose,
      quests: quests,
      storage: storage,
    );
    await provider.refresh();

    final outcome = await provider.confront();
    expect(outcome.success, isFalse);
    expect(
      lose.hero!.health,
      lose.hero!.maxHealth - (lose.hero!.maxHealth * 0.2).round(),
    );
    expect(provider.open, isNull);

    final storage2 = InMemoryQuestStorage();
    final win = AppState(storage: storage2, now: () => day, roll: () => 0.01);
    await win.saveHero(makeHero(skills: ['fireball']));
    final provider2 = EncounterProvider(
      appState: win,
      quests: quests,
      storage: storage2,
    );
    await provider2.refresh();
    final victory = await provider2.confront();
    expect(victory.success, isTrue);
    expect(victory.xpGained, 120);
  });

  test('decline resolves the day', () async {
    final day = dayWithEncounter();
    final storage = InMemoryQuestStorage();
    final appState = AppState(storage: storage, now: () => day);
    await appState.saveHero(makeHero());
    final quests = QuestListProvider(
      storage: storage,
      scheduler: FakeReminderScheduler(),
      now: () => day,
    );
    final provider = EncounterProvider(
      appState: appState,
      quests: quests,
      storage: storage,
    );
    await provider.refresh();
    await provider.decline();
    expect(provider.open, isNull);
    expect(provider.encounter!.status, EncounterStatus.declined);
  });
}

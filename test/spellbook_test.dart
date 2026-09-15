import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/spells.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/state/spellbook.dart';

import 'helpers/fake_reminder_scheduler.dart';
import 'helpers/heroes.dart';

void main() {
  final now = DateTime(2030, 6, 1, 12);
  late InMemoryQuestStorage storage;
  late AppState appState;
  late QuestListProvider quests;
  late Spellbook spellbook;

  Future<void> setUpHero(List<String> skills) async {
    storage = InMemoryQuestStorage();
    appState = AppState(storage: storage, now: () => now, roll: () => 0.99);
    quests = QuestListProvider(
      storage: storage,
      scheduler: FakeReminderScheduler(),
      now: () => now,
    );
    spellbook = Spellbook(appState: appState, quests: quests);
    await appState.saveHero(
      makeHero(skills: skills, restedOn: now, lastCompletedOn: now, streak: 2),
    );
  }

  Quest quest(int id, {int difficulty = 2, DateTime? due}) => Quest(
    id: id,
    title: 'Quest $id',
    description: 'd',
    difficulty: difficulty,
    dueDate: due ?? now.add(const Duration(days: 1)),
  );

  test('known spells and castability follow learned skills', () async {
    await setUpHero(['heal', 'power_strike']);
    expect(spellbook.known.map((s) => s.skillId), ['heal', 'power_strike']);
    expect(spellbook.castableOn(null).map((s) => s.skillId), ['power_strike']);
    expect(spellbook.castableOn(quest(1)).map((s) => s.skillId), ['heal']);
    expect(
      spellbook.blockedReason(Spell.forSkill('fireball')!),
      'Not learned yet.',
    );
  });

  test('casting spends the resource and records the use', () async {
    await setUpHero(['power_strike']);
    final before = appState.hero!;
    final spell = Spell.forSkill('power_strike')!;
    final cost = spellbook.costOf(spell);

    final result = await spellbook.cast(spell);

    expect(result.success, isTrue);
    expect(appState.hero!.stamina, before.stamina - cost);
    expect(appState.hero!.spellsCast, 1);
    expect(appState.hero!.hasBuff(BuffType.empowered, now), isTrue);
    expect(result.unlocked.map((a) => a.id), contains('spell_caster'));
    expect(spellbook.blockedReason(spell), 'Already empowered.');
  });

  test('cannot cast without enough resource', () async {
    await setUpHero(['fireball']);
    await appState.saveHero(appState.hero!.copyWith(mana: 3));
    await quests.addQuest(quest(1));
    final spell = Spell.forSkill('fireball')!;
    expect(
      spellbook.blockedReason(spell, target: quests.questById(1)),
      contains('Needs 25 MP'),
    );
    final result = await spellbook.cast(spell, target: quests.questById(1));
    expect(result.success, isFalse);
    expect(quests.quests.length, 1);
  });

  test('Heal mends only overdue quests and restores the torch', () async {
    await setUpHero(['heal']);
    await appState.saveHero(appState.hero!.copyWith(health: 20));
    await quests.addQuest(
      quest(1, due: now.subtract(const Duration(hours: 2))),
    );
    await quests.addQuest(quest(2));
    final spell = Spell.forSkill('heal')!;

    expect(
      spellbook.blockedReason(spell, target: quests.questById(2)),
      'Only works on an overdue quest.',
    );
    final result = await spellbook.cast(spell, target: quests.questById(1));

    expect(result.success, isTrue);
    expect(quests.questById(1)!.isOverdueAt(now), isFalse);
    expect(
      quests.questById(1)!.dueDate,
      now.subtract(const Duration(hours: 2)).add(const Duration(days: 1)),
    );
    expect(
      appState.hero!.health,
      20 + (appState.hero!.maxHealth * 0.3).round(),
    );
  });

  test(
    'Stealth snoozes a quest until tomorrow and hides it from Home',
    () async {
      await setUpHero(['stealth']);
      await quests.addQuest(quest(1));
      await spellbook.cast(
        Spell.forSkill('stealth')!,
        target: quests.questById(1),
      );

      final q = quests.questById(1)!;
      expect(q.isSnoozedAt(now), isTrue);
      expect(q.dueDate, now.add(const Duration(days: 2)));
      expect(
        quests.getFilteredQuests(QuestStatus.inProgress, hideSnoozed: true),
        isEmpty,
      );
      expect(quests.getFilteredQuests(QuestStatus.inProgress), hasLength(1));
      expect(q.isSnoozedAt(now.add(const Duration(days: 1))), isFalse);
    },
  );

  test('Fireball removes a quest and salvages a third of its XP', () async {
    await setUpHero(['fireball']);
    await quests.addQuest(quest(1, difficulty: 3)); // 150 XP
    final result = await spellbook.cast(
      Spell.forSkill('fireball')!,
      target: quests.questById(1),
    );
    expect(result.success, isTrue);
    expect(result.xpGained, 50);
    expect(quests.quests, isEmpty);
    expect(appState.hero!.levelUp.exp, 50);
    expect(
      appState.hero!.questsCompleted,
      0,
      reason: 'burning is not completing',
    );
  });

  test('shields stack to the cap', () async {
    await setUpHero(['shield_bash', 'mana_shield']);
    await spellbook.cast(Spell.forSkill('mana_shield')!);
    expect(appState.hero!.shieldCharges, 2);
    await spellbook.cast(Spell.forSkill('shield_bash')!);
    expect(appState.hero!.shieldCharges, 3);
    expect(
      spellbook.blockedReason(Spell.forSkill('shield_bash')!),
      'Shields are already at full strength.',
    );
  });

  test('Whirlwind sweeps every Trivial quest with a bonus', () async {
    await setUpHero(['whirlwind']);
    await quests.addQuest(quest(1, difficulty: 1));
    await quests.addQuest(quest(2, difficulty: 1));
    await quests.addQuest(quest(3, difficulty: 3));
    final result = await spellbook.cast(Spell.forSkill('whirlwind')!);
    expect(result.success, isTrue);
    expect(result.xpGained, 110); // 2 × (50 + 10%)
    expect(quests.completedQuests.map((q) => q.id), containsAll([1, 2]));
    expect(quests.questById(3)!.isCompleted, isFalse);
    expect(appState.hero!.questsCompleted, 2);
    expect(
      spellbook.blockedReason(Spell.forSkill('whirlwind')!),
      'No Trivial quests to sweep.',
    );
  });

  test('a completion consumes buffs and reports the breakdown', () async {
    await setUpHero(['power_strike']);
    await spellbook.cast(Spell.forSkill('power_strike')!);
    await quests.addQuest(quest(1, difficulty: 4));
    final result = await appState.completeQuestForHero(
      0,
      quest: quests.questById(1),
    );
    expect(result.xpGained, 300);
    expect(result.breakdown!.summary, '200 XP · Empowered +50%');
    expect(appState.hero!.hasBuff(BuffType.empowered, now), isFalse);
  });

  test('critical completions double XP and count', () async {
    storage = InMemoryQuestStorage();
    appState = AppState(storage: storage, now: () => now, roll: () => 0.01);
    await appState.saveHero(makeHero(luck: 4));
    final result = await appState.completeQuestForHero(0, quest: quest(1));
    expect(result.critical, isTrue);
    expect(result.xpGained, 200);
    expect(appState.hero!.criticalHits, 1);
    expect(
      result.unlockedAchievements.map((a) => a.id),
      contains('lucky_strike'),
    );
  });

  test(
    'processNewDay applies rest and awards Torch Bearer for surviving',
    () async {
      await setUpHero([]);
      final later = now.add(const Duration(days: 2));
      final state = AppState(
        storage: storage,
        now: () => later,
        roll: () => 0.99,
      );
      await state.loadHeroFromStorage();
      final report = await state.processNewDay();
      expect(report!.missedDays, 1);
      expect(state.hero!.health, lessThan(state.hero!.maxHealth));
      expect(state.hero!.hasAchievement('torch_bearer'), isTrue);
      expect(state.lastRest, isNotNull);
      state.dismissRestReport();
      expect(state.lastRest, isNull);
    },
  );

  test('boss quests complete only when every step is done', () async {
    await setUpHero([]);
    await quests.addQuest(
      Quest(
        id: 1,
        title: 'Dragon',
        description: 'd',
        dueDate: now,
        difficulty: 5,
        steps: const [QuestStep(title: 'Find it'), QuestStep(title: 'Slay it')],
      ),
    );
    await quests.toggleStep(1, 0);
    expect(quests.questById(1)!.stepsDone, 1);
    expect(quests.questById(1)!.allStepsDone, isFalse);
    await quests.toggleStep(1, 1);
    expect(quests.questById(1)!.allStepsDone, isTrue);
    final result = await appState.completeQuestForHero(
      0,
      quest: quests.questById(1),
    );
    expect(result.breakdown!.lines.map((l) => l.label), contains('Boss quest'));
    expect(result.xpGained, 313); // 250 × 1.25 rounded
    expect(appState.hero!.bossesSlain, 1);
    expect(
      result.unlockedAchievements.map((a) => a.id),
      contains('boss_slayer'),
    );
    // Steps survive a JSON round trip.
    final reloaded = QuestListProvider(
      storage: storage,
      scheduler: FakeReminderScheduler(),
    );
    await reloaded.loadQuestsFromStorage();
    expect(reloaded.questById(1)!.steps.length, 2);
  });

  test('titles can be worn and removed', () async {
    await setUpHero([]);
    await appState.setTitle('first_quest');
    expect(appState.hero!.title, isNull, reason: 'not unlocked');
    await appState.completeQuestForHero(0, quest: quest(1));
    await appState.setTitle('first_quest');
    expect(appState.hero!.title!.name, 'Quest Initiate');
    await appState.setTitle(null);
    expect(appState.hero!.title, isNull);
  });
}

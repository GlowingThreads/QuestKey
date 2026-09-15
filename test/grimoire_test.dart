import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/rewards.dart';
import 'package:quest_key/models/spells.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/state/spellbook.dart';

import 'helpers/fake_reminder_scheduler.dart';
import 'helpers/heroes.dart';

/// The wider grimoire: new active spells, passive disciplines and the
/// honours they unlock.
void main() {
  final now = DateTime(2030, 6, 1, 12);
  late InMemoryQuestStorage storage;
  late AppState appState;
  late QuestListProvider quests;
  late Spellbook spellbook;

  Future<void> setUpHero(List<String> skills, {double roll = 0.99}) async {
    storage = InMemoryQuestStorage();
    appState = AppState(storage: storage, now: () => now, roll: () => roll);
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

  Quest quest(
    int id, {
    int difficulty = 2,
    DateTime? due,
    QuestCategory category = QuestCategory.other,
  }) => Quest(
    id: id,
    title: 'Quest $id',
    description: 'd',
    difficulty: difficulty,
    category: category,
    dueDate: due ?? now.add(const Duration(days: 1)),
  );

  group('catalogue', () {
    test('every active skill has a spell and every passive has none', () {
      for (final skill in allSkills) {
        expect(
          Spell.forSkill(skill.id) != null,
          !skill.isPassive,
          reason: skill.id,
        );
      }
      expect(allSkills.length, greaterThanOrEqualTo(19));
      expect(allSkills.where((s) => s.isPassive).length, 3);
    });

    test('the original eight ids are unchanged', () {
      expect(allSkills.take(8).map((s) => s.id), [
        'power_strike',
        'swift_strike',
        'fireball',
        'heal',
        'stealth',
        'shield_bash',
        'mana_shield',
        'whirlwind',
      ]);
    });

    test('passives are never listed in the spellbook', () async {
      await setUpHero(['iron_will', 'meditate']);
      expect(spellbook.known.map((s) => s.skillId), ['meditate']);
      expect(appState.hero!.passives.map((s) => s.skill.id), ['iron_will']);
    });
  });

  group('resource conversion', () {
    test('Meditate trades stamina for mana', () async {
      await setUpHero(['meditate']);
      final hero = appState.hero!;
      await appState.saveHero(hero.copyWith(mana: 0));
      final spell = Spell.forSkill('meditate')!;
      final result = await spellbook.cast(spell);
      expect(result.success, isTrue);
      expect(appState.hero!.mana, (hero.maxMana * meditateFraction).round());
      expect(appState.hero!.stamina, hero.maxStamina - spellbook.costOf(spell));
      await appState.saveHero(appState.hero!.copyWith(mana: hero.maxMana));
      expect(spellbook.blockedReason(spell), 'Mana is already full.');
    });

    test('Second Wind trades mana for stamina', () async {
      await setUpHero(['second_wind']);
      final hero = appState.hero!;
      await appState.saveHero(hero.copyWith(stamina: 5));
      final result = await spellbook.cast(Spell.forSkill('second_wind')!);
      expect(result.success, isTrue);
      expect(
        appState.hero!.stamina,
        5 + (hero.maxStamina * secondWindFraction).round(),
      );
    });
  });

  group('buffs', () {
    test('Rallied pays on every quest and is not consumed', () async {
      await setUpHero(['battle_cry']);
      await spellbook.cast(Spell.forSkill('battle_cry')!);
      expect(appState.hero!.hasBuff(BuffType.rallied, now), isTrue);
      expect(
        spellbook.blockedReason(Spell.forSkill('battle_cry')!),
        'Already rallied.',
      );
      await quests.addQuest(quest(1));
      await quests.addQuest(quest(2));
      final first = await appState.completeQuestForHero(
        0,
        quest: quests.questById(1),
      );
      expect(first.xpGained, 115);
      expect(appState.hero!.hasBuff(BuffType.rallied, now), isTrue);
      final second = await appState.completeQuestForHero(
        0,
        quest: quests.questById(2),
      );
      expect(second.xpGained, 115);
      // Gone at midnight.
      expect(
        appState.hero!.hasBuff(BuffType.rallied, DateTime(2030, 6, 2, 0, 1)),
        isFalse,
      );
    });

    test('Foresight guarantees one critical and is consumed', () async {
      await setUpHero(['foresight']);
      await spellbook.cast(Spell.forSkill('foresight')!);
      await quests.addQuest(quest(1));
      await quests.addQuest(quest(2));
      final first = await appState.completeQuestForHero(
        0,
        quest: quests.questById(1),
      );
      expect(first.critical, isTrue);
      expect(first.breakdown!.foreseen, isTrue);
      expect(first.breakdown!.summary, '100 XP · FORESEEN ×2');
      expect(first.xpGained, 200);
      expect(appState.hero!.criticalHits, 1);
      expect(appState.hero!.hasBuff(BuffType.foresight, now), isFalse);
      final second = await appState.completeQuestForHero(
        0,
        quest: quests.questById(2),
      );
      expect(second.critical, isFalse);
    });

    test('Berserk costs torch HP and doubles Epic quests only', () async {
      await setUpHero(['berserk']);
      final hero = appState.hero!;
      final result = await spellbook.cast(Spell.forSkill('berserk')!);
      expect(result.success, isTrue);
      expect(
        appState.hero!.health,
        hero.maxHealth - (hero.maxHealth * berserkSelfDamage).round(),
      );
      await quests.addQuest(quest(1, difficulty: 4));
      await quests.addQuest(quest(2, difficulty: 5));
      final hard = await appState.completeQuestForHero(
        0,
        quest: quests.questById(1),
      );
      expect(hard.breakdown!.lines, isEmpty, reason: 'Hard is not Epic');
      final epic = await appState.completeQuestForHero(
        0,
        quest: quests.questById(2),
      );
      expect(epic.xpGained, 500);
      expect(appState.hero!.hasBuff(BuffType.berserk, now), isFalse);
    });

    test('Berserk is refused when the torch is nearly out', () async {
      await setUpHero(['berserk']);
      await appState.saveHero(appState.hero!.copyWith(health: 5));
      expect(
        spellbook.blockedReason(Spell.forSkill('berserk')!),
        'The torch is too low to rage.',
      );
    });

    test('Divine Favour refills the torch and raises a shield', () async {
      await setUpHero(['divine_favour']);
      await appState.saveHero(appState.hero!.copyWith(health: 1));
      final result = await spellbook.cast(Spell.forSkill('divine_favour')!);
      expect(result.success, isTrue);
      expect(appState.hero!.health, appState.hero!.maxHealth);
      expect(appState.hero!.shieldCharges, 1);
    });
  });

  group('quest spells', () {
    test('Enchant marks a quest once and pays on completion', () async {
      await setUpHero(['enchant']);
      await quests.addQuest(quest(1));
      final spell = Spell.forSkill('enchant')!;
      final result = await spellbook.cast(spell, target: quests.questById(1));
      expect(result.success, isTrue);
      expect(quests.questById(1)!.enchantPercent, enchantPercent);
      expect(
        spellbook.blockedReason(spell, target: quests.questById(1)),
        'Already enchanted.',
      );
      final done = await appState.completeQuestForHero(
        0,
        quest: quests.questById(1),
      );
      expect(done.breakdown!.summary, '100 XP · Enchanted +25%');
      expect(done.xpGained, 125);
      expect(done.unlockedAchievements.map((a) => a.id), contains('enchanter'));
    });

    test('Chronoshift moves the due date two days without snoozing', () async {
      await setUpHero(['chronoshift']);
      await quests.addQuest(quest(1));
      await spellbook.cast(
        Spell.forSkill('chronoshift')!,
        target: quests.questById(1),
      );
      final q = quests.questById(1)!;
      expect(q.dueDate, now.add(const Duration(days: 3)));
      expect(q.isSnoozedAt(now), isFalse);
    });

    test('enchantment survives a JSON round trip', () {
      final q = quest(1).copyWith(enchantPercent: 25);
      final back = Quest.fromJson(q.toJson());
      expect(back, q);
      expect(back.isEnchanted, isTrue);
      expect(Quest.fromJson(quest(2).toJson()).enchantPercent, 0);
    });
  });

  group('passives', () {
    test('Iron Will softens torch damage', () {
      final plain = makeHero(restedOn: now, lastCompletedOn: now, streak: 3);
      final iron = makeHero(
        skills: ['iron_will'],
        restedOn: now,
        lastCompletedOn: now,
        streak: 3,
      );
      final later = now.add(const Duration(days: 2));
      expect(
        plain.rest(later).torchDamage,
        (plain.maxHealth * torchDamagePerMissedDay).round(),
      );
      expect(
        iron.rest(later).torchDamage,
        (iron.maxHealth * ironWillDamagePerMissedDay).round(),
      );
    });

    test("Scholar's Focus pays on Study and Creative only", () {
      final scholar = makeHero(skills: ['scholars_focus']);
      expect(
        computeReward(
          scholar,
          quest(1, category: QuestCategory.study),
          now: now,
          roll: 0.99,
        ).total,
        110,
      );
      expect(
        computeReward(
          scholar,
          quest(1, category: QuestCategory.creative),
          now: now,
          roll: 0.99,
        ).lines.single.label,
        "Scholar's Focus",
      );
      expect(
        computeReward(
          scholar,
          quest(1, category: QuestCategory.home),
          now: now,
          roll: 0.99,
        ).lines,
        isEmpty,
      );
    });

    test('Keen Edge adds five points of critical chance', () {
      expect(criticalChance(makeHero(luck: 4)), closeTo(0.10, 1e-9));
      expect(
        criticalChance(makeHero(luck: 4, skills: ['keen_edge'])),
        closeTo(0.15, 1e-9),
      );
      expect(
        criticalChance(makeHero(luck: 99, skills: ['keen_edge'])),
        closeTo(0.40, 1e-9),
      );
    });
  });

  group('honours', () {
    test('learning the first skill unlocks Apprentice', () async {
      await setUpHero([]);
      final skill = allSkills.firstWhere((s) => s.id == 'power_strike');
      final unlocked = await appState.learnSkill(skill);
      expect(unlocked, isNotNull);
      expect(unlocked!.map((a) => a.id), contains('first_skill'));
      expect(await appState.learnSkill(skill), isNull, reason: 'known');
    });

    test('wearing a title unlocks Heraldry', () async {
      await setUpHero([]);
      await appState.completeQuestForHero(0, quest: quest(1));
      final unlocked = await appState.setTitle('first_quest');
      expect(unlocked.map((a) => a.id), contains('title_worn'));
    });

    test('full shields unlock Bulwark', () async {
      await setUpHero(['mana_shield', 'shield_bash']);
      await spellbook.cast(Spell.forSkill('mana_shield')!);
      final result = await spellbook.cast(Spell.forSkill('shield_bash')!);
      expect(result.unlocked.map((a) => a.id), contains('bulwark'));
    });

    test('losing the flame unlocks From the Ashes', () async {
      await setUpHero([]);
      final later = now.add(const Duration(days: 8));
      final state = AppState(
        storage: storage,
        now: () => later,
        roll: () => 0.99,
      );
      await state.loadHeroFromStorage();
      final report = await state.processNewDay();
      expect(report!.flameWentOut, isTrue);
      expect(state.hero!.hasAchievement('ashes'), isTrue);
      expect(state.hero!.hasAchievement('torch_bearer'), isFalse);
    });

    test('completions track punctuality and categories', () async {
      await setUpHero([]);
      await quests.addQuest(quest(1, category: QuestCategory.health));
      await quests.addQuest(
        quest(
          2,
          category: QuestCategory.work,
          due: now.subtract(const Duration(hours: 1)),
        ),
      );
      await appState.completeQuestForHero(0, quest: quests.questById(1));
      await appState.completeQuestForHero(0, quest: quests.questById(2));
      final hero = appState.hero!;
      expect(hero.onTimeCompletions, 1);
      expect(hero.categoriesCompleted, ['health', 'work']);
      // Round trip.
      final back = HeroCharacter.fromJson(hero.toJson());
      expect(back.onTimeCompletions, 1);
      expect(back.categoriesCompleted, ['health', 'work']);
      // Legacy heroes default cleanly.
      final legacy =
          hero.toJson()
            ..remove('onTimeCompletions')
            ..remove('categoriesCompleted');
      expect(HeroCharacter.fromJson(legacy).categoriesCompleted, isEmpty);
    });
  });
}

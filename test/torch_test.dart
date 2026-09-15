import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character.dart';

import 'package:quest_key/models/spells.dart';

import 'helpers/heroes.dart';

void main() {
  final day1 = DateTime(2030, 3, 1, 9);

  test('legacy hero starts its clock and refills without damage', () {
    final hero = makeHero().copyWith(mana: 0, stamina: 0, health: 40);
    final report = hero.rest(day1);
    expect(report.nothingHappened, isTrue);
    expect(report.hero.lastRestedOn, DateTime(2030, 3, 1));
    expect(report.hero.mana, hero.maxMana);
    expect(report.hero.health, 40);
  });

  test('same day: nothing happens', () {
    final hero = makeHero(
      restedOn: day1,
      lastCompletedOn: day1,
      streak: 3,
    ).copyWith(mana: 5);
    final report = hero.rest(day1.add(const Duration(hours: 6)));
    expect(report.daysPassed, 0);
    expect(report.hero.mana, 5);
  });

  test('a new day refills mana and stamina', () {
    final hero = makeHero(
      restedOn: day1,
      lastCompletedOn: day1,
      streak: 3,
    ).copyWith(mana: 0, stamina: 1);
    final report = hero.rest(day1.add(const Duration(days: 1)));
    expect(report.daysPassed, 1);
    expect(report.missedDays, 0, reason: 'yesterday had a completion');
    expect(report.hero.mana, hero.maxMana);
    expect(report.hero.stamina, hero.maxStamina);
    expect(report.hero.currentStreak, 3);
  });

  test('a missed day burns a quarter of the torch and keeps the streak', () {
    final hero = makeHero(restedOn: day1, lastCompletedOn: day1, streak: 3);
    // Two days later: the day after day1 had no completion.
    final report = hero.rest(day1.add(const Duration(days: 2)));
    expect(report.missedDays, 1);
    expect(report.torchDamage, (hero.maxHealth * 0.25).round());
    expect(report.hero.health, hero.maxHealth - report.torchDamage);
    expect(report.flameWentOut, isFalse);
    expect(report.hero.currentStreak, 3);
    // The next completion extends the streak instead of resetting it.
    final after = report.hero.recordQuestCompletion(
      day1.add(const Duration(days: 2)),
    );
    expect(after.currentStreak, 4);
  });

  test('shield charges absorb missed days', () {
    final hero = makeHero(
      restedOn: day1,
      lastCompletedOn: day1,
      streak: 3,
    ).addShieldCharges(2);
    final report = hero.rest(
      day1.add(const Duration(days: 3)),
    ); // 2 missed days
    expect(report.missedDays, 2);
    expect(report.shieldsSpent, 2);
    expect(report.torchDamage, 0);
    expect(report.hero.health, hero.maxHealth);
    expect(report.hero.shieldCharges, 0);
  });

  test('the flame goes out after enough missed days', () {
    final hero = makeHero(restedOn: day1, lastCompletedOn: day1, streak: 9);
    final report = hero.rest(
      day1.add(const Duration(days: 6)),
    ); // 5 missed days
    expect(report.flameWentOut, isTrue);
    expect(report.hero.currentStreak, 0);
    expect(report.hero.health, (hero.maxHealth * 0.25).round());
    expect(report.hero.isStreakAliveAt(day1), isFalse);
    final after = report.hero.recordQuestCompletion(
      day1.add(const Duration(days: 6)),
    );
    expect(after.currentStreak, 1);
  });

  test('no flame before the first completion', () {
    final hero = makeHero(restedOn: day1);
    final report = hero.rest(day1.add(const Duration(days: 4)));
    expect(report.missedDays, 0);
    expect(report.hero.health, hero.maxHealth);
  });

  test('completing a quest restores a tenth of every pool', () {
    final hero = makeHero().copyWith(health: 10, mana: 10, stamina: 10);
    final after = hero.recordQuestCompletion(day1);
    expect(after.health, 10 + (hero.maxHealth * regenPerQuest).round());
    expect(after.mana, 10 + (hero.maxMana * regenPerQuest).round());
    expect(after.stamina, 10 + (hero.maxStamina * regenPerQuest).round());
  });

  test('spend, canAfford and useSkill', () {
    final hero = makeHero(skills: ['heal']);
    expect(hero.canAfford(SpellResource.mana, hero.maxMana), isTrue);
    expect(hero.canAfford(SpellResource.mana, hero.maxMana + 1), isFalse);
    expect(
      () => hero.spend(SpellResource.mana, hero.maxMana + 1),
      throwsStateError,
    );
    var used = hero;
    for (var i = 0; i < 5; i++) {
      used = used.useSkill('heal');
    }
    expect(used.learnedSkill('heal')!.timesUsed, 5);
    expect(used.learnedSkill('heal')!.level, 2);
    expect(used.spellsCast, 5);
  });

  test('titles require the honour to be unlocked', () {
    final hero = makeHero();
    expect(hero.copyWith(titleAchievementId: 'first_quest').title, isNull);
  });
}

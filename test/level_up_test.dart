import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/level_up.dart';

HeroCharacter _hero(LevelUp levelUp) {
  return HeroCharacter(
    name: 'TestHero',
    motto: 'Test',
    classes: fighter,
    description: '',
    imageUrl: '',
    levelUp: levelUp,
  );
}

void main() {
  group('LevelUp.applyExperience', () {
    test('accumulates without levelling', () {
      const start = LevelUp();
      final r = start.applyExperience(30);
      expect(r.leveledUp, isFalse);
      expect(r.next, const LevelUp(exp: 30));
      expect(start.exp, 0, reason: 'immutable');
    });

    test('exactly reaching maxExp levels up with 0 XP carried', () {
      final r = const LevelUp(exp: 40).applyExperience(60);
      expect(r.leveledUp, isTrue);
      expect(
        r.next,
        const LevelUp(level: 2, exp: 0, maxExp: 200, statPoints: 3),
      );
    });

    test('multi-level jump in one gain (350 XP at level 1)', () {
      // 100 to reach L2, then 200 to reach L3, 50 left over.
      final r = const LevelUp().applyExperience(350);
      expect(r.leveledUp, isTrue);
      expect(r.next.level, 3);
      expect(r.next.exp, 50);
      expect(r.next.maxExp, 300);
      expect(r.next.statPoints, 6);
    });

    test('non-positive amounts are ignored', () {
      const start = LevelUp(exp: 10);
      expect(start.applyExperience(0).next, start);
      expect(start.applyExperience(-50).next, start);
    });

    test('progress and expToNextLevel', () {
      const l = LevelUp(exp: 25, maxExp: 100);
      expect(l.progress, 0.25);
      expect(l.expToNextLevel, 75);
    });

    test('JSON round trip', () {
      const l = LevelUp(level: 4, exp: 12, maxExp: 400, statPoints: 2);
      expect(LevelUp.fromJson(l.toJson()), l);
      expect(LevelUp.fromJson(const {}), const LevelUp());
    });
  });

  group('HeroCharacter XP and stats', () {
    test('XP accumulates across multiple gains', () {
      var hero = _hero(const LevelUp());
      hero = hero.gainExperience(20).hero;
      hero = hero.gainExperience(30).hero;
      hero = hero.gainExperience(25).hero;
      expect(hero.levelUp.exp, 75);
      expect(hero.levelUp.level, 1);
    });

    test(
      'multi-level jump in one gain updates resources for the new level',
      () {
        final r = _hero(const LevelUp()).gainExperience(350);
        expect(r.leveledUp, isTrue);
        expect(r.hero.levelUp.level, 3);
        expect(r.hero.health, 100 + 3 * 5);
        expect(r.hero.mana, 50 + 3 * 5);
        expect(r.hero.stamina, 75 + 3 * 8);
      },
    );

    test('stat-point assignment rejects overspend', () {
      final hero = _hero(const LevelUp(statPoints: 2));
      expect(() => hero.assignStatPoints('strength', 3), throwsArgumentError);
      expect(() => hero.assignStatPoints('luck', 0), throwsArgumentError);
      // Spending exactly what is available works.
      expect(hero.assignStatPoints('luck', 2).levelUp.statPoints, 0);
    });

    test('stat-point assignment rejects unknown stat', () {
      final hero = _hero(const LevelUp(statPoints: 5));
      expect(() => hero.assignStatPoints('agility', 1), throwsArgumentError);
      expect(hero.levelUp.statPoints, 5, reason: 'nothing spent');
    });

    test('every known stat can be assigned', () {
      var hero = _hero(LevelUp(statPoints: heroStatNames.length));
      for (final stat in heroStatNames) {
        hero = hero.assignStatPoints(stat, 1);
        expect(hero.statValue(stat), 1);
      }
      expect(hero.levelUp.statPoints, 0);
    });
  });
}

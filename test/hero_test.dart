import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/level_up.dart';

HeroCharacter _hero(LevelUp levelUp) {
  return HeroCharacter(
    name: 'TestHero',
    motto: 'Test',
    classes: wizard,
    description: '',
    imageUrl: '',
    levelUp: levelUp,
  );
}

void main() {
  test('Hero gains XP', () {
    final hero = _hero(const LevelUp(level: 1, exp: 10, maxExp: 100));

    final result = hero.gainExperience(20);

    expect(result.leveledUp, isFalse);
    expect(result.hero.levelUp.exp, equals(30));
    // The original is untouched.
    expect(hero.levelUp.exp, equals(10));
  });

  test('Hero levels up and carries excess XP over', () {
    final hero = _hero(const LevelUp(level: 1, exp: 90, maxExp: 100));

    final result = hero.gainExperience(20);

    expect(result.leveledUp, isTrue);
    expect(result.hero.levelUp.level, equals(2));
    expect(result.hero.levelUp.exp, equals(10));
    expect(result.hero.levelUp.maxExp, equals(200));
    expect(result.hero.levelUp.statPoints, equals(3));
    expect(result.hero.health, equals(110));
    expect(result.hero.mana, equals(60));
    expect(result.hero.stamina, equals(91));
  });

  test('Hero stats are updated correctly', () {
    final hero = _hero(
      const LevelUp(level: 1, exp: 0, maxExp: 100, statPoints: 5),
    );

    final updated = hero.assignStatPoints('strength', 3);

    expect(updated.strength, equals(3));
    expect(updated.levelUp.statPoints, equals(2));
    expect(hero.strength, equals(0));
    expect(hero.levelUp.statPoints, equals(5));
  });
}

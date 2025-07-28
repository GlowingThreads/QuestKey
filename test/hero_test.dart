import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/state/app_state.dart';

void main() {
  test('Hero gains XP', () {
    final hero = HeroCharacter(
      name: 'TestHero',
      motto: 'Simple XP',
      classes: wizard,
      description: '',
      imageUrl: '',
      levelUp: LevelUp(level: 1, exp: 10, maxExp: 100, statPoints: 0),
    );

    hero.gainExperience(20);

    expect(hero.levelUp.exp, equals(30));
  });

  test('Hero levels up', () {
    final hero = HeroCharacter(
      name: 'TestHero',
      motto: 'Level Up',
      classes: wizard,
      description: '',
      imageUrl: '',
      levelUp: LevelUp(level: 1, exp: 90, maxExp: 100, statPoints: 0),
    );

    hero.gainExperience(20);

    expect(hero.levelUp.level, equals(2));
    expect(hero.levelUp.exp, equals(10));
  });

  test('Hero stats are updated correctly', () {
    final hero = HeroCharacter(
      name: 'TestHero',
      motto: 'Stat Update',
      classes: wizard,
      description: '',
      imageUrl: '',
      levelUp: LevelUp(level: 1, exp: 0, maxExp: 100, statPoints: 5),
    );

    hero.assignStatPoints('strength', 3);

    expect(hero.strength, equals(3));
    expect(hero.levelUp.statPoints, equals(2));
  });
}

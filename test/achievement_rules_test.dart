import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/achievement_rules.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/level_up.dart';
import 'package:quest_key/models/quest.dart';

HeroCharacter _hero({
  LevelUp levelUp = const LevelUp(),
  int questsCompleted = 0,
  int currentStreak = 0,
  int strength = 0,
  int allStats = 0,
}) {
  return HeroCharacter(
    name: 'H',
    motto: '',
    classes: fighter,
    description: '',
    imageUrl: '',
    levelUp: levelUp,
    questsCompleted: questsCompleted,
    currentStreak: currentStreak,
    strength: allStats > 0 ? allStats : strength,
    dexterity: allStats,
    intelligence: allStats,
    wisdom: allStats,
    charisma: allStats,
    constitution: allStats,
    luck: allStats,
  );
}

Iterable<String> _ids(List<CharacterAchievement> list) => list.map((a) => a.id);

void main() {
  final noon = DateTime(2030, 1, 1, 12);

  test('nothing for a fresh hero', () {
    expect(evaluateAchievements(_hero(), now: noon), isEmpty);
  });

  test('first quest', () {
    final unlocked = evaluateAchievements(
      _hero(questsCompleted: 1),
      now: noon,
      completedToday: 1,
    );
    expect(_ids(unlocked), ['first_quest']);
  });

  test('already unlocked achievements are not returned again', () {
    final hero = _hero(questsCompleted: 1).unlockAchievements(
      evaluateAchievements(_hero(questsCompleted: 1), now: noon),
    );
    expect(hero.hasAchievement('first_quest'), isTrue);
    expect(evaluateAchievements(hero, now: noon), isEmpty);
  });

  test('quest master at 10 quests, level ups, stat master', () {
    final hero = _hero(
      questsCompleted: 10,
      levelUp: const LevelUp(level: 2, statPoints: 0),
    );
    expect(
      _ids(evaluateAchievements(hero, now: noon)),
      containsAll([
        'first_quest',
        'first_level',
        'quest_master',
        'stat_master',
      ]),
    );
    expect(
      _ids(evaluateAchievements(hero, now: noon)),
      isNot(contains('level_ten')),
    );
  });

  test('stat master needs every point spent', () {
    final hero = _hero(levelUp: const LevelUp(level: 2, statPoints: 1));
    expect(
      _ids(evaluateAchievements(hero, now: noon)),
      isNot(contains('stat_master')),
    );
  });

  test('level ten', () {
    final hero = _hero(levelUp: const LevelUp(level: 10, statPoints: 3));
    expect(_ids(evaluateAchievements(hero, now: noon)), contains('level_ten'));
  });

  test('speedrunner counts quests completed today', () {
    expect(
      _ids(
        evaluateAchievements(
          _hero(questsCompleted: 5),
          now: noon,
          completedToday: 5,
        ),
      ),
      contains('speedrunner'),
    );
    expect(
      _ids(
        evaluateAchievements(
          _hero(questsCompleted: 5),
          now: noon,
          completedToday: 4,
        ),
      ),
      isNot(contains('speedrunner')),
    );
  });

  test('perfectionist needs a 10 day streak', () {
    expect(
      _ids(
        evaluateAchievements(
          _hero(questsCompleted: 10, currentStreak: 10),
          now: noon,
        ),
      ),
      contains('perfectionist'),
    );
    expect(
      _ids(
        evaluateAchievements(
          _hero(questsCompleted: 10, currentStreak: 9),
          now: noon,
        ),
      ),
      isNot(contains('perfectionist')),
    );
  });

  test('balanced hero and specialist', () {
    expect(
      _ids(evaluateAchievements(_hero(allStats: 5), now: noon)),
      contains('balanced_hero'),
    );
    expect(
      _ids(evaluateAchievements(_hero(allStats: 4), now: noon)),
      isNot(contains('balanced_hero')),
    );
    expect(
      _ids(evaluateAchievements(_hero(strength: 10), now: noon)),
      contains('specialist'),
    );
    expect(
      _ids(evaluateAchievements(_hero(strength: 9), now: noon)),
      isNot(contains('specialist')),
    );
  });

  test('hidden Night Owl unlocks when a quest is completed before 4 am', () {
    final quest = Quest(id: 1, title: 't', description: 'd', dueDate: noon);
    final lateNight = DateTime(2030, 1, 1, 2, 30);
    expect(
      _ids(
        evaluateAchievements(
          _hero(questsCompleted: 1),
          now: lateNight,
          justCompleted: quest,
        ),
      ),
      contains('secret_hidden'),
    );
    expect(
      _ids(
        evaluateAchievements(
          _hero(questsCompleted: 1),
          now: noon,
          justCompleted: quest,
        ),
      ),
      isNot(contains('secret_hidden')),
    );
    // Not when nothing was completed (e.g. a stat assignment at night).
    expect(
      _ids(evaluateAchievements(_hero(questsCompleted: 1), now: lateNight)),
      isNot(contains('secret_hidden')),
    );
  });

  test('every predefined achievement has a rule', () {
    // A hero that satisfies everything at once.
    final hero = _hero(
      questsCompleted: 10,
      currentStreak: 10,
      allStats: 10,
      levelUp: const LevelUp(level: 10, statPoints: 0),
    );
    final quest = Quest(id: 1, title: 't', description: 'd', dueDate: noon);
    final unlocked = evaluateAchievements(
      hero,
      now: DateTime(2030, 1, 1, 1),
      completedToday: 5,
      justCompleted: quest,
    );
    expect(_ids(unlocked).toSet(), allAchievements.map((a) => a.id).toSet());
  });
}

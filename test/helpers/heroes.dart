import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/classes.dart';
import 'package:quest_key/models/level_up.dart';

/// A hero with full pools, optional learned skills and a started rest clock.
HeroCharacter makeHero({
  Classes? classes,
  LevelUp levelUp = const LevelUp(level: 3, exp: 0, maxExp: 300),
  List<String> skills = const [],
  DateTime? restedOn,
  DateTime? lastCompletedOn,
  int streak = 0,
  int luck = 0,
  int strength = 7,
  int intelligence = 2,
}) {
  var hero = HeroCharacter(
    name: 'Tester',
    motto: 'Testing',
    classes: classes ?? fighter,
    description: '',
    imageUrl: '',
    levelUp: levelUp,
    strength: strength,
    dexterity: 4,
    intelligence: intelligence,
    wisdom: 2,
    charisma: 4,
    constitution: 4,
    luck: luck,
    health: maxHealthFor(levelUp.level),
    mana: maxManaFor(levelUp.level),
    stamina: maxStaminaFor(levelUp.level),
    lastRestedOn: restedOn,
    lastQuestCompletedOn: lastCompletedOn,
    currentStreak: streak,
    longestStreak: streak,
  );
  for (final id in skills) {
    final skill = allSkills.firstWhere((s) => s.id == id);
    hero = hero.copyWith(
      learnedSkills: [...hero.learnedSkills, LearnedSkill(skill: skill)],
    );
  }
  return hero;
}

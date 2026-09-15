import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/spells.dart';

/// Number of quests completed in one day for the Speedrunner achievement.
const int speedrunnerQuestsPerDay = 5;

/// Streak length for the Perfectionist achievement.
const int perfectionistStreak = 10;

/// Quests completed in one weekend day for Weekend Warrior.
const int weekendWarriorQuests = 3;

/// Returns the achievements in [allAchievements] that [hero] has now earned
/// but not yet unlocked.
///
/// Pure: call it after the hero has been updated (XP applied, quest
/// recorded, stat assigned) and pass the result to
/// [HeroCharacter.unlockAchievements].
///
/// * [now] is the wall-clock time of the triggering event.
/// * [completedToday] is the number of quests completed on the day of [now]
///   including the one just completed (0 when not completing a quest).
/// * [justCompleted] is the quest that was just completed, if any.
/// * [survivedMissedDay] is true when the daily rest burned the torch but
///   the flame stayed lit.
/// * [flameWentOut] is true when the daily rest extinguished the flame.
List<CharacterAchievement> evaluateAchievements(
  HeroCharacter hero, {
  required DateTime now,
  int completedToday = 0,
  Quest? justCompleted,
  bool survivedMissedDay = false,
  bool flameWentOut = false,
}) {
  final level = hero.levelUp.level;
  final stats = heroStatNames.map(hero.statValue).toList();
  final weekend =
      now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  final categories =
      QuestCategory.values
          .where((c) => c != QuestCategory.other)
          .map((c) => c.name)
          .toSet();

  bool earned(String id) {
    switch (id) {
      // The Road
      case 'first_quest':
        return hero.questsCompleted >= 1;
      case 'first_level':
        return level >= 2;
      case 'streak_3':
        return hero.currentStreak >= 3;
      case 'level_five':
        return level >= 5;
      case 'quest_master':
        return hero.questsCompleted >= 10;
      case 'level_ten':
        return level >= 10;
      case 'quest_50':
        return hero.questsCompleted >= 50;
      case 'quest_100':
        return hero.questsCompleted >= 100;
      case 'level_twenty':
        return level >= 20;
      case 'title_worn':
        return hero.title != null;

      // Trials
      case 'speedrunner':
        return completedToday >= speedrunnerQuestsPerDay;
      case 'perfectionist':
        return hero.currentStreak >= perfectionistStreak;
      case 'streak_30':
        return hero.currentStreak >= 30;
      case 'epic_first':
        return justCompleted != null &&
            justCompleted.difficulty >= maxDifficulty;
      case 'punctual':
        return hero.onTimeCompletions >= 10;
      case 'lucky_strike':
        return hero.criticalHits >= 1;
      case 'crit_10':
        return hero.criticalHits >= 10;
      case 'boss_slayer':
        return hero.bossesSlain >= 1;
      case 'boss_5':
        return hero.bossesSlain >= 5;
      case 'torch_bearer':
        return survivedMissedDay;
      case 'bulwark':
        return hero.shieldCharges >= Spell.maxShieldCharges;
      case 'secret_hidden':
        return justCompleted != null && now.hour < 4;
      case 'early_bird':
        return justCompleted != null && now.hour >= 5 && now.hour < 7;
      case 'weekend_warrior':
        return weekend && completedToday >= weekendWarriorQuests;
      case 'ashes':
        return flameWentOut;

      // Mastery
      case 'stat_master':
        // Has received points from levelling and spent every one of them.
        return level >= 2 && hero.levelUp.statPoints == 0;
      case 'balanced_hero':
        return stats.every((value) => value >= 5);
      case 'specialist':
        return stats.any((value) => value >= 10);
      case 'paragon':
        return stats.every((value) => value >= 10);
      case 'first_skill':
        return hero.learnedSkills.isNotEmpty;
      case 'spell_caster':
        return hero.spellsCast >= 1;
      case 'spell_master':
        return hero.spellsCast >= 25;
      case 'spell_100':
        return hero.spellsCast >= 100;
      case 'enchanter':
        return justCompleted != null && justCompleted.isEnchanted;
      case 'loremaster':
        return allSkills.every((s) => hero.hasSkill(s.id));

      // Wayfaring
      case 'encounter_victor':
        return hero.encountersResolved >= 1;
      case 'wayfarer':
        return hero.encountersResolved >= 10;
      case 'well_rounded':
        return categories.every(hero.categoriesCompleted.contains);
      default:
        return false;
    }
  }

  return [
    for (final achievement in allAchievements)
      if (!hero.hasAchievement(achievement.id) && earned(achievement.id))
        achievement,
  ];
}

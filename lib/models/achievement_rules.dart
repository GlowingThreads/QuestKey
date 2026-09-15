import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/quest.dart';

/// Number of quests completed in one day for the Speedrunner achievement.
const int speedrunnerQuestsPerDay = 5;

/// Streak length for the Perfectionist achievement.
const int perfectionistStreak = 10;

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
List<CharacterAchievement> evaluateAchievements(
  HeroCharacter hero, {
  required DateTime now,
  int completedToday = 0,
  Quest? justCompleted,
  bool survivedMissedDay = false,
}) {
  final level = hero.levelUp.level;
  final stats = heroStatNames.map(hero.statValue).toList();

  bool earned(String id) {
    switch (id) {
      case 'first_quest':
        return hero.questsCompleted >= 1;
      case 'first_level':
        return level >= 2;
      case 'quest_master':
        return hero.questsCompleted >= 10;
      case 'level_ten':
        return level >= 10;
      case 'stat_master':
        // Has received points from levelling and spent every one of them.
        return level >= 2 && hero.levelUp.statPoints == 0;
      case 'speedrunner':
        return completedToday >= speedrunnerQuestsPerDay;
      case 'perfectionist':
        return hero.currentStreak >= perfectionistStreak;
      case 'balanced_hero':
        return stats.every((value) => value >= 5);
      case 'specialist':
        return stats.any((value) => value >= 10);
      case 'secret_hidden':
        return justCompleted != null && now.hour < 4;
      case 'spell_caster':
        return hero.spellsCast >= 1;
      case 'spell_master':
        return hero.spellsCast >= 25;
      case 'lucky_strike':
        return hero.criticalHits >= 1;
      case 'encounter_victor':
        return hero.encountersResolved >= 1;
      case 'boss_slayer':
        return hero.bossesSlain >= 1;
      case 'torch_bearer':
        return survivedMissedDay;
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

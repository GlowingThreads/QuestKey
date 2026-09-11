// character model
import 'package:quest_key/models/classes.dart';
import 'package:quest_key/models/character_background.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/level_up.dart';

/// Names of the seven allocatable stats, in display order.
const List<String> heroStatNames = [
  'strength',
  'dexterity',
  'intelligence',
  'wisdom',
  'charisma',
  'constitution',
  'luck',
];

/// The player's hero.
///
/// Immutable: every "mutating" operation ([gainExperience],
/// [assignStatPoints], [learnSkill], [unlockAchievement]) returns a new
/// instance and leaves the receiver untouched.
class HeroCharacter {
  final String name;
  final String motto;
  final Classes classes;
  final String description;
  final String imageUrl;
  final LevelUp levelUp;

  final CharacterBackground? background;
  final String biography; // Character's personal story/notes
  final List<LearnedSkill> learnedSkills;
  final List<UnlockedAchievement> unlockedAchievements;
  final DateTime createdDate;
  final int questsCompleted;

  /// Consecutive calendar days (ending on [lastQuestCompletedOn]) with at
  /// least one completed quest.
  final int currentStreak;
  final int longestStreak;

  /// Calendar day (time stripped) of the most recent quest completion.
  final DateTime? lastQuestCompletedOn;

  final int strength;
  final int dexterity;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final int constitution;
  final int luck;

  final int health;
  final int mana;
  final int stamina;

  HeroCharacter({
    required this.name,
    required this.motto,
    required this.classes,
    required this.description,
    required this.imageUrl,
    required this.levelUp,
    this.strength = 0,
    this.dexterity = 0,
    this.intelligence = 0,
    this.wisdom = 0,
    this.charisma = 0,
    this.constitution = 0,
    this.luck = 0,
    this.health = 0,
    this.mana = 0,
    this.stamina = 0,
    this.background,
    this.biography = '',
    List<LearnedSkill>? learnedSkills,
    List<UnlockedAchievement>? unlockedAchievements,
    DateTime? createdDate,
    this.questsCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastQuestCompletedOn,
  }) : learnedSkills = List.unmodifiable(learnedSkills ?? const []),
       unlockedAchievements = List.unmodifiable(
         unlockedAchievements ?? const [],
       ),
       createdDate = createdDate ?? DateTime.now();

  factory HeroCharacter.fromClasses(Classes classes) {
    return HeroCharacter(
      name: classes.className,
      motto: 'A brave hero',
      classes: classes,
      strength: classes.strength,
      dexterity: classes.dexterity,
      imageUrl: classes.classImageUrl,
      levelUp: const LevelUp(level: 1, exp: 0, maxExp: 100, statPoints: 0),
      description: 'A brave hero',
      intelligence: classes.intelligence,
      wisdom: classes.wisdom,
      charisma: classes.charisma,
      constitution: classes.constitution,
      luck: classes.luck,
      health: 100,
      mana: 50,
      stamina: 50,
    );
  }

  // Serialization with all character data
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'motto': motto,
      'classes': classes.toJson(),
      'description': description,
      'imageUrl': imageUrl,
      'levelUp': levelUp.toJson(),
      'strength': strength,
      'dexterity': dexterity,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'constitution': constitution,
      'luck': luck,
      'health': health,
      'mana': mana,
      'stamina': stamina,
      'background': background?.toJson(),
      'biography': biography,
      'learnedSkills': learnedSkills.map((s) => s.toJson()).toList(),
      'unlockedAchievements':
          unlockedAchievements.map((a) => a.toJson()).toList(),
      'createdDate': createdDate.toIso8601String(),
      'questsCompleted': questsCompleted,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastQuestCompletedOn': lastQuestCompletedOn?.toIso8601String(),
    };
  }

  factory HeroCharacter.fromJson(Map<String, dynamic> json) {
    CharacterBackground? background;
    if (json['background'] != null) {
      background = CharacterBackground.fromJson(
        Map<String, dynamic>.from(json['background'] as Map),
      );
    }

    final learnedSkills = <LearnedSkill>[];
    if (json['learnedSkills'] != null) {
      for (final entry in json['learnedSkills'] as List) {
        learnedSkills.add(
          LearnedSkill.fromJson(Map<String, dynamic>.from(entry as Map)),
        );
      }
    }

    final unlockedAchievements = <UnlockedAchievement>[];
    if (json['unlockedAchievements'] != null) {
      for (final entry in json['unlockedAchievements'] as List) {
        unlockedAchievements.add(
          UnlockedAchievement.fromJson(
            Map<String, dynamic>.from(entry as Map),
            allAchievements,
          ),
        );
      }
    }

    final levelUpJson = json['levelUp'];

    return HeroCharacter(
      name: json['name'] as String? ?? 'Hero',
      motto: json['motto'] as String? ?? '',
      classes: Classes.fromJson(
        Map<String, dynamic>.from(json['classes'] as Map),
      ),
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      levelUp:
          levelUpJson is Map
              ? LevelUp.fromJson(Map<String, dynamic>.from(levelUpJson))
              : const LevelUp(),
      strength: _int(json['strength']),
      dexterity: _int(json['dexterity']),
      intelligence: _int(json['intelligence']),
      wisdom: _int(json['wisdom']),
      charisma: _int(json['charisma']),
      constitution: _int(json['constitution']),
      luck: _int(json['luck']),
      health: _int(json['health']),
      mana: _int(json['mana']),
      stamina: _int(json['stamina']),
      background: background,
      biography: json['biography'] as String? ?? '',
      learnedSkills: learnedSkills,
      unlockedAchievements: unlockedAchievements,
      createdDate:
          json['createdDate'] != null
              ? DateTime.tryParse(json['createdDate'] as String) ??
                  DateTime.now()
              : DateTime.now(),
      questsCompleted: _int(json['questsCompleted']),
      currentStreak: _int(json['currentStreak']),
      longestStreak: _int(json['longestStreak']),
      lastQuestCompletedOn:
          json['lastQuestCompletedOn'] is String
              ? DateTime.tryParse(json['lastQuestCompletedOn'] as String)
              : null,
    );
  }

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  /// Adds [amount] XP. Returns the updated hero and whether it levelled up.
  ///
  /// On level up the hero's resource pools grow with its new level.
  ({HeroCharacter hero, bool leveledUp}) gainExperience(int amount) {
    final result = levelUp.applyExperience(amount);
    if (!result.leveledUp) {
      return (hero: copyWith(levelUp: result.next), leveledUp: false);
    }

    final newLevel = result.next.level;
    return (
      hero: copyWith(
        levelUp: result.next,
        health: 100 + (newLevel * 5),
        mana: 50 + (newLevel * 5),
        stamina: 75 + (newLevel * 8),
      ),
      leveledUp: true,
    );
  }

  /// Records a quest completed at [now]: bumps [questsCompleted] and updates
  /// the daily streak (same day keeps it, the next day extends it, a gap
  /// resets it to 1).
  HeroCharacter recordQuestCompletion(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final last = lastQuestCompletedOn;

    int streak;
    if (last == null) {
      streak = 1;
    } else {
      final lastDay = DateTime(last.year, last.month, last.day);
      final gap = today.difference(lastDay).inDays;
      if (gap == 0) {
        streak = currentStreak < 1 ? 1 : currentStreak;
      } else if (gap == 1) {
        streak = currentStreak + 1;
      } else {
        streak = 1;
      }
    }

    return copyWith(
      questsCompleted: questsCompleted + 1,
      currentStreak: streak,
      longestStreak: streak > longestStreak ? streak : longestStreak,
      lastQuestCompletedOn: today,
    );
  }

  /// Whether the streak is still alive as of [now] (a completion today or
  /// yesterday).
  bool isStreakAliveAt(DateTime now) {
    final last = lastQuestCompletedOn;
    if (last == null || currentStreak == 0) return false;
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    return today.difference(lastDay).inDays <= 1;
  }

  /// Spends [points] unassigned stat points on [stat].
  ///
  /// Throws [ArgumentError] if the hero does not have enough points or if
  /// [stat] is not one of [heroStatNames].
  HeroCharacter assignStatPoints(String stat, int points) {
    if (points <= 0) {
      throw ArgumentError.value(points, 'points', 'must be positive');
    }
    if (points > levelUp.statPoints) {
      throw ArgumentError('Not enough stat points available');
    }
    if (!heroStatNames.contains(stat)) {
      throw ArgumentError.value(stat, 'stat', 'Invalid stat name');
    }

    final remaining = levelUp.copyWith(statPoints: levelUp.statPoints - points);

    switch (stat) {
      case 'strength':
        return copyWith(strength: strength + points, levelUp: remaining);
      case 'dexterity':
        return copyWith(dexterity: dexterity + points, levelUp: remaining);
      case 'intelligence':
        return copyWith(
          intelligence: intelligence + points,
          levelUp: remaining,
        );
      case 'wisdom':
        return copyWith(wisdom: wisdom + points, levelUp: remaining);
      case 'charisma':
        return copyWith(charisma: charisma + points, levelUp: remaining);
      case 'constitution':
        return copyWith(
          constitution: constitution + points,
          levelUp: remaining,
        );
      case 'luck':
        return copyWith(luck: luck + points, levelUp: remaining);
      default:
        throw ArgumentError.value(stat, 'stat', 'Invalid stat name');
    }
  }

  HeroCharacter copyWith({
    String? name,
    String? motto,
    Classes? classes,
    String? description,
    String? imageUrl,
    LevelUp? levelUp,
    int? strength,
    int? dexterity,
    int? intelligence,
    int? wisdom,
    int? charisma,
    int? constitution,
    int? luck,
    int? health,
    int? mana,
    int? stamina,
    CharacterBackground? background,
    String? biography,
    List<LearnedSkill>? learnedSkills,
    List<UnlockedAchievement>? unlockedAchievements,
    DateTime? createdDate,
    int? questsCompleted,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastQuestCompletedOn,
  }) {
    return HeroCharacter(
      name: name ?? this.name,
      motto: motto ?? this.motto,
      classes: classes ?? this.classes,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      levelUp: levelUp ?? this.levelUp,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      intelligence: intelligence ?? this.intelligence,
      wisdom: wisdom ?? this.wisdom,
      charisma: charisma ?? this.charisma,
      constitution: constitution ?? this.constitution,
      luck: luck ?? this.luck,
      health: health ?? this.health,
      mana: mana ?? this.mana,
      stamina: stamina ?? this.stamina,
      background: background ?? this.background,
      biography: biography ?? this.biography,
      learnedSkills: learnedSkills ?? this.learnedSkills,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      createdDate: createdDate ?? this.createdDate,
      questsCompleted: questsCompleted ?? this.questsCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastQuestCompletedOn: lastQuestCompletedOn ?? this.lastQuestCompletedOn,
    );
  }

  /// Whether the hero meets the level and stat requirements of [skill].
  bool canLearnSkill(CharacterSkill skill) {
    if (hasSkill(skill.id)) return false;
    if (levelUp.level < skill.levelRequired) return false;

    for (final req in skill.requirements) {
      final parts = req.split(':');
      if (parts.length == 2) {
        final requiredValue = int.tryParse(parts[1]) ?? 0;
        if (statValue(parts[0]) < requiredValue) return false;
      }
    }
    return true;
  }

  /// Returns a hero that has learned [skill], or `null` if the requirements
  /// are not met or the skill is already known.
  HeroCharacter? learnSkill(CharacterSkill skill) {
    if (!canLearnSkill(skill)) return null;
    return copyWith(
      learnedSkills: [...learnedSkills, LearnedSkill(skill: skill)],
    );
  }

  /// Get a stat value by name (0 for unknown names).
  int statValue(String statName) {
    switch (statName) {
      case 'strength':
        return strength;
      case 'dexterity':
        return dexterity;
      case 'intelligence':
        return intelligence;
      case 'wisdom':
        return wisdom;
      case 'charisma':
        return charisma;
      case 'constitution':
        return constitution;
      case 'luck':
        return luck;
      default:
        return 0;
    }
  }

  /// Returns a hero with every achievement in [achievements] unlocked
  /// (already-unlocked ones are skipped).
  HeroCharacter unlockAchievements(
    Iterable<CharacterAchievement> achievements,
  ) {
    var hero = this;
    for (final achievement in achievements) {
      hero = hero.unlockAchievement(achievement) ?? hero;
    }
    return hero;
  }

  /// Returns a hero with [achievement] unlocked, or `null` if it was already
  /// unlocked.
  HeroCharacter? unlockAchievement(CharacterAchievement achievement) {
    if (hasAchievement(achievement.id)) return null;
    return copyWith(
      unlockedAchievements: [
        ...unlockedAchievements,
        UnlockedAchievement(achievement: achievement),
      ],
    );
  }

  /// Check if character has learned a skill
  bool hasSkill(String skillId) {
    return learnedSkills.any((s) => s.skill.id == skillId);
  }

  /// Check if character has achievement
  bool hasAchievement(String achievementId) {
    return unlockedAchievements.any((a) => a.achievement.id == achievementId);
  }
}

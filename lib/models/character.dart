// character model
import 'dart:math' as math;

import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/character_background.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/models/classes.dart';
import 'package:quest_key/models/familiar.dart';
import 'package:quest_key/models/level_up.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/spells.dart';

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

/// Resource pool sizes grow with level.
int maxHealthFor(int level) => 100 + level * 5;
int maxManaFor(int level) => 50 + level * 5;
int maxStaminaFor(int level) => 75 + level * 8;

/// Torch damage taken for each day with no completed quest (fraction of
/// max HP).
const double torchDamagePerMissedDay = 0.25;

/// Resources restored on every quest completion (fraction of max).
const double regenPerQuest = 0.10;

/// What happened when a new day was processed.
class RestReport {
  const RestReport({
    required this.hero,
    required this.daysPassed,
    required this.missedDays,
    required this.shieldsSpent,
    required this.torchDamage,
    required this.flameWentOut,
  });

  final HeroCharacter hero;
  final int daysPassed;
  final int missedDays;
  final int shieldsSpent;
  final int torchDamage;

  /// HP reached zero: the streak was lost.
  final bool flameWentOut;

  bool get nothingHappened => daysPassed == 0;
}

/// The player's hero.
///
/// Immutable: every "mutating" operation returns a new instance and leaves
/// the receiver untouched.
class HeroCharacter {
  final String name;
  final String motto;
  final Classes classes;
  final String description;
  final String imageUrl;
  final LevelUp levelUp;

  final CharacterBackground? background;
  final String biography;
  final List<LearnedSkill> learnedSkills;
  final List<UnlockedAchievement> unlockedAchievements;
  final DateTime createdDate;
  final int questsCompleted;

  /// Consecutive days with at least one completed quest (torch permitting).
  final int currentStreak;
  final int longestStreak;

  /// Calendar day (time stripped) of the most recent quest completion.
  final DateTime? lastQuestCompletedOn;

  /// Calendar day the daily rest was last processed (resources refilled,
  /// torch damage applied). `null` for heroes saved before this existed.
  final DateTime? lastRestedOn;

  final int strength;
  final int dexterity;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final int constitution;
  final int luck;

  /// Current pools. Maximums come from [maxHealthFor] etc.
  final int health;
  final int mana;
  final int stamina;

  /// Shield charges absorb missed-day torch damage, one day per charge.
  final int shieldCharges;
  final List<ActiveBuff> buffs;

  /// Honour worn as a title, e.g. "the Night Owl" (achievement id).
  final String? titleAchievementId;

  final int spellsCast;
  final int criticalHits;
  final int encountersResolved;
  final int bossesSlain;

  /// Quests completed before their due date.
  final int onTimeCompletions;

  /// Names of every [QuestCategory] the hero has completed a quest in.
  final List<String> categoriesCompleted;

  /// The companion adopted at the hearth, if any.
  final Familiar? familiar;

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
    this.lastRestedOn,
    this.shieldCharges = 0,
    List<ActiveBuff>? buffs,
    this.titleAchievementId,
    this.spellsCast = 0,
    this.criticalHits = 0,
    this.encountersResolved = 0,
    this.bossesSlain = 0,
    this.onTimeCompletions = 0,
    List<String>? categoriesCompleted,
    this.familiar,
  }) : learnedSkills = List.unmodifiable(learnedSkills ?? const []),
       categoriesCompleted = List.unmodifiable(categoriesCompleted ?? const []),
       unlockedAchievements = List.unmodifiable(
         unlockedAchievements ?? const [],
       ),
       buffs = List.unmodifiable(buffs ?? const []),
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
      health: maxHealthFor(1),
      mana: maxManaFor(1),
      stamina: maxStaminaFor(1),
    );
  }

  int get maxHealth => maxHealthFor(levelUp.level);
  int get maxMana => maxManaFor(levelUp.level);
  int get maxStamina => maxStaminaFor(levelUp.level);

  /// The honour worn as a title, if any.
  CharacterAchievement? get title {
    final id = titleAchievementId;
    if (id == null || !hasAchievement(id)) return null;
    for (final a in allAchievements) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ---------------------------------------------------------------- JSON

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
      'lastRestedOn': lastRestedOn?.toIso8601String(),
      'shieldCharges': shieldCharges,
      'buffs': buffs.map((b) => b.toJson()).toList(),
      'titleAchievementId': titleAchievementId,
      'spellsCast': spellsCast,
      'criticalHits': criticalHits,
      'encountersResolved': encountersResolved,
      'bossesSlain': bossesSlain,
      'onTimeCompletions': onTimeCompletions,
      'categoriesCompleted': categoriesCompleted,
      'familiar': familiar?.toJson(),
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
    for (final entry in (json['learnedSkills'] as List?) ?? const []) {
      learnedSkills.add(
        LearnedSkill.fromJson(Map<String, dynamic>.from(entry as Map)),
      );
    }

    final unlockedAchievements = <UnlockedAchievement>[];
    for (final entry in (json['unlockedAchievements'] as List?) ?? const []) {
      unlockedAchievements.add(
        UnlockedAchievement.fromJson(
          Map<String, dynamic>.from(entry as Map),
          allAchievements,
        ),
      );
    }

    final buffs = <ActiveBuff>[];
    for (final entry in (json['buffs'] as List?) ?? const []) {
      final buff = ActiveBuff.fromJson(Map<String, dynamic>.from(entry as Map));
      if (buff != null) buffs.add(buff);
    }

    final levelUpJson = json['levelUp'];
    final levelUp =
        levelUpJson is Map
            ? LevelUp.fromJson(Map<String, dynamic>.from(levelUpJson))
            : const LevelUp();

    return HeroCharacter(
      name: json['name'] as String? ?? 'Hero',
      motto: json['motto'] as String? ?? '',
      classes: Classes.fromJson(
        Map<String, dynamic>.from(json['classes'] as Map),
      ),
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      levelUp: levelUp,
      strength: _int(json['strength']),
      dexterity: _int(json['dexterity']),
      intelligence: _int(json['intelligence']),
      wisdom: _int(json['wisdom']),
      charisma: _int(json['charisma']),
      constitution: _int(json['constitution']),
      luck: _int(json['luck']),
      health: _int(json['health']).clamp(0, maxHealthFor(levelUp.level)),
      mana: _int(json['mana']).clamp(0, maxManaFor(levelUp.level)),
      stamina: _int(json['stamina']).clamp(0, maxStaminaFor(levelUp.level)),
      background: background,
      biography: json['biography'] as String? ?? '',
      learnedSkills: learnedSkills,
      unlockedAchievements: unlockedAchievements,
      createdDate: _date(json['createdDate']) ?? DateTime.now(),
      questsCompleted: _int(json['questsCompleted']),
      currentStreak: _int(json['currentStreak']),
      longestStreak: _int(json['longestStreak']),
      lastQuestCompletedOn: _date(json['lastQuestCompletedOn']),
      lastRestedOn: _date(json['lastRestedOn']),
      shieldCharges: _int(json['shieldCharges']),
      buffs: buffs,
      titleAchievementId: json['titleAchievementId'] as String?,
      spellsCast: _int(json['spellsCast']),
      criticalHits: _int(json['criticalHits']),
      encountersResolved: _int(json['encountersResolved']),
      bossesSlain: _int(json['bossesSlain']),
      onTimeCompletions: _int(json['onTimeCompletions']),
      categoriesCompleted: [
        for (final c in (json['categoriesCompleted'] as List?) ?? const [])
          if (c is String) c,
      ],
      familiar:
          json['familiar'] is Map
              ? Familiar.fromJson(
                Map<String, dynamic>.from(json['familiar'] as Map),
              )
              : null,
    );
  }

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  // ---------------------------------------------------------------- XP

  /// Adds [amount] XP. Returns the updated hero and whether it levelled up.
  /// On level up the pools grow and are refilled.
  ({HeroCharacter hero, bool leveledUp}) gainExperience(int amount) {
    final result = levelUp.applyExperience(amount);
    if (!result.leveledUp) {
      return (hero: copyWith(levelUp: result.next), leveledUp: false);
    }

    final newLevel = result.next.level;
    return (
      hero: copyWith(
        levelUp: result.next,
        health: maxHealthFor(newLevel),
        mana: maxManaFor(newLevel),
        stamina: maxStaminaFor(newLevel),
      ),
      leveledUp: true,
    );
  }

  /// Returns a hero with [bonuses] (stat name → points) added to its stats.
  HeroCharacter addStats(Map<String, int> bonuses) {
    var hero = this;
    for (final entry in bonuses.entries) {
      final v = entry.value;
      hero = switch (entry.key) {
        'strength' => hero.copyWith(strength: hero.strength + v),
        'dexterity' => hero.copyWith(dexterity: hero.dexterity + v),
        'intelligence' => hero.copyWith(intelligence: hero.intelligence + v),
        'wisdom' => hero.copyWith(wisdom: hero.wisdom + v),
        'charisma' => hero.copyWith(charisma: hero.charisma + v),
        'constitution' => hero.copyWith(constitution: hero.constitution + v),
        'luck' => hero.copyWith(luck: hero.luck + v),
        _ => hero,
      };
    }
    return hero;
  }

  /// Returns a hero with [background] set and its stat bonuses applied.
  HeroCharacter withBackground(CharacterBackground background) =>
      addStats(background.statBonus).copyWith(background: background);

  // ---------------------------------------------------------------- streak & torch

  /// Records a quest completed at [now]: bumps [questsCompleted], updates the
  /// daily streak, restores a little of every pool and, when [quest] is
  /// given, tracks punctuality and the categories seen.
  ///
  /// A gap of more than one day normally resets the streak, unless the torch
  /// survived the missed days (see [rest]), in which case it keeps burning.
  HeroCharacter recordQuestCompletion(DateTime now, {Quest? quest}) {
    final today = _dayOf(now);
    final onTime = quest != null && !now.isAfter(quest.dueDate);
    final categories =
        quest == null || categoriesCompleted.contains(quest.category.name)
            ? categoriesCompleted
            : [...categoriesCompleted, quest.category.name];
    final last = lastQuestCompletedOn;

    int streak;
    if (last == null) {
      streak = 1;
    } else {
      final gap = today.difference(_dayOf(last)).inDays;
      if (gap == 0) {
        streak = currentStreak < 1 ? 1 : currentStreak;
      } else if (gap == 1 || currentStreak > 0) {
        streak = currentStreak + 1;
      } else {
        streak = 1;
      }
    }

    return restore(
      health: (maxHealth * regenPerQuest).round(),
      mana: (maxMana * regenPerQuest).round(),
      stamina: (maxStamina * regenPerQuest).round(),
    ).copyWith(
      questsCompleted: questsCompleted + 1,
      currentStreak: streak,
      longestStreak: streak > longestStreak ? streak : longestStreak,
      lastQuestCompletedOn: today,
      onTimeCompletions: onTime ? onTimeCompletions + 1 : onTimeCompletions,
      categoriesCompleted: categories,
      familiar: familiar?.copyWith(bond: familiar!.bond + 1),
    );
  }

  /// Whether the streak is currently burning.
  bool isStreakAliveAt(DateTime now) => currentStreak > 0 && health > 0;

  /// Fraction of max HP one unshielded missed day costs: 25%, or 15% with
  /// the Iron Will passive.
  double get torchDamageFraction =>
      hasSkill('iron_will')
          ? ironWillDamagePerMissedDay
          : torchDamagePerMissedDay;

  /// Processes the days that passed since [lastRestedOn]:
  ///
  /// * mana and stamina refill completely at the start of each new day;
  /// * every day in the gap with no completed quest burns the torch for
  ///   [torchDamagePerMissedDay] of max HP, unless a shield charge absorbs it;
  /// * if HP reaches zero the flame goes out: the streak resets and the
  ///   torch relights at a quarter of max HP;
  /// * expired buffs are dropped.
  ///
  /// Heroes saved before this mechanic simply start their clock today.
  RestReport rest(DateTime now) {
    final today = _dayOf(now);
    final lastRest = lastRestedOn;
    var hero = _dropExpiredBuffs(now);

    if (lastRest == null) {
      hero = hero.copyWith(
        lastRestedOn: today,
        mana: maxMana,
        stamina: maxStamina,
        health: health <= 0 ? maxHealth : health,
      );
      return RestReport(
        hero: hero,
        daysPassed: 0,
        missedDays: 0,
        shieldsSpent: 0,
        torchDamage: 0,
        flameWentOut: false,
      );
    }

    final daysPassed = today.difference(_dayOf(lastRest)).inDays;
    if (daysPassed <= 0) {
      return RestReport(
        hero: hero,
        daysPassed: 0,
        missedDays: 0,
        shieldsSpent: 0,
        torchDamage: 0,
        flameWentOut: false,
      );
    }

    // Days in [lastRest, yesterday] that came after the last completion and
    // therefore had no quest done. Before the first ever completion there is
    // no flame to protect.
    var missed = 0;
    final lastDone = lastQuestCompletedOn;
    if (lastDone != null && currentStreak > 0) {
      final lastDoneDay = _dayOf(lastDone);
      for (var i = 0; i < daysPassed; i++) {
        final day = _dayOf(lastRest).add(Duration(days: i));
        if (day.isAfter(lastDoneDay)) missed++;
      }
    }

    final shieldsSpent = math.min(missed, shieldCharges);
    final unshielded = missed - shieldsSpent;
    var damage = (maxHealth * torchDamageFraction * unshielded).round();
    var newHealth = health - damage;
    var streak = currentStreak;
    var flameOut = false;
    if (unshielded > 0 && newHealth <= 0) {
      flameOut = true;
      streak = 0;
      damage = health;
      newHealth = (maxHealth * 0.25).round();
    }

    hero = hero.copyWith(
      lastRestedOn: today,
      mana: maxMana,
      stamina: maxStamina,
      health: newHealth.clamp(0, maxHealth),
      shieldCharges: shieldCharges - shieldsSpent,
      currentStreak: streak,
    );

    return RestReport(
      hero: hero,
      daysPassed: daysPassed,
      missedDays: missed,
      shieldsSpent: shieldsSpent,
      torchDamage: damage,
      flameWentOut: flameOut,
    );
  }

  HeroCharacter _dropExpiredBuffs(DateTime now) {
    final live = buffs.where((b) => b.isActiveAt(now)).toList();
    return live.length == buffs.length ? this : copyWith(buffs: live);
  }

  // ---------------------------------------------------------------- resources & spells

  int poolOf(SpellResource resource) => switch (resource) {
    SpellResource.mana => mana,
    SpellResource.stamina => stamina,
    SpellResource.none => 0,
  };

  int maxPoolOf(SpellResource resource) => switch (resource) {
    SpellResource.mana => maxMana,
    SpellResource.stamina => maxStamina,
    SpellResource.none => 0,
  };

  bool canAfford(SpellResource resource, int cost) =>
      resource == SpellResource.none || poolOf(resource) >= cost;

  /// Spends [cost] from [resource]. Throws [StateError] if unaffordable.
  HeroCharacter spend(SpellResource resource, int cost) {
    if (!canAfford(resource, cost)) {
      throw StateError('Not enough ${resource.label}');
    }
    return switch (resource) {
      SpellResource.mana => copyWith(mana: mana - cost),
      SpellResource.stamina => copyWith(stamina: stamina - cost),
      SpellResource.none => this,
    };
  }

  /// Restores pools, clamped to their maximums.
  HeroCharacter restore({int health = 0, int mana = 0, int stamina = 0}) {
    return copyWith(
      health: (this.health + health).clamp(0, maxHealth),
      mana: (this.mana + mana).clamp(0, maxMana),
      stamina: (this.stamina + stamina).clamp(0, maxStamina),
    );
  }

  /// Torch damage from an event (e.g. a failed encounter).
  HeroCharacter damage(int amount) =>
      copyWith(health: (health - amount).clamp(0, maxHealth));

  List<ActiveBuff> activeBuffsAt(DateTime now) =>
      buffs.where((b) => b.isActiveAt(now)).toList();

  bool hasBuff(BuffType type, DateTime now) =>
      activeBuffsAt(now).any((b) => b.type == type);

  /// Adds (or refreshes) a buff.
  HeroCharacter withBuff(ActiveBuff buff) =>
      copyWith(buffs: [...buffs.where((b) => b.type != buff.type), buff]);

  /// Removes the buff of [type] (after it has been consumed).
  HeroCharacter consumeBuff(BuffType type) =>
      copyWith(buffs: buffs.where((b) => b.type != type).toList());

  HeroCharacter addShieldCharges(int n) => copyWith(
    shieldCharges: (shieldCharges + n).clamp(0, Spell.maxShieldCharges),
  );

  /// Marks a cast of [skillId]: bumps its use count, its proficiency and the
  /// hero's spell tally.
  HeroCharacter useSkill(String skillId) {
    final updated = [
      for (final ls in learnedSkills)
        if (ls.skill.id == skillId)
          ls.copyWith(
            timesUsed: ls.timesUsed + 1,
            level: proficiencyFor(ls.timesUsed + 1),
          )
        else
          ls,
    ];
    return copyWith(learnedSkills: updated, spellsCast: spellsCast + 1);
  }

  LearnedSkill? learnedSkill(String skillId) {
    for (final ls in learnedSkills) {
      if (ls.skill.id == skillId) return ls;
    }
    return null;
  }

  // ---------------------------------------------------------------- stats

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
    return addStats({stat: points}).copyWith(levelUp: remaining);
  }

  /// Get a stat value by name (0 for unknown names).
  int statValue(String statName) => switch (statName) {
    'strength' => strength,
    'dexterity' => dexterity,
    'intelligence' => intelligence,
    'wisdom' => wisdom,
    'charisma' => charisma,
    'constitution' => constitution,
    'luck' => luck,
    _ => 0,
  };

  // ---------------------------------------------------------------- skills & honours

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

  bool hasSkill(String skillId) =>
      learnedSkills.any((s) => s.skill.id == skillId);

  /// Learned passive skills.
  List<LearnedSkill> get passives =>
      learnedSkills.where((s) => s.skill.isPassive).toList();

  bool hasAchievement(String achievementId) =>
      unlockedAchievements.any((a) => a.achievement.id == achievementId);

  // ---------------------------------------------------------------- copyWith

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
    DateTime? lastRestedOn,
    int? shieldCharges,
    List<ActiveBuff>? buffs,
    String? titleAchievementId,
    bool clearTitle = false,
    int? spellsCast,
    int? criticalHits,
    int? encountersResolved,
    int? bossesSlain,
    int? onTimeCompletions,
    List<String>? categoriesCompleted,
    Familiar? familiar,
    bool clearFamiliar = false,
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
      lastRestedOn: lastRestedOn ?? this.lastRestedOn,
      shieldCharges: shieldCharges ?? this.shieldCharges,
      buffs: buffs ?? this.buffs,
      titleAchievementId:
          clearTitle ? null : (titleAchievementId ?? this.titleAchievementId),
      spellsCast: spellsCast ?? this.spellsCast,
      criticalHits: criticalHits ?? this.criticalHits,
      encountersResolved: encountersResolved ?? this.encountersResolved,
      bossesSlain: bossesSlain ?? this.bossesSlain,
      onTimeCompletions: onTimeCompletions ?? this.onTimeCompletions,
      categoriesCompleted: categoriesCompleted ?? this.categoriesCompleted,
      familiar: clearFamiliar ? null : (familiar ?? this.familiar),
    );
  }
}

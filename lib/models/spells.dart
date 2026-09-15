/// Spells: what a learned skill actually does in the game.
///
/// Every *active* entry in `allSkills` maps to one [Spell]. Casting costs
/// mana (magic) or stamina (combat / utility) and either targets a quest or
/// changes the hero. Passive skills have no spell; their effects live in the
/// rules they modify (see the `passive*` helpers at the bottom). The casting
/// rules live in `lib/state/spellbook.dart`; this file is the description.
library;

import 'package:quest_key/models/character_skill.dart';

/// Which resource pool a spell draws from.
enum SpellResource {
  mana('MP'),
  stamina('STA'),
  none('');

  const SpellResource(this.label);
  final String label;
}

/// What a spell needs to be cast on.
enum SpellTarget {
  /// Buffs or shields the hero; no quest involved.
  self,

  /// Any quest still in progress.
  quest,

  /// Only a quest that is past its due date.
  overdueQuest,

  /// All in-progress quests of Trivial difficulty at once.
  trivialQuests,
}

/// Temporary effects a hero can carry.
enum BuffType {
  /// Next Hard or Epic quest completed pays +50% XP.
  empowered('Empowered', '+50% XP on the next Hard or Epic quest'),

  /// Next quest completed before it expires pays +25% XP.
  haste('Haste', '+25% XP on the next quest completed in time'),

  /// Every quest completed until midnight pays +15% XP. Not consumed.
  rallied('Rallied', '+15% XP on every quest until midnight'),

  /// The next completion is a guaranteed critical.
  foresight('Foresight', 'The next quest you finish is a critical'),

  /// Next Epic quest completed pays +100% XP.
  berserk('Berserk', '+100% XP on the next Epic quest');

  const BuffType(this.label, this.description);
  final String label;
  final String description;

  /// Buffs that stay after a completion instead of being used up.
  bool get persists => this == BuffType.rallied;

  static BuffType? fromName(String? name) {
    for (final b in BuffType.values) {
      if (b.name == name) return b;
    }
    return null;
  }
}

/// A buff with an expiry time.
class ActiveBuff {
  const ActiveBuff({required this.type, required this.expiresAt});

  final BuffType type;
  final DateTime expiresAt;

  bool isActiveAt(DateTime now) => now.isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'expiresAt': expiresAt.toIso8601String(),
  };

  static ActiveBuff? fromJson(Map<String, dynamic> json) {
    final type = BuffType.fromName(json['type'] as String?);
    final expires = DateTime.tryParse(json['expiresAt'] as String? ?? '');
    if (type == null || expires == null) return null;
    return ActiveBuff(type: type, expiresAt: expires);
  }

  @override
  bool operator ==(Object other) =>
      other is ActiveBuff && other.type == type && other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(type, expiresAt);
}

/// Description of a castable skill.
class Spell {
  const Spell({
    required this.skillId,
    required this.resource,
    required this.target,
    required this.effect,
    required this.verb,
    this.incantation = '',
  });

  final String skillId;
  final SpellResource resource;
  final SpellTarget target;

  /// One-line effect shown in the spellbook.
  final String effect;

  /// Button label, e.g. "Mend".
  final String verb;

  /// Short flavour line shown while the spell is being cast.
  final String incantation;

  CharacterSkill get skill => allSkills.firstWhere((s) => s.id == skillId);

  bool get targetsQuest =>
      target == SpellTarget.quest || target == SpellTarget.overdueQuest;

  /// Cost after proficiency discount: 15% off per proficiency level above 1.
  int costFor(LearnedSkill? learned) {
    final base = skill.costPerUse;
    final level = learned?.level ?? 1;
    final discount = 1 - 0.15 * (level - 1).clamp(0, 2);
    return (base * discount).round();
  }

  static Spell? forSkill(String skillId) => _spells[skillId];

  static List<Spell> get all => _spells.values.toList();

  static const int maxShieldCharges = 3;

  static const Map<String, Spell> _spells = {
    'power_strike': Spell(
      skillId: 'power_strike',
      resource: SpellResource.stamina,
      target: SpellTarget.self,
      effect: 'Your next Hard or Epic quest pays +50% XP (until midnight).',
      verb: 'Empower',
      incantation: 'Steel remembers.',
    ),
    'swift_strike': Spell(
      skillId: 'swift_strike',
      resource: SpellResource.stamina,
      target: SpellTarget.self,
      effect: 'Haste: the next quest you finish within an hour pays +25% XP.',
      verb: 'Hasten',
      incantation: 'Before the candle gutters.',
    ),
    'fireball': Spell(
      skillId: 'fireball',
      resource: SpellResource.mana,
      target: SpellTarget.quest,
      effect:
          'Burn a quest you will never do. It is removed and you keep a third of its XP.',
      verb: 'Burn',
      incantation: 'Ash keeps no debts.',
    ),
    'heal': Spell(
      skillId: 'heal',
      resource: SpellResource.mana,
      target: SpellTarget.overdueQuest,
      effect:
          'Mend an overdue quest: it becomes due tomorrow, and your torch recovers 30% HP.',
      verb: 'Mend',
      incantation: 'What is broken, knit.',
    ),
    'stealth': Spell(
      skillId: 'stealth',
      resource: SpellResource.stamina,
      target: SpellTarget.quest,
      effect:
          'Slip a quest one day into the future and hide it from Home until tomorrow.',
      verb: 'Snooze',
      incantation: 'Unseen, unhurried.',
    ),
    'shield_bash': Spell(
      skillId: 'shield_bash',
      resource: SpellResource.stamina,
      target: SpellTarget.self,
      effect:
          'Raise one shield charge. A charge absorbs one missed day of torch damage.',
      verb: 'Bulwark',
      incantation: 'Hold the line.',
    ),
    'mana_shield': Spell(
      skillId: 'mana_shield',
      resource: SpellResource.mana,
      target: SpellTarget.self,
      effect: 'Raise two shield charges (up to three) against missed days.',
      verb: 'Ward',
      incantation: 'A wall of quiet light.',
    ),
    'whirlwind': Spell(
      skillId: 'whirlwind',
      resource: SpellResource.stamina,
      target: SpellTarget.trivialQuests,
      effect: 'Finish every Trivial quest in one sweep for full XP plus 10%.',
      verb: 'Sweep',
      incantation: 'All at once, then rest.',
    ),
    'meditate': Spell(
      skillId: 'meditate',
      resource: SpellResource.stamina,
      target: SpellTarget.self,
      effect: 'Trade stamina for focus: restore 35% of your mana.',
      verb: 'Meditate',
      incantation: 'Breathe in; the well refills.',
    ),
    'second_wind': Spell(
      skillId: 'second_wind',
      resource: SpellResource.mana,
      target: SpellTarget.self,
      effect: 'Trade mana for vigour: restore 40% of your stamina.',
      verb: 'Rally',
      incantation: 'Not done yet.',
    ),
    'enchant': Spell(
      skillId: 'enchant',
      resource: SpellResource.mana,
      target: SpellTarget.quest,
      effect: 'Enchant a quest so it pays +25% XP when completed.',
      verb: 'Enchant',
      incantation: 'Gild the ordinary.',
    ),
    'battle_cry': Spell(
      skillId: 'battle_cry',
      resource: SpellResource.stamina,
      target: SpellTarget.self,
      effect: 'Rallied: every quest you finish until midnight pays +15% XP.',
      verb: 'Roar',
      incantation: 'Let them hear you.',
    ),
    'chronoshift': Spell(
      skillId: 'chronoshift',
      resource: SpellResource.mana,
      target: SpellTarget.quest,
      effect: 'Move a quest\'s due date two days later. It stays in view.',
      verb: 'Shift',
      incantation: 'The sand runs backward.',
    ),
    'foresight': Spell(
      skillId: 'foresight',
      resource: SpellResource.mana,
      target: SpellTarget.self,
      effect: 'The next quest you finish is a guaranteed critical (×2 XP).',
      verb: 'Foresee',
      incantation: 'The dice already fell.',
    ),
    'berserk': Spell(
      skillId: 'berserk',
      resource: SpellResource.stamina,
      target: SpellTarget.self,
      effect:
          'Your next Epic quest today pays +100% XP, but the torch loses 10% HP now.',
      verb: 'Rage',
      incantation: 'Pain is a ledger. Pay it.',
    ),
    'divine_favour': Spell(
      skillId: 'divine_favour',
      resource: SpellResource.mana,
      target: SpellTarget.self,
      effect: 'The torch is restored to full and one shield charge is raised.',
      verb: 'Pray',
      incantation: 'Answered.',
    ),
  };
}

/// Proficiency level for a learned skill: one level per five casts, max 3.
int proficiencyFor(int timesUsed) => (1 + timesUsed ~/ 5).clamp(1, 3);

// ---------------------------------------------------------------- tuning

const int ralliedPercent = 15;
const int berserkPercent = 100;
const int enchantPercent = 25;
const double meditateFraction = 0.35;
const double secondWindFraction = 0.40;
const double berserkSelfDamage = 0.10;

/// Passive: Scholar's Focus bonus on Study and Creative quests.
const int scholarsFocusPercent = 10;

/// Passive: Iron Will torch damage per missed day (replaces 25%).
const double ironWillDamagePerMissedDay = 0.15;

/// Passive: Keen Edge critical-chance bonus.
const double keenEdgeCritBonus = 0.05;

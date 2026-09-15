/// Spells: what a learned skill actually does in the game.
///
/// Every entry in `allSkills` maps to one [Spell]. Casting costs mana
/// (magic) or stamina (combat / utility) and either targets a quest or
/// buffs the hero. The rules live in `lib/state/spellbook.dart`; this file
/// is the pure description.
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
  haste('Haste', '+25% XP on the next quest completed in time');

  const BuffType(this.label, this.description);
  final String label;
  final String description;

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
  });

  final String skillId;
  final SpellResource resource;
  final SpellTarget target;

  /// One-line effect shown in the spellbook.
  final String effect;

  /// Button label, e.g. "Mend".
  final String verb;

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
    ),
    'swift_strike': Spell(
      skillId: 'swift_strike',
      resource: SpellResource.stamina,
      target: SpellTarget.self,
      effect: 'Haste: the next quest you finish within an hour pays +25% XP.',
      verb: 'Hasten',
    ),
    'fireball': Spell(
      skillId: 'fireball',
      resource: SpellResource.mana,
      target: SpellTarget.quest,
      effect:
          'Burn a quest you will never do. It is removed and you keep a third of its XP.',
      verb: 'Burn',
    ),
    'heal': Spell(
      skillId: 'heal',
      resource: SpellResource.mana,
      target: SpellTarget.overdueQuest,
      effect:
          'Mend an overdue quest: it becomes due tomorrow, and your torch recovers 30% HP.',
      verb: 'Mend',
    ),
    'stealth': Spell(
      skillId: 'stealth',
      resource: SpellResource.stamina,
      target: SpellTarget.quest,
      effect:
          'Slip a quest one day into the future and hide it from Home until tomorrow.',
      verb: 'Snooze',
    ),
    'shield_bash': Spell(
      skillId: 'shield_bash',
      resource: SpellResource.stamina,
      target: SpellTarget.self,
      effect:
          'Raise one shield charge. A charge absorbs one missed day of torch damage.',
      verb: 'Bulwark',
    ),
    'mana_shield': Spell(
      skillId: 'mana_shield',
      resource: SpellResource.mana,
      target: SpellTarget.self,
      effect: 'Raise two shield charges (up to three) against missed days.',
      verb: 'Ward',
    ),
    'whirlwind': Spell(
      skillId: 'whirlwind',
      resource: SpellResource.stamina,
      target: SpellTarget.trivialQuests,
      effect: 'Finish every Trivial quest in one sweep for full XP plus 10%.',
      verb: 'Sweep',
    ),
  };
}

/// Proficiency level for a learned skill: one level per five casts, max 3.
int proficiencyFor(int timesUsed) => (1 + timesUsed ~/ 5).clamp(1, 3);

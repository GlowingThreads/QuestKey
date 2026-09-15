/// Character skills and abilities.
///
/// A skill is either *active* (it maps to a [Spell] in `spells.dart` and is
/// cast for mana or stamina) or *passive* (category `passive`: always on
/// once learned, with its effect wired into the rules that it changes).
library;

/// Schools a skill can belong to, in display order.
const List<String> skillSchools = ['combat', 'magic', 'utility', 'passive'];

class CharacterSkill {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category; // 'combat', 'magic', 'utility', 'passive'
  final int levelRequired;
  final int costPerUse; // mana or stamina cost (0 for passives)
  final List<String> requirements; // stat requirements

  const CharacterSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.levelRequired,
    required this.costPerUse,
    required this.requirements,
  });

  /// Passive skills are never cast; they change a rule permanently.
  bool get isPassive => category == 'passive';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'levelRequired': levelRequired,
      'costPerUse': costPerUse,
      'requirements': requirements,
    };
  }

  factory CharacterSkill.fromJson(Map<String, dynamic> json) {
    return CharacterSkill(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      category: json['category'],
      levelRequired: json['levelRequired'],
      costPerUse: json['costPerUse'],
      requirements: List<String>.from(json['requirements'] ?? []),
    );
  }
}

/// Every skill a hero can learn.
///
/// The first eight are the original catalogue and keep their ids so saved
/// heroes load unchanged. The rest were added with the wider grimoire.
final List<CharacterSkill> allSkills = [
  const CharacterSkill(
    id: 'power_strike',
    name: 'Power Strike',
    description: 'A devastating melee attack dealing increased damage.',
    icon: '⚔️',
    category: 'combat',
    levelRequired: 1,
    costPerUse: 15,
    requirements: ['strength:5'],
  ),
  const CharacterSkill(
    id: 'swift_strike',
    name: 'Swift Strike',
    description: 'A quick strike that may land a critical hit.',
    icon: '💨',
    category: 'combat',
    levelRequired: 3,
    costPerUse: 10,
    requirements: ['dexterity:6'],
  ),
  const CharacterSkill(
    id: 'fireball',
    name: 'Fireball',
    description: 'Hurl a ball of flames at enemies, dealing area damage.',
    icon: '🔥',
    category: 'magic',
    levelRequired: 5,
    costPerUse: 25,
    requirements: ['intelligence:7'],
  ),
  const CharacterSkill(
    id: 'heal',
    name: 'Heal',
    description: 'Restore health to yourself or an ally.',
    icon: '❤️',
    category: 'magic',
    levelRequired: 3,
    costPerUse: 20,
    requirements: ['wisdom:6'],
  ),
  const CharacterSkill(
    id: 'stealth',
    name: 'Stealth',
    description: 'Blend into shadows for tactical advantage.',
    icon: '🌑',
    category: 'utility',
    levelRequired: 2,
    costPerUse: 10,
    requirements: ['dexterity:7'],
  ),
  const CharacterSkill(
    id: 'shield_bash',
    name: 'Shield Bash',
    description: 'Bash enemies with your shield, stunning them briefly.',
    icon: '🛡️',
    category: 'combat',
    levelRequired: 4,
    costPerUse: 12,
    requirements: ['strength:6', 'constitution:5'],
  ),
  const CharacterSkill(
    id: 'mana_shield',
    name: 'Mana Shield',
    description: 'Use mana to absorb incoming damage.',
    icon: '✨',
    category: 'magic',
    levelRequired: 6,
    costPerUse: 30,
    requirements: ['intelligence:8', 'wisdom:5'],
  ),
  const CharacterSkill(
    id: 'whirlwind',
    name: 'Whirlwind Attack',
    description: 'Spin rapidly to hit all nearby enemies.',
    icon: '🌪️',
    category: 'combat',
    levelRequired: 7,
    costPerUse: 35,
    requirements: ['strength:8', 'dexterity:7'],
  ),

  // ------------------------------------------------------------ new actives
  const CharacterSkill(
    id: 'meditate',
    name: 'Meditate',
    description: 'Still the body to gather the mind.',
    icon: '🧘',
    category: 'utility',
    levelRequired: 2,
    costPerUse: 15,
    requirements: ['wisdom:5'],
  ),
  const CharacterSkill(
    id: 'second_wind',
    name: 'Second Wind',
    description: 'Draw on reserves the body forgot it had.',
    icon: '🌬️',
    category: 'combat',
    levelRequired: 4,
    costPerUse: 15,
    requirements: ['constitution:6'],
  ),
  const CharacterSkill(
    id: 'enchant',
    name: 'Enchant',
    description: 'Lay a glamour on a task so its reward shines brighter.',
    icon: '💫',
    category: 'magic',
    levelRequired: 4,
    costPerUse: 20,
    requirements: ['intelligence:6'],
  ),
  const CharacterSkill(
    id: 'battle_cry',
    name: 'Battle Cry',
    description: 'A roar that rallies everyone within earshot.',
    icon: '📯',
    category: 'combat',
    levelRequired: 5,
    costPerUse: 20,
    requirements: ['charisma:6'],
  ),
  const CharacterSkill(
    id: 'chronoshift',
    name: 'Chronoshift',
    description: 'Bend the hourglass and buy a little time.',
    icon: '⏳',
    category: 'magic',
    levelRequired: 6,
    costPerUse: 20,
    requirements: ['intelligence:7', 'wisdom:6'],
  ),
  const CharacterSkill(
    id: 'foresight',
    name: 'Foresight',
    description: 'Glimpse the outcome before the dice fall.',
    icon: '👁️',
    category: 'utility',
    levelRequired: 8,
    costPerUse: 40,
    requirements: ['luck:7'],
  ),
  const CharacterSkill(
    id: 'berserk',
    name: 'Berserk',
    description: 'Trade caution for fury.',
    icon: '🩸',
    category: 'combat',
    levelRequired: 9,
    costPerUse: 30,
    requirements: ['strength:9'],
  ),
  const CharacterSkill(
    id: 'divine_favour',
    name: 'Divine Favour',
    description: 'A prayer answered in full.',
    icon: '🕊️',
    category: 'magic',
    levelRequired: 10,
    costPerUse: 45,
    requirements: ['wisdom:9'],
  ),

  // ------------------------------------------------------------ passives
  const CharacterSkill(
    id: 'scholars_focus',
    name: "Scholar's Focus",
    description: 'Study and Creative quests pay +10% XP.',
    icon: '📖',
    category: 'passive',
    levelRequired: 3,
    costPerUse: 0,
    requirements: ['intelligence:5', 'wisdom:5'],
  ),
  const CharacterSkill(
    id: 'iron_will',
    name: 'Iron Will',
    description: 'A missed day burns 15% of the torch instead of 25%.',
    icon: '⛓️',
    category: 'passive',
    levelRequired: 5,
    costPerUse: 0,
    requirements: ['constitution:8'],
  ),
  const CharacterSkill(
    id: 'keen_edge',
    name: 'Keen Edge',
    description: 'Critical chance +5%.',
    icon: '🗡️',
    category: 'passive',
    levelRequired: 7,
    costPerUse: 0,
    requirements: ['dexterity:8', 'luck:5'],
  ),
];

/// Active skills only (those that map to a spell).
List<CharacterSkill> get activeSkills =>
    allSkills.where((s) => !s.isPassive).toList();

/// Track learned skills per character
class LearnedSkill {
  final CharacterSkill skill;

  /// Proficiency level (1–3). Derived from [timesUsed]; stored for display.
  final int level;
  final DateTime learnedDate;
  final int timesUsed;

  LearnedSkill({
    required this.skill,
    this.level = 1,
    DateTime? learnedDate,
    this.timesUsed = 0,
  }) : learnedDate = learnedDate ?? DateTime.now();

  LearnedSkill copyWith({int? level, DateTime? learnedDate, int? timesUsed}) {
    return LearnedSkill(
      skill: skill,
      level: level ?? this.level,
      learnedDate: learnedDate ?? this.learnedDate,
      timesUsed: timesUsed ?? this.timesUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skill.id,
      'level': level,
      'learnedDate': learnedDate.toIso8601String(),
      'timesUsed': timesUsed,
    };
  }

  factory LearnedSkill.fromJson(Map<String, dynamic> json) {
    final skillId = json['skillId'];
    final skill = allSkills.firstWhere(
      (s) => s.id == skillId,
      orElse: () => allSkills.first,
    );
    return LearnedSkill(
      skill: skill,
      level: (json['level'] as num?)?.toInt() ?? 1,
      learnedDate:
          DateTime.tryParse(json['learnedDate'] as String? ?? '') ??
          DateTime.now(),
      timesUsed: (json['timesUsed'] as num?)?.toInt() ?? 0,
    );
  }
}

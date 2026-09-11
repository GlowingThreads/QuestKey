/// Character skills and abilities
class CharacterSkill {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category; // 'combat', 'magic', 'utility', 'passive'
  final int levelRequired;
  final int costPerUse; // mana or stamina cost
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

/// Skills learned by characters
final List<CharacterSkill> allSkills = [
  CharacterSkill(
    id: 'power_strike',
    name: 'Power Strike',
    description: 'A devastating melee attack dealing increased damage.',
    icon: '⚔️',
    category: 'combat',
    levelRequired: 1,
    costPerUse: 15,
    requirements: ['strength:5'],
  ),
  CharacterSkill(
    id: 'swift_strike',
    name: 'Swift Strike',
    description: 'A quick strike that may land a critical hit.',
    icon: '💨',
    category: 'combat',
    levelRequired: 3,
    costPerUse: 10,
    requirements: ['dexterity:6'],
  ),
  CharacterSkill(
    id: 'fireball',
    name: 'Fireball',
    description: 'Hurl a ball of flames at enemies, dealing area damage.',
    icon: '🔥',
    category: 'magic',
    levelRequired: 5,
    costPerUse: 25,
    requirements: ['intelligence:7'],
  ),
  CharacterSkill(
    id: 'heal',
    name: 'Heal',
    description: 'Restore health to yourself or an ally.',
    icon: '❤️',
    category: 'magic',
    levelRequired: 3,
    costPerUse: 20,
    requirements: ['wisdom:6'],
  ),
  CharacterSkill(
    id: 'stealth',
    name: 'Stealth',
    description: 'Blend into shadows for tactical advantage.',
    icon: '🌑',
    category: 'utility',
    levelRequired: 2,
    costPerUse: 10,
    requirements: ['dexterity:7'],
  ),
  CharacterSkill(
    id: 'shield_bash',
    name: 'Shield Bash',
    description: 'Bash enemies with your shield, stunning them briefly.',
    icon: '🛡️',
    category: 'combat',
    levelRequired: 4,
    costPerUse: 12,
    requirements: ['strength:6', 'constitution:5'],
  ),
  CharacterSkill(
    id: 'mana_shield',
    name: 'Mana Shield',
    description: 'Use mana to absorb incoming damage.',
    icon: '✨',
    category: 'magic',
    levelRequired: 6,
    costPerUse: 30,
    requirements: ['intelligence:8', 'wisdom:5'],
  ),
  CharacterSkill(
    id: 'whirlwind',
    name: 'Whirlwind Attack',
    description: 'Spin rapidly to hit all nearby enemies.',
    icon: '🌪️',
    category: 'combat',
    levelRequired: 7,
    costPerUse: 35,
    requirements: ['strength:8', 'dexterity:7'],
  ),
];

/// Track learned skills per character
class LearnedSkill {
  final CharacterSkill skill;
  int level; // skill proficiency level
  DateTime learnedDate;
  int timesUsed;

  LearnedSkill({
    required this.skill,
    this.level = 1,
    DateTime? learnedDate,
    this.timesUsed = 0,
  }) : learnedDate = learnedDate ?? DateTime.now();

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
      level: json['level'],
      learnedDate: DateTime.parse(json['learnedDate']),
      timesUsed: json['timesUsed'],
    );
  }
}

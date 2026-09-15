/// Character achievements and milestones
class CharacterAchievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category; // 'progress', 'combat', 'exploration', 'challenge'
  final bool hidden; // hidden achievements show ??? until unlocked
  final int rarityScore; // 1-5 for rarity

  const CharacterAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.hidden = false,
    this.rarityScore = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'hidden': hidden,
      'rarityScore': rarityScore,
    };
  }

  factory CharacterAchievement.fromJson(Map<String, dynamic> json) {
    return CharacterAchievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      category: json['category'],
      hidden: json['hidden'] ?? false,
      rarityScore: json['rarityScore'] ?? 1,
    );
  }
}

/// Track unlocked achievements
class UnlockedAchievement {
  final CharacterAchievement achievement;
  final DateTime unlockedDate;
  final int progressPercentage; // for progressive achievements

  UnlockedAchievement({
    required this.achievement,
    DateTime? unlockedDate,
    this.progressPercentage = 100,
  }) : unlockedDate = unlockedDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievement.id,
      'unlockedDate': unlockedDate.toIso8601String(),
      'progressPercentage': progressPercentage,
    };
  }

  factory UnlockedAchievement.fromJson(
    Map<String, dynamic> json,
    List<CharacterAchievement> allAchievements,
  ) {
    final achievementId = json['achievementId'];
    final achievement = allAchievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => allAchievements.first,
    );
    return UnlockedAchievement(
      achievement: achievement,
      unlockedDate: DateTime.parse(json['unlockedDate']),
      progressPercentage: json['progressPercentage'] ?? 100,
    );
  }
}

// Predefined achievements
final List<CharacterAchievement> allAchievements = [
  const CharacterAchievement(
    id: 'first_quest',
    name: 'Quest Initiate',
    description: 'Complete your first quest.',
    icon: '✨',
    category: 'progress',
    rarityScore: 1,
  ),
  const CharacterAchievement(
    id: 'first_level',
    name: 'Leveled Up',
    description: 'Reach level 2.',
    icon: '📈',
    category: 'progress',
    rarityScore: 1,
  ),
  const CharacterAchievement(
    id: 'quest_master',
    name: 'Quest Master',
    description: 'Complete 10 quests.',
    icon: '👑',
    category: 'progress',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'level_ten',
    name: 'Veteran',
    description: 'Reach level 10.',
    icon: '🏆',
    category: 'progress',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'stat_master',
    name: 'Stat Allocator',
    description: 'Allocate all available stat points.',
    icon: '⚡',
    category: 'progress',
    rarityScore: 2,
  ),
  const CharacterAchievement(
    id: 'speedrunner',
    name: 'Speedrunner',
    description: 'Complete 5 quests in a single day.',
    icon: '⚡',
    category: 'challenge',
    rarityScore: 4,
  ),
  const CharacterAchievement(
    id: 'perfectionist',
    name: 'Perfectionist',
    description: 'Complete 10 consecutive quests without a day off.',
    icon: '💎',
    category: 'challenge',
    rarityScore: 4,
  ),
  const CharacterAchievement(
    id: 'balanced_hero',
    name: 'Balanced Hero',
    description: 'Achieve 5 stat points in all attributes.',
    icon: '⚖️',
    category: 'progress',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'specialist',
    name: 'Specialist',
    description: 'Get 10 points in any single stat.',
    icon: '🎯',
    category: 'progress',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'spell_caster',
    name: 'Spellweaver',
    description: 'Cast your first spell.',
    icon: '🪄',
    category: 'progress',
    rarityScore: 1,
  ),
  const CharacterAchievement(
    id: 'spell_master',
    name: 'Archmage',
    description: 'Cast 25 spells.',
    icon: '🔮',
    category: 'progress',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'lucky_strike',
    name: 'Fortune\'s Favourite',
    description: 'Land a critical completion.',
    icon: '🍀',
    category: 'challenge',
    rarityScore: 2,
  ),
  const CharacterAchievement(
    id: 'encounter_victor',
    name: 'Trailblazer',
    description: 'Resolve an encounter.',
    icon: '🗺️',
    category: 'exploration',
    rarityScore: 2,
  ),
  const CharacterAchievement(
    id: 'boss_slayer',
    name: 'Giant Slayer',
    description: 'Complete a boss quest with every step done.',
    icon: '🐉',
    category: 'challenge',
    rarityScore: 4,
  ),
  const CharacterAchievement(
    id: 'torch_bearer',
    name: 'Torch Bearer',
    description: 'Keep the flame alive through a missed day.',
    icon: '🔥',
    category: 'challenge',
    rarityScore: 3,
  ),
  // Hidden: shown as ??? until unlocked. Earned by completing a quest
  // between midnight and 4 am (see achievement_rules.dart).
  const CharacterAchievement(
    id: 'secret_hidden',
    name: 'Night Owl',
    description: 'Complete a quest between midnight and 4 am.',
    icon: '🦉',
    category: 'challenge',
    hidden: true,
    rarityScore: 5,
  ),
];

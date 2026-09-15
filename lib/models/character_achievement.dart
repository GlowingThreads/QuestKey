/// Character achievements ("honours") and milestones.
library;

/// Honour categories in display order, with the label shown as a section
/// heading in the Hall of Honours.
const Map<String, String> achievementCategoryLabels = {
  'progress': 'The Road',
  'challenge': 'Trials',
  'mastery': 'Mastery',
  'exploration': 'Wayfaring',
};

class CharacterAchievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category; // 'progress', 'challenge', 'mastery', 'exploration'
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

/// Player-facing name for a rarity score.
String rarityLabel(int rarityScore) => switch (rarityScore) {
  1 => 'Common',
  2 => 'Uncommon',
  3 => 'Rare',
  4 => 'Epic',
  _ => 'Legendary',
};

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

/// Every honour. Ids are stable: saved heroes refer to them by id.
///
/// The rules that unlock each one live in `achievement_rules.dart`.
final List<CharacterAchievement> allAchievements = [
  // ------------------------------------------------------------ The Road
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
    id: 'streak_3',
    name: 'Kindling',
    description: 'Keep a three-day streak.',
    icon: '🕯️',
    category: 'progress',
    rarityScore: 1,
  ),
  const CharacterAchievement(
    id: 'level_five',
    name: 'Adept',
    description: 'Reach level 5.',
    icon: '🎖️',
    category: 'progress',
    rarityScore: 2,
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
    id: 'quest_50',
    name: 'Seasoned',
    description: 'Complete 50 quests.',
    icon: '🛡️',
    category: 'progress',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'quest_100',
    name: 'Centurion',
    description: 'Complete 100 quests.',
    icon: '🏛️',
    category: 'progress',
    rarityScore: 4,
  ),
  const CharacterAchievement(
    id: 'level_twenty',
    name: 'Champion',
    description: 'Reach level 20.',
    icon: '🌟',
    category: 'progress',
    rarityScore: 4,
  ),
  const CharacterAchievement(
    id: 'title_worn',
    name: 'Heraldry',
    description: 'Wear an honour as your title.',
    icon: '🎗️',
    category: 'progress',
    rarityScore: 1,
  ),

  // ------------------------------------------------------------ Trials
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
    id: 'streak_30',
    name: 'Eternal Flame',
    description: 'Keep a thirty-day streak.',
    icon: '🔥',
    category: 'challenge',
    rarityScore: 5,
  ),
  const CharacterAchievement(
    id: 'epic_first',
    name: 'Dragonheart',
    description: 'Complete an Epic quest.',
    icon: '🐲',
    category: 'challenge',
    rarityScore: 2,
  ),
  const CharacterAchievement(
    id: 'punctual',
    name: 'Clockwork',
    description: 'Complete 10 quests before they fall due.',
    icon: '⏱️',
    category: 'challenge',
    rarityScore: 2,
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
    id: 'crit_10',
    name: 'Blessed by Fortune',
    description: 'Land 10 critical completions.',
    icon: '🎲',
    category: 'challenge',
    rarityScore: 3,
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
    id: 'boss_5',
    name: 'Dragonslayer',
    description: 'Complete 5 boss quests.',
    icon: '⚔️',
    category: 'challenge',
    rarityScore: 5,
  ),
  const CharacterAchievement(
    id: 'torch_bearer',
    name: 'Torch Bearer',
    description: 'Keep the flame alive through a missed day.',
    icon: '🔥',
    category: 'challenge',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'bulwark',
    name: 'Bulwark',
    description: 'Hold three shield charges at once.',
    icon: '🛡️',
    category: 'challenge',
    rarityScore: 2,
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
  const CharacterAchievement(
    id: 'early_bird',
    name: 'Dawn Patrol',
    description: 'Complete a quest between 5 and 7 am.',
    icon: '🌅',
    category: 'challenge',
    hidden: true,
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'weekend_warrior',
    name: 'Weekend Warrior',
    description: 'Complete 3 quests on a Saturday or Sunday.',
    icon: '🏕️',
    category: 'challenge',
    hidden: true,
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'ashes',
    name: 'From the Ashes',
    description: 'Lose the flame, and relight it.',
    icon: '🕊️',
    category: 'challenge',
    hidden: true,
    rarityScore: 2,
  ),

  // ------------------------------------------------------------ Mastery
  const CharacterAchievement(
    id: 'stat_master',
    name: 'Stat Allocator',
    description: 'Allocate all available stat points.',
    icon: '⚡',
    category: 'mastery',
    rarityScore: 2,
  ),
  const CharacterAchievement(
    id: 'balanced_hero',
    name: 'Balanced Hero',
    description: 'Achieve 5 stat points in all attributes.',
    icon: '⚖️',
    category: 'mastery',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'specialist',
    name: 'Specialist',
    description: 'Get 10 points in any single stat.',
    icon: '🎯',
    category: 'mastery',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'paragon',
    name: 'Paragon',
    description: 'Reach 10 in every attribute.',
    icon: '🔱',
    category: 'mastery',
    rarityScore: 5,
  ),
  const CharacterAchievement(
    id: 'first_skill',
    name: 'Apprentice',
    description: 'Learn your first skill.',
    icon: '📜',
    category: 'mastery',
    rarityScore: 1,
  ),
  const CharacterAchievement(
    id: 'spell_caster',
    name: 'Spellweaver',
    description: 'Cast your first spell.',
    icon: '🪄',
    category: 'mastery',
    rarityScore: 1,
  ),
  const CharacterAchievement(
    id: 'spell_master',
    name: 'Archmage',
    description: 'Cast 25 spells.',
    icon: '🔮',
    category: 'mastery',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'spell_100',
    name: 'Grand Magus',
    description: 'Cast 100 spells.',
    icon: '🌌',
    category: 'mastery',
    rarityScore: 5,
  ),
  const CharacterAchievement(
    id: 'enchanter',
    name: 'Gilded Hand',
    description: 'Complete an enchanted quest.',
    icon: '💫',
    category: 'mastery',
    rarityScore: 2,
  ),
  const CharacterAchievement(
    id: 'loremaster',
    name: 'Loremaster',
    description: 'Learn every skill in the grimoire.',
    icon: '📚',
    category: 'mastery',
    rarityScore: 4,
  ),

  // ------------------------------------------------------------ Wayfaring
  const CharacterAchievement(
    id: 'encounter_victor',
    name: 'Trailblazer',
    description: 'Resolve an encounter.',
    icon: '🗺️',
    category: 'exploration',
    rarityScore: 2,
  ),
  const CharacterAchievement(
    id: 'wayfarer',
    name: 'Wayfarer',
    description: 'Resolve 10 encounters.',
    icon: '🧭',
    category: 'exploration',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'well_rounded',
    name: 'Well Travelled',
    description: 'Complete a quest in every category.',
    icon: '🌍',
    category: 'exploration',
    rarityScore: 3,
  ),
  const CharacterAchievement(
    id: 'hearth_friend',
    name: 'Hearth Friend',
    description: 'Adopt a familiar.',
    icon: '🐾',
    category: 'exploration',
    rarityScore: 1,
  ),
  const CharacterAchievement(
    id: 'kindred',
    name: 'Kindred Spirit',
    description: 'Raise a familiar to Soulbound.',
    icon: '🌙',
    category: 'exploration',
    rarityScore: 4,
  ),
];

/// Honours grouped by category, in [achievementCategoryLabels] order.
Map<String, List<CharacterAchievement>> achievementsByCategory() => {
  for (final key in achievementCategoryLabels.keys)
    key: allAchievements.where((a) => a.category == key).toList(),
};

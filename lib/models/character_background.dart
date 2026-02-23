/// Character background/origin system
class CharacterBackground {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji or icon reference
  final Map<String, int> statBonus; // stat boosts from background
  final String flavorText;

  const CharacterBackground({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.statBonus,
    required this.flavorText,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'statBonus': statBonus,
      'flavorText': flavorText,
    };
  }

  factory CharacterBackground.fromJson(Map<String, dynamic> json) {
    return CharacterBackground(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      statBonus: Map<String, int>.from(json['statBonus'] ?? {}),
      flavorText: json['flavorText'],
    );
  }
}

// Predefined backgrounds
final List<CharacterBackground> backgroundsList = [
  CharacterBackground(
    id: 'noble',
    name: 'Noble Born',
    description: 'You come from a noble family with prestige and training.',
    icon: '👑',
    statBonus: {'charisma': 2, 'intelligence': 1},
    flavorText:
        'Raised in courts and halls of power, you command respect through lineage.',
  ),
  CharacterBackground(
    id: 'merchant',
    name: 'Merchant',
    description: 'A skilled trader who understands value and negotiation.',
    icon: '💰',
    statBonus: {'charisma': 2, 'intelligence': 1},
    flavorText: 'Your silver tongue and keen eye for deals serve you well.',
  ),
  CharacterBackground(
    id: 'soldier',
    name: 'Soldier',
    description: 'Hardened by military service and discipline.',
    icon: '⚔️',
    statBonus: {'strength': 2, 'constitution': 1},
    flavorText: 'Years of training and combat have forged your body and spirit.',
  ),
  CharacterBackground(
    id: 'scholar',
    name: 'Scholar',
    description: 'A learned individual steeped in knowledge and wisdom.',
    icon: '📚',
    statBonus: {'intelligence': 2, 'wisdom': 1},
    flavorText: 'Books are your greatest allies in unraveling worldly mysteries.',
  ),
  CharacterBackground(
    id: 'orphan',
    name: 'Street Orphan',
    description: 'Raised on the streets, you learned to survive through cunning.',
    icon: '🏚️',
    statBonus: {'dexterity': 2, 'luck': 1},
    flavorText: 'The streets taught you independence and sharp instincts.',
  ),
  CharacterBackground(
    id: 'monk_train',
    name: 'Temple Trained',
    description: 'Disciplined in a monastery, seeking balance and enlightenment.',
    icon: '🏯',
    statBonus: {'wisdom': 2, 'constitution': 1},
    flavorText: 'Meditation and spiritual training shaped your inner strength.',
  ),
  CharacterBackground(
    id: 'hunter',
    name: 'Wilderness Hunter',
    description: 'Skilled in tracking and survival in the wild.',
    icon: '🏹',
    statBonus: {'dexterity': 2, 'wisdom': 1},
    flavorText: 'The forests and plains are your home and hunting ground.',
  ),
  CharacterBackground(
    id: 'cursed',
    name: 'Cursed Soul',
    description: 'Marked by fate with both burden and power.',
    icon: '⚡',
    statBonus: {'intelligence': 2, 'luck': 1},
    flavorText: 'Dark magic flows through you, granting power at a cost.',
  ),
];

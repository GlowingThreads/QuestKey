/// Familiars: a shadow companion adopted at the hearth on the Home tab.
///
/// A familiar has no needs to neglect; it grows a bond with every quest the
/// hero completes and, once bonded, lends a small XP bonus. Its mood is
/// read from the hero's state (torch, streak, today's work) each time it is
/// drawn, so it reacts without any extra bookkeeping.
library;

import 'package:quest_key/models/character.dart';

enum FamiliarSpecies {
  cat('Cat', 'A shadow cat. Aloof, then suddenly not.'),
  hound('Hound', 'A shadow hound. Loyal past all reason.'),
  weasel('Weasel', 'A shadow weasel. Into everything, especially your bag.'),
  owl('Owl', 'A shadow owl. Sees what you would rather not.');

  const FamiliarSpecies(this.label, this.lore);
  final String label;
  final String lore;

  static FamiliarSpecies? fromName(String? name) {
    for (final s in FamiliarSpecies.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// How the familiar feels right now, read from the hero's state.
enum FamiliarMood {
  /// Torch is low or the flame is out.
  sleepy,

  /// Nothing done yet today.
  watchful,

  /// At least one quest done today.
  content,

  /// A strong streak and a full torch.
  joyful,
}

/// Bond thresholds (quests completed since adoption) and their titles.
const List<({int bond, String title, int bonusPercent})> familiarTiers = [
  (bond: 0, title: 'Stray', bonusPercent: 0),
  (bond: 10, title: 'Companion', bonusPercent: 2),
  (bond: 30, title: 'Bonded', bonusPercent: 4),
  (bond: 60, title: 'Soulbound', bonusPercent: 6),
];

class Familiar {
  const Familiar({
    required this.species,
    required this.name,
    required this.adoptedOn,
    this.bond = 0,
    this.timesPetted = 0,
  });

  final FamiliarSpecies species;
  final String name;
  final DateTime adoptedOn;

  /// Quests completed since adoption.
  final int bond;
  final int timesPetted;

  int get tier {
    var t = 0;
    for (var i = 0; i < familiarTiers.length; i++) {
      if (bond >= familiarTiers[i].bond) t = i;
    }
    return t;
  }

  String get tierTitle => familiarTiers[tier].title;

  /// XP bonus the familiar lends at its current tier.
  int get bonusPercent => familiarTiers[tier].bonusPercent;

  bool get isSoulbound => tier == familiarTiers.length - 1;

  /// Bond needed for the next tier, or `null` at the top.
  int? get nextTierBond =>
      tier + 1 < familiarTiers.length ? familiarTiers[tier + 1].bond : null;

  /// Progress (0–1) through the current tier.
  double get tierProgress {
    final next = nextTierBond;
    if (next == null) return 1;
    final start = familiarTiers[tier].bond;
    return ((bond - start) / (next - start)).clamp(0.0, 1.0);
  }

  Familiar copyWith({String? name, int? bond, int? timesPetted}) => Familiar(
    species: species,
    name: name ?? this.name,
    adoptedOn: adoptedOn,
    bond: bond ?? this.bond,
    timesPetted: timesPetted ?? this.timesPetted,
  );

  Map<String, dynamic> toJson() => {
    'species': species.name,
    'name': name,
    'adoptedOn': adoptedOn.toIso8601String(),
    'bond': bond,
    'timesPetted': timesPetted,
  };

  static Familiar? fromJson(Map<String, dynamic> json) {
    final species = FamiliarSpecies.fromName(json['species'] as String?);
    if (species == null) return null;
    return Familiar(
      species: species,
      name:
          (json['name'] as String?)?.trim().isNotEmpty == true
              ? json['name'] as String
              : species.label,
      adoptedOn:
          DateTime.tryParse(json['adoptedOn'] as String? ?? '') ??
          DateTime.now(),
      bond: (json['bond'] as num?)?.toInt() ?? 0,
      timesPetted: (json['timesPetted'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Familiar &&
      other.species == species &&
      other.name == name &&
      other.adoptedOn == adoptedOn &&
      other.bond == bond &&
      other.timesPetted == timesPetted;

  @override
  int get hashCode => Object.hash(species, name, adoptedOn, bond, timesPetted);
}

/// Reads the familiar's mood from the hero at [now].
FamiliarMood familiarMoodFor(
  HeroCharacter hero, {
  required DateTime now,
  required int completedToday,
}) {
  final torch = hero.maxHealth == 0 ? 0.0 : hero.health / hero.maxHealth;
  if (torch < 0.3) return FamiliarMood.sleepy;
  if (completedToday == 0) return FamiliarMood.watchful;
  if (torch >= 0.9 && hero.isStreakAliveAt(now) && hero.currentStreak >= 3) {
    return FamiliarMood.joyful;
  }
  return FamiliarMood.content;
}

/// A short line for the hearth panel.
String familiarLine(Familiar familiar, FamiliarMood mood) {
  final n = familiar.name;
  return switch ((familiar.species, mood)) {
    (FamiliarSpecies.cat, FamiliarMood.sleepy) =>
      '$n curls tighter. The torch is low; it can feel the cold.',
    (FamiliarSpecies.cat, FamiliarMood.watchful) =>
      '$n watches the door and pretends not to wait for you.',
    (FamiliarSpecies.cat, FamiliarMood.content) =>
      '$n kneads the hearthstone. Good work, apparently.',
    (FamiliarSpecies.cat, FamiliarMood.joyful) =>
      '$n brings you something it caught. It is a streak.',
    (FamiliarSpecies.hound, FamiliarMood.sleepy) =>
      '$n lies across your feet, guarding what flame is left.',
    (FamiliarSpecies.hound, FamiliarMood.watchful) =>
      '$n sits by the log with its lead in its mouth.',
    (FamiliarSpecies.hound, FamiliarMood.content) =>
      '$n thumps its tail. One quest is enough to be a hero to a hound.',
    (FamiliarSpecies.hound, FamiliarMood.joyful) =>
      '$n cannot sit still. The streak burns and so does its tail.',
    (FamiliarSpecies.weasel, FamiliarMood.sleepy) =>
      '$n has poured itself into your boot to sleep.',
    (FamiliarSpecies.weasel, FamiliarMood.watchful) =>
      '$n keeps checking the quest log, then checking you.',
    (FamiliarSpecies.weasel, FamiliarMood.content) =>
      '$n does a small victory dance. It is mostly wriggling.',
    (FamiliarSpecies.weasel, FamiliarMood.joyful) =>
      '$n is doing laps of the hearth. The streak has gone to its head.',
    (FamiliarSpecies.owl, FamiliarMood.sleepy) =>
      '$n has closed one eye. It is saving the other for you.',
    (FamiliarSpecies.owl, FamiliarMood.watchful) =>
      '$n turns its head all the way round to look at your quest log.',
    (FamiliarSpecies.owl, FamiliarMood.content) =>
      '$n blinks slowly. From an owl, that is applause.',
    (FamiliarSpecies.owl, FamiliarMood.joyful) =>
      '$n hoots at the dawn. The streak is long and the night is short.',
  };
}

/// What the familiar says when petted.
String familiarPettedLine(Familiar familiar) => switch (familiar.species) {
  FamiliarSpecies.cat => '${familiar.name} allows it. Briefly.',
  FamiliarSpecies.hound => '${familiar.name} leans its whole weight on you.',
  FamiliarSpecies.weasel => '${familiar.name} chatters and steals a button.',
  FamiliarSpecies.owl => '${familiar.name} fluffs up to twice its size.',
};

/// Suggested names, by species.
const Map<FamiliarSpecies, List<String>> familiarNames = {
  FamiliarSpecies.cat: ['Nyx', 'Soot', 'Vesper', 'Ash', 'Grimalkin', 'Pyre'],
  FamiliarSpecies.hound: ['Barrow', 'Ember', 'Gnash', 'Wolfram', 'Brand'],
  FamiliarSpecies.weasel: ['Pip', 'Ferrous', 'Nettle', 'Sprocket', 'Tallow'],
  FamiliarSpecies.owl: ['Umbra', 'Sable', 'Quill', 'Moth', 'Noctis', 'Vigil'],
};

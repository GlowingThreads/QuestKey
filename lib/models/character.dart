// character model
import 'package:quest_key/models/classes.dart';
import 'package:quest_key/state/app_state.dart';

//hero character model
class HeroCharacter {
  final String name;
  final String motto;
  final Classes classes;
  final String description;
  final String imageUrl;
  final LevelUp levelUp;

  int strength;
  int dexterity;
  int intelligence;
  int wisdom;
  int charisma;
  int constitution;
  int luck;

  int health;
  int mana;
  int stamina;

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
  });

  factory HeroCharacter.fromClasses(Classes classes) {
    return HeroCharacter(
      name: classes.className,
      motto: 'A brave hero',
      classes: classes,
      strength: classes.strength,
      dexterity: classes.dexterity,
      imageUrl: classes.classImageUrl,
      levelUp: LevelUp(level: 1, exp: 0, maxExp: 100, statPoints: 0),
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
  // add mapping
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
    };
  }

  factory HeroCharacter.fromJson(Map<String, dynamic> json) {
    return HeroCharacter(
      name: json['name'],
      motto: json['motto'],
      classes: Classes.fromJson(json['classes']),
      description: json['description'],
      imageUrl: json['imageUrl'],
      levelUp: LevelUp.fromJson(json['levelUp']),
      strength: json['strength'],
      dexterity: json['dexterity'],
      intelligence: json['intelligence'],
      wisdom: json['wisdom'],
      charisma: json['charisma'],
      constitution: json['constitution'],
      luck: json['luck'],
      health: json['health'],
      mana: json['mana'],
      stamina: json['stamina'],
    );
  }

  bool gainExperience(int amount) {
    levelUp.exp += amount;
    if (levelUp.exp >= levelUp.maxExp) {
      levelUp.levelUp();

      // Update hero stats
      health = 100 + (levelUp.level * 5);
      mana = 50 + (levelUp.level * 5);
      stamina = 75 + (levelUp.level * 8);

      return true;
    }
    return false;
  }

  void assignStatPoints(String stat, int points) {
    if (points > levelUp.statPoints) {
      throw Exception('Not enough stat points available');
    }

    switch (stat) {
      case 'strength':
        strength += points;
        break;
      case 'dexterity':
        dexterity += points;
        break;
      case 'intelligence':
        intelligence += points;
        break;
      case 'wisdom':
        wisdom += points;
        break;
      case 'charisma':
        charisma += points;
        break;
      case 'constitution':
        constitution += points;
        break;
      case 'luck':
        luck += points;
        break;
      default:
        throw Exception('Invalid stat name');
    }

    levelUp.statPoints -= points;
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
    );
  }
}

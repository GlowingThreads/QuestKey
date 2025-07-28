//stat class
import 'package:quest_key/models/classes.dart';

class StatPoints {
  int strength;
  int dexterity;
  int intelligence;
  int wisdom;
  int charisma;
  int constitution;
  int luck;
  int level;
  int experience;
  int health;
  int mana;
  int stamina;

  StatPoints({
    this.strength = 0,
    this.dexterity = 0,
    this.intelligence = 0,
    this.wisdom = 0,
    this.charisma = 0,
    this.constitution = 0,
    this.luck = 0,
    this.level = 0,
    this.experience = 0,
    this.health = 0,
    this.mana = 0,
    this.stamina = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'strength': strength,
      'dexterity': dexterity,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'constitution': constitution,
      'luck': luck,
      'level': level,
      'experience': experience,
      'health': health,
      'mana': mana,
      'stamina': stamina,
    };
  }

  factory StatPoints.fromJson(Map<String, dynamic> json) {
    return StatPoints(
      strength: json['strength'],
      dexterity: json['dexterity'],
      intelligence: json['intelligence'],
      wisdom: json['wisdom'],
      charisma: json['charisma'],
      constitution: json['constitution'],
      luck: json['luck'],
      level: json['level'],
      experience: json['experience'],
      health: json['health'],
      mana: json['mana'],
      stamina: json['stamina'],
    );
  }
  // factory for moving from class choice to stats
  factory StatPoints.fromClass(Classes c) {
    return StatPoints(
      strength: c.strength,
      dexterity: c.dexterity,
      intelligence: c.intelligence,
      wisdom: c.wisdom,
      charisma: c.charisma,
      constitution: c.constitution,
      luck: c.luck,
      mana: c.mana,
      stamina: c.stamina,
      health: c.health,
      level: c.level,
      experience: c.experience,
    );
  }
}

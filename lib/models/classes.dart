// define the classes of the app.
// it contains the base stats for the class chosen by the user.

class Classes {
  Classes({
    required this.className,
    required this.classImageUrl,
    required this.description,
    required this.strength,
    required this.dexterity,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    required this.constitution,
    required this.luck,
    required this.level,
    required this.experience,
    required this.health,
    required this.mana,
    required this.stamina,
  });

  String className;
  String classImageUrl;
  String description;
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

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'classImageUrl': classImageUrl,
      'description': description,
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

  factory Classes.fromJson(Map<String, dynamic> json) {
    return Classes(
      className: json['className'],
      classImageUrl: json['classImageUrl'],
      description: json['description'],
      strength: json['strength'],
      intelligence: json['intelligence'],
      dexterity: json['dexterity'],
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

  @override
  String toString() {
    return 'Classes{className: $className, classImageUrl: $classImageUrl, description: $description, strength: $strength, dexterity: $dexterity, intelligence: $intelligence, wisdom: $wisdom, charisma: $charisma, constitution: $constitution, luck: $luck, level: $level, experience: $experience, health: $health, mana: $mana, stamina: $stamina}';
  }
}

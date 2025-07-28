//values for the classes in the app
import 'package:quest_key/models/classes.dart';

final List<Classes> classesList = [
  fighter,
  wizard,
  rogue,
  paladin,
  warlock,
  monk,
  cleric,
  ranger,
  barbarian,
];

// starter values for classes
Classes fighter = Classes(
  className: 'Fighter',
  classImageUrl: 'assets/images/class_images/fighter.png',
  description: 'A versatile figther with high strength and dexterity.',
  strength: 7,
  dexterity: 7,
  intelligence: 2,
  wisdom: 2,
  charisma: 4,
  constitution: 4,
  luck: 1,
  level: 1,
  experience: 0,
  health: 100,
  mana: 20,
  stamina: 50,
);

Classes wizard = Classes(
  className: 'Wizard',
  classImageUrl: 'assets/images/class_images/wizard.png',
  description: 'A magic user with high intelligence and wisdom',
  strength: 2,
  dexterity: 3,
  intelligence: 3,
  wisdom: 3,
  charisma: 4,
  constitution: 2,
  luck: 1,
  level: 1,
  experience: 0,
  health: 80,
  mana: 100,
  stamina: 30,
);

Classes rogue = Classes(
  className: 'Rogue',
  classImageUrl: 'assets/images/class_images/rouge.png',
  description: 'A stealthy rogue with high dexterity and luck.',
  strength: 5,
  dexterity: 10,
  intelligence: 3,
  wisdom: 2,
  charisma: 4,
  constitution: 3,
  luck: 8,
  level: 1,
  experience: 0,
  health: 90,
  mana: 30,
  stamina: 40,
);

Classes paladin = Classes(
  className: 'Paladin',
  classImageUrl: 'assets/images/class_images/paladin.png',
  description: 'A holy warrior with high strength and wisdom.',
  strength: 8,
  dexterity: 4,
  intelligence: 3,
  wisdom: 7,
  charisma: 5,
  constitution: 6,
  luck: 2,
  level: 1,
  experience: 0,
  health: 120,
  mana: 40,
  stamina: 60,
);

Classes warlock = Classes(
  className: 'Warlock',
  classImageUrl: 'assets/images/class_images/warlock.png',
  description:
      'A magic user tangled in arts of the soul, high intellegence and constitution.',
  strength: 3,
  dexterity: 4,
  intelligence: 8,
  wisdom: 8,
  charisma: 5,
  constitution: 7,
  luck: 2,
  level: 1,
  experience: 0,
  health: 90,
  mana: 120,
  stamina: 30,
);

Classes monk = Classes(
  className: 'Monk',
  classImageUrl: 'assets/images/class_images/monk.png',
  description:
      'A humble master of the martial arts, high intellegence and dexterity.',
  strength: 5,
  dexterity: 8,
  intelligence: 8,
  wisdom: 3,
  charisma: 4,
  constitution: 2,
  luck: 2,
  level: 1,
  experience: 0,
  health: 80,
  mana: 50,
  stamina: 40,
);

Classes cleric = Classes(
  className: 'Cleric',
  classImageUrl: 'assets/images/class_images/cleric.png',
  description: 'A holy magic user that relys on wisdom and intellegence.',
  strength: 2,
  dexterity: 3,
  intelligence: 8,
  wisdom: 4,
  charisma: 3,
  constitution: 8,
  luck: 1,
  level: 1,
  experience: 0,
  health: 70,
  mana: 150,
  stamina: 20,
);

Classes ranger = Classes(
  className: 'Ranger',
  classImageUrl: 'assets/images/class_images/ranger.png',
  description: 'A skilled archer with high dexterity and luck.',
  strength: 4,
  dexterity: 10,
  intelligence: 3,
  wisdom: 2,
  charisma: 5,
  constitution: 4,
  luck: 7,
  level: 1,
  experience: 0,
  health: 85,
  mana: 30,
  stamina: 50,
);

Classes barbarian = Classes(
  className: 'Barbarian',
  classImageUrl: 'assets/images/class_images/barbarian.png',
  description: 'The strongest of warriors, high strength and charisma.',
  strength: 10,
  dexterity: 4,
  intelligence: 2,
  wisdom: 4,
  charisma: 6,
  constitution: 3,
  luck: 2,
  level: 1,
  experience: 0,
  health: 150,
  mana: 10,
  stamina: 80,
);

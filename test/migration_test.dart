import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quest JSON exactly as the pre-refactor app wrote it.
Map<String, dynamic> _legacyQuestJson() => {
  'id': 7,
  'title': 'Old quest',
  'description': 'Written by the old app',
  'status': 'Completed',
  'xpReward': 150,
  'startDate': '2025-04-18 09:30:00.000',
  'endDate': '2025-04-18 09:30:00.000',
  'timeRemaining': '3 days, 2 hrs, 1 mins',
  'questImageUrl': 'assets/images/app_assets/todo.png',
};

/// Hero JSON exactly as the mutable-era app wrote it.
Map<String, dynamic> _legacyHeroJson() => {
  'name': 'Old Hero',
  'motto': 'Onwards',
  'classes': {
    'className': 'Fighter',
    'classImageUrl': 'assets/images/class_images/fighter.png',
    'description': 'A versatile fighter',
    'strength': 7,
    'dexterity': 7,
    'intelligence': 2,
    'wisdom': 2,
    'charisma': 4,
    'constitution': 4,
    'luck': 1,
    'level': 1,
    'experience': 0,
    'health': 100,
    'mana': 20,
    'stamina': 50,
  },
  'description': 'A brave hero',
  'imageUrl': 'assets/images/character_images/hero_3.png',
  'levelUp': {'level': 3, 'exp': 45, 'maxExp': 300, 'statPoints': 4},
  'strength': 9,
  'dexterity': 7,
  'intelligence': 2,
  'wisdom': 2,
  'charisma': 4,
  'constitution': 4,
  'luck': 1,
  'health': 115,
  'mana': 65,
  'stamina': 99,
  'background': null,
  'biography': '',
  'learnedSkills': [],
  'unlockedAchievements': [],
  'createdDate': '2025-04-01T10:00:00.000',
  'questsCompleted': 4,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quest.fromJson (legacy format)', () {
    test('loads string status, string dates and derives difficulty', () {
      final quest = Quest.fromJson(_legacyQuestJson());

      expect(quest.id, 7);
      expect(quest.title, 'Old quest');
      expect(quest.status, QuestStatus.completed);
      expect(quest.isCompleted, isTrue);
      expect(quest.difficulty, 3); // 150 XP / 50
      expect(quest.xpReward, 150);
      expect(quest.dueDate, DateTime(2025, 4, 18, 9, 30));
      expect(quest.questImageUrl, 'assets/images/app_assets/todo.png');
    });

    test('falls back safely on garbage legacy values', () {
      final before = DateTime.now();
      final quest = Quest.fromJson({
        'id': 2,
        'title': 'Broken',
        'description': 'x',
        'status': 'Unknown status',
        'xpReward': 0,
        'startDate': 'Date not set',
        'endDate': 'Date not set',
        'timeRemaining': '? days',
      });

      expect(quest.status, QuestStatus.inProgress);
      expect(quest.difficulty, minDifficulty);
      expect(quest.dueDate.isBefore(before), isFalse);
      expect(quest.questImageUrl, defaultQuestImage);
    });

    test('prefers the new dueDate/difficulty keys when present', () {
      final json =
          _legacyQuestJson()
            ..['dueDate'] = '2031-01-02T03:04:00.000'
            ..['difficulty'] = 5;

      final quest = Quest.fromJson(json);

      expect(quest.dueDate, DateTime(2031, 1, 2, 3, 4));
      expect(quest.difficulty, 5);
      expect(quest.xpReward, 250);
    });

    test('round-trips through the new toJson', () {
      final quest = Quest.fromJson(_legacyQuestJson());
      final again = Quest.fromJson(jsonDecode(jsonEncode(quest.toJson())));
      expect(again, quest);
    });

    test('legacy quests JSON in SharedPreferences loads', () async {
      SharedPreferences.setMockInitialValues({
        'quests': jsonEncode([_legacyQuestJson()]),
      });

      final loaded = await SharedPrefsQuestStorage().loadQuests();

      expect(loaded.length, 1);
      expect(loaded.single.title, 'Old quest');
    });
  });

  group('HeroCharacter.fromJson (mutable-era format)', () {
    test('loads the levelUp map and all stats', () {
      final hero = HeroCharacter.fromJson(_legacyHeroJson());

      expect(hero.name, 'Old Hero');
      expect(hero.levelUp.level, 3);
      expect(hero.levelUp.exp, 45);
      expect(hero.levelUp.maxExp, 300);
      expect(hero.levelUp.statPoints, 4);
      expect(hero.strength, 9);
      expect(hero.health, 115);
      expect(hero.questsCompleted, 4);
      expect(hero.classes.className, 'Fighter');
      expect(hero.createdDate, DateTime(2025, 4, 1, 10));
    });

    test('legacy hero JSON in SharedPreferences loads', () async {
      SharedPreferences.setMockInitialValues({
        'hero': jsonEncode(_legacyHeroJson()),
      });

      final hero = await SharedPrefsQuestStorage().loadHero();

      expect(hero, isNotNull);
      expect(hero!.levelUp.level, 3);
    });

    test('round-trips through the new toJson', () {
      final hero = HeroCharacter.fromJson(_legacyHeroJson());
      final again = HeroCharacter.fromJson(
        jsonDecode(jsonEncode(hero.toJson())),
      );
      expect(again.levelUp, hero.levelUp);
      expect(again.strength, hero.strength);
      expect(again.questsCompleted, hero.questsCompleted);
    });
  });
}

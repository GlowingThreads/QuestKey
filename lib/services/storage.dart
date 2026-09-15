// Persistence for quests and the hero.
import 'dart:convert';

import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage contract for quests and the hero.
///
/// The app uses [SharedPrefsQuestStorage]; tests can inject an in-memory
/// implementation (see `InMemoryQuestStorage`).
abstract class QuestStorage {
  Future<void> saveQuests(List<Quest> quests);
  Future<List<Quest>> loadQuests();
  Future<void> deleteQuest(Quest quest);
  Future<void> saveHero(HeroCharacter hero);
  Future<HeroCharacter?> loadHero();

  /// Today's encounter state as a JSON map (`null` when none is stored).
  Future<Map<String, dynamic>?> loadEncounter();
  Future<void> saveEncounter(Map<String, dynamic>? json);
  Future<void> clearAllData();
}

/// [QuestStorage] backed by `shared_preferences`.
class SharedPrefsQuestStorage implements QuestStorage {
  static const String questsKey = 'quests';
  static const String heroKey = 'hero';
  static const String heroExistsKey = 'heroExists';
  static const String encounterKey = 'encounter';

  @override
  Future<void> saveQuests(List<Quest> quests) async {
    final prefs = await SharedPreferences.getInstance();
    final questListJson = jsonEncode(
      quests.map((quest) => quest.toJson()).toList(),
    );
    await prefs.setString(questsKey, questListJson);
  }

  @override
  Future<List<Quest>> loadQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(questsKey);
    if (jsonString == null) return [];

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((quest) => Quest.fromJson(Map<String, dynamic>.from(quest)))
          .toList();
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> deleteQuest(Quest quest) async {
    final currentQuests = await loadQuests();
    currentQuests.removeWhere((q) => q.id == quest.id);
    await saveQuests(currentQuests);
  }

  @override
  Future<void> saveHero(HeroCharacter hero) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(heroKey, jsonEncode(hero.toJson()));
    await prefs.setBool(heroExistsKey, true);
  }

  @override
  Future<HeroCharacter?> loadHero() async {
    final prefs = await SharedPreferences.getInstance();
    final heroString = prefs.getString(heroKey);
    if (heroString == null) return null;

    try {
      final json = jsonDecode(heroString);
      if (json is! Map) return null;
      return HeroCharacter.fromJson(Map<String, dynamic>.from(json));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> loadEncounter() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(encounterKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveEncounter(Map<String, dynamic>? json) async {
    final prefs = await SharedPreferences.getInstance();
    if (json == null) {
      await prefs.remove(encounterKey);
    } else {
      await prefs.setString(encounterKey, jsonEncode(json));
    }
  }

  @override
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(heroKey);
    await prefs.remove(questsKey);
    await prefs.remove(encounterKey);
    await prefs.setBool(heroExistsKey, false);
  }
}

/// Static-style facade over [StorageService.instance].
///
/// Existing call sites keep working unchanged; tests can swap the backing
/// implementation with `StorageService.instance = InMemoryQuestStorage()`.
class StorageService {
  StorageService._();

  /// The storage implementation used by the static helpers below and, by
  /// default, by the providers.
  static QuestStorage instance = SharedPrefsQuestStorage();

  static Future<void> saveQuests(List<Quest> quests) =>
      instance.saveQuests(quests);

  static Future<List<Quest>> loadQuests() => instance.loadQuests();

  static Future<void> deleteQuest(Quest quest) => instance.deleteQuest(quest);

  static Future<void> saveHero(HeroCharacter hero) => instance.saveHero(hero);

  static Future<HeroCharacter?> loadHero() => instance.loadHero();

  static Future<void> clearAllData() => instance.clearAllData();
}

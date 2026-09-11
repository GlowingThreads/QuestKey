import 'dart:convert';

import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/storage.dart';

/// [QuestStorage] that keeps everything in memory.
///
/// Data goes through a JSON round trip on save/load so tests exercise the
/// same serialisation path as the real implementation.
class InMemoryQuestStorage implements QuestStorage {
  String? _questsJson;
  String? _heroJson;

  /// Number of times [saveQuests] has been called (useful in tests).
  int questSaveCount = 0;

  /// Number of times [saveHero] has been called (useful in tests).
  int heroSaveCount = 0;

  @override
  Future<void> saveQuests(List<Quest> quests) async {
    questSaveCount++;
    _questsJson = jsonEncode(quests.map((q) => q.toJson()).toList());
  }

  @override
  Future<List<Quest>> loadQuests() async {
    final json = _questsJson;
    if (json == null) return [];
    return (jsonDecode(json) as List)
        .map((q) => Quest.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();
  }

  @override
  Future<void> deleteQuest(Quest quest) async {
    final quests = await loadQuests();
    quests.removeWhere((q) => q.id == quest.id);
    await saveQuests(quests);
  }

  @override
  Future<void> saveHero(HeroCharacter hero) async {
    heroSaveCount++;
    _heroJson = jsonEncode(hero.toJson());
  }

  @override
  Future<HeroCharacter?> loadHero() async {
    final json = _heroJson;
    if (json == null) return null;
    return HeroCharacter.fromJson(
      Map<String, dynamic>.from(jsonDecode(json) as Map),
    );
  }

  @override
  Future<void> clearAllData() async {
    _questsJson = null;
    _heroJson = null;
  }
}

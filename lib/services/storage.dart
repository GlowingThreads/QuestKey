//this is storage.dart
//quest and hero servs
import 'package:flutter/material.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/character.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuestListProvider with ChangeNotifier {
  final List<Quest> _quests = [];
  Quest? selectedQuest;
  List<Quest> get quests => _quests;

  //nullable for reset
  void setSelectedQuest(Quest? quest) {
    selectedQuest = quest;
    notifyListeners();
  }

  void addQuest(Quest quest) {
    _quests.add(quest);
    saveQuestsToStorage();
    notifyListeners();
  }

  void removeQuest(Quest quest) {
    _quests.remove(quest);
    saveQuestsToStorage();
    notifyListeners();
  }

  void updateQuest(Quest quest) {
    final index = _quests.indexWhere((quest) => quest.id == quest.id);
    if (index != -1) {
      _quests[index] = quest;
      saveQuestsToStorage();
      notifyListeners();
    }
  }

  void updateQuestStatus(int questId, String status) {
    final index = _quests.indexWhere((quest) => quest.id == questId);
    if (index != -1) {
      _quests[index] = _quests[index].copyWith(status: status);
      saveQuestsToStorage();
      notifyListeners();
    }
  }

  void markQuestCompleted(Quest quest) {
    final index = _quests.indexWhere((q) => q.id == quest.id);
    if (index != -1) {
      _quests[index] = quest.copyWith(status: 'Completed');
      saveQuestsToStorage();
      notifyListeners();
    }
  }

  List<Quest> getFilteredQuests(String? filterStatus) {
    if (filterStatus == null || filterStatus == 'All') {
      return _quests;
    }
    return _quests.where((quest) => quest.status == filterStatus).toList();
  }

  Future<void> loadQuestsFromStorage() async {
    final loadedQuests = await StorageService.loadQuests();
    _quests.clear();
    _quests.addAll(loadedQuests);
    notifyListeners();
  }

  Future<void> saveQuestsToStorage() async {
    await StorageService.saveQuests(_quests);
  }
}

class StorageService {
  static Future<void> saveQuests(List<Quest> quests) async {
    final prefs = await SharedPreferences.getInstance();
    final questListJson = jsonEncode(
      quests.map((quest) => quest.toJson()).toList(),
    );
    await prefs.setString('quests', questListJson);
  }

  static Future<List<Quest>> loadQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('quests');

    if (jsonString == null) return [];

    final decoded = jsonDecode(jsonString) as List;
    return decoded.map((quest) => Quest.fromJson(quest)).toList();
  }

  static Future<void> deleteQuest(Quest quest) async {
    final currentQuests = await loadQuests();
    currentQuests.removeWhere((quest) => quest.id == quest.id);
    await saveQuests(currentQuests);
  }

  static Future<void> saveHero(HeroCharacter hero) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hero', jsonEncode(hero.toJson()));
  }

  static Future<HeroCharacter?> loadHero() async {
    final prefs = await SharedPreferences.getInstance();
    final heroString = prefs.getString('hero');

    if (heroString == null) return null;

    final json = jsonDecode(heroString);
    return HeroCharacter.fromJson(json);
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hero');
    await prefs.remove('quests');
    await prefs.setBool('heroExists', false);
  }
}

// this is app state
import 'package:quest_key/models/character.dart';
import 'package:quest_key/services/storage.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  HeroCharacter? hero;
  int currentQuestIndex;
  int currentQuestId;
  int currentQuestStatus;
  int currentQuestXpReward;
  String currentQuestTitle;
  String currentQuestDescription;
  String currentQuestStartDate;
  String currentQuestEndDate;
  String currentQuestTimeRemaining;

  AppState({
    this.hero,
    this.currentQuestIndex = 0,
    this.currentQuestId = 0,
    this.currentQuestStatus = 0,
    this.currentQuestXpReward = 0,
    this.currentQuestTitle = '',
    this.currentQuestDescription = '',
    this.currentQuestStartDate = '',
    this.currentQuestEndDate = '',
    this.currentQuestTimeRemaining = '',
  });

  AppState copyWith({
    HeroCharacter? hero,
    int? currentQuestIndex,
    int? currentQuestId,
    int? currentQuestStatus,
    int? currentQuestXpReward,
    String? currentQuestTitle,
    String? currentQuestDescription,
    String? currentQuestStartDate,
    String? currentQuestEndDate,
    String? currentQuestTimeRemaining,
  }) {
    return AppState(
      hero: hero ?? this.hero,
      currentQuestIndex: currentQuestIndex ?? this.currentQuestIndex,
      currentQuestId: currentQuestId ?? this.currentQuestId,
      currentQuestStatus: currentQuestStatus ?? this.currentQuestStatus,
      currentQuestXpReward: currentQuestXpReward ?? this.currentQuestXpReward,
      currentQuestTitle: currentQuestTitle ?? this.currentQuestTitle,
      currentQuestDescription:
          currentQuestDescription ?? this.currentQuestDescription,
      currentQuestStartDate:
          currentQuestStartDate ?? this.currentQuestStartDate,
      currentQuestEndDate: currentQuestEndDate ?? this.currentQuestEndDate,
      currentQuestTimeRemaining:
          currentQuestTimeRemaining ?? this.currentQuestTimeRemaining,
    );
  }

  @override
  String toString() {
    return 'AppState(hero: $hero, currentQuestIndex: $currentQuestIndex, currentQuestId: $currentQuestId, currentQuestStatus: $currentQuestStatus, currentQuestXpReward: $currentQuestXpReward, currentQuestTitle: $currentQuestTitle, currentQuestDescription: $currentQuestDescription, currentQuestStartDate: $currentQuestStartDate, currentQuestEndDate: $currentQuestEndDate, currentQuestTimeRemaining: $currentQuestTimeRemaining)';
  }

  void completeQuest() {
    if (hero != null) {
      hero!.gainExperience(currentQuestXpReward);
    }
  }

  int currentIndex = 0;

  void setIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  Future<void> loadHeroFromStorage() async {
    final loadedHero = await StorageService.loadHero();
    if (loadedHero != null) {
      hero = loadedHero;
    }
  }

  void saveHero(HeroCharacter newHero) {
    hero = newHero;
    StorageService.saveHero(newHero);
    notifyListeners();
  }
}

class LevelUp {
  int level;
  int exp;
  int maxExp;
  int statPoints;

  LevelUp({
    required this.level,
    required this.exp,
    required this.maxExp,
    required this.statPoints,
  });

  @override
  String toString() {
    return 'LevelUp(level: $level, exp: $exp, maxExp: $maxExp, statPoints: $statPoints)';
  }

  // method to level up user
  void levelUp() {
    level++;
    exp = 0;
    maxExp += 100;
    statPoints += 3;
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'exp': exp,
      'maxExp': maxExp,
      'statPoints': statPoints,
    };
  }

  factory LevelUp.fromJson(Map<String, dynamic> json) {
    return LevelUp(
      level: json['level'] ?? 1,
      exp: json['exp'] ?? 0,
      maxExp: json['maxExp'] ?? 100,
      statPoints: json['statPoints'] ?? 0,
    );
  }
}

class StatsPerLevel {
  final int level;
  final int exp;
  final int hp;
  final int mp;
  final int pointsToAssign;

  StatsPerLevel({
    required this.level,
    required this.exp,
    required this.hp,
    required this.mp,
    required this.pointsToAssign,
  });

  factory StatsPerLevel.fromJson(Map<String, dynamic> json) {
    return StatsPerLevel(
      level: json['level'],
      exp: json['exp'],
      hp: json['hp'],
      mp: json['mp'],
      pointsToAssign: json['pointsToAssign'],
    );
  }

  StatsPerLevel copyWith({
    int? level,
    int? exp,
    int? hp,
    int? mp,
    int? pointsToAssign,
  }) {
    return StatsPerLevel(
      level: level ?? this.level,
      exp: exp ?? this.exp,
      hp: hp ?? this.hp,
      mp: mp ?? this.mp,
      pointsToAssign: pointsToAssign ?? this.pointsToAssign,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'exp': exp,
      'hp': hp,
      'mp': mp,
      'pointsToAssign': pointsToAssign,
    };
  }

  @override
  String toString() {
    return 'StatsPerLevel(level: $level, exp: $exp, hp: $hp, mp: $mp, pointsToAssign: $pointsToAssign)';
  }

  StatsPerLevel levelUp() {
    return StatsPerLevel(
      level: level + 1,
      exp: exp + 100,
      hp: hp + 10,
      mp: mp + 5,
      pointsToAssign: pointsToAssign + 1,
    );
  }

  Map<String, dynamic> getStats() {
    return {
      'level': level,
      'exp': exp,
      'hp': hp,
      'mp': mp,
      'pointsToAssign': pointsToAssign,
    };
  }
}

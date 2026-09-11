// App-wide state: the hero and the selected navigation tab.
import 'package:flutter/foundation.dart';
import 'package:quest_key/models/achievement_rules.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/storage.dart';

/// What happened when a quest was completed.
class QuestCompletionResult {
  const QuestCompletionResult({
    required this.xpGained,
    required this.leveledUp,
    required this.unlockedAchievements,
  });

  static const QuestCompletionResult none = QuestCompletionResult(
    xpGained: 0,
    leveledUp: false,
    unlockedAchievements: [],
  );

  final int xpGained;
  final bool leveledUp;
  final List<CharacterAchievement> unlockedAchievements;
}

class AppState extends ChangeNotifier {
  AppState({this.hero, QuestStorage? storage, DateTime Function()? now})
    : _storage = storage,
      _now = now ?? DateTime.now;

  final QuestStorage? _storage;
  final DateTime Function() _now;

  /// Storage used for persistence; defaults to [StorageService.instance].
  QuestStorage get storage => _storage ?? StorageService.instance;

  HeroCharacter? hero;

  /// Index of the selected bottom-navigation tab.
  int currentIndex = 0;

  /// Whether the most recent [completeQuestForHero] call levelled the hero up.
  bool lastCompletionLeveledUp = false;

  bool get hasHero => hero != null;

  void setIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  Future<void> loadHeroFromStorage() async {
    final loadedHero = await storage.loadHero();
    if (loadedHero != null) {
      hero = loadedHero;
      notifyListeners();
    }
  }

  /// Replaces the hero, notifies listeners and persists it.
  Future<void> saveHero(HeroCharacter newHero) async {
    hero = newHero;
    notifyListeners();
    await storage.saveHero(newHero);
  }

  /// Awards [xp] to the hero for a completed quest, records the completion
  /// (quest count + daily streak), unlocks any earned achievements, saves,
  /// notifies and reports what happened.
  ///
  /// [completedToday] is how many quests (including this one) were completed
  /// today; it drives the Speedrunner achievement. [quest] is the quest that
  /// was completed, when known.
  Future<QuestCompletionResult> completeQuestForHero(
    int xp, {
    int completedToday = 1,
    Quest? quest,
  }) async {
    final current = hero;
    if (current == null) {
      lastCompletionLeveledUp = false;
      return QuestCompletionResult.none;
    }

    final now = _now();
    final gained = current.gainExperience(xp);
    var updated = gained.hero.recordQuestCompletion(now);
    final unlocked = evaluateAchievements(
      updated,
      now: now,
      completedToday: completedToday,
      justCompleted: quest,
    );
    updated = updated.unlockAchievements(unlocked);

    lastCompletionLeveledUp = gained.leveledUp;
    await saveHero(updated);
    return QuestCompletionResult(
      xpGained: xp,
      leveledUp: gained.leveledUp,
      unlockedAchievements: unlocked,
    );
  }

  /// Spends [points] stat points on [stat], unlocks any stat achievements,
  /// saves and returns the newly unlocked achievements.
  Future<List<CharacterAchievement>> assignStatPoint(
    String stat, {
    int points = 1,
  }) async {
    final current = hero;
    if (current == null) return const [];

    var updated = current.assignStatPoints(stat, points);
    final unlocked = evaluateAchievements(updated, now: _now());
    updated = updated.unlockAchievements(unlocked);
    await saveHero(updated);
    return unlocked;
  }

  /// Learns [skill] if the hero meets its requirements. Returns whether it
  /// was learned.
  Future<bool> learnSkill(CharacterSkill skill) async {
    final updated = hero?.learnSkill(skill);
    if (updated == null) return false;
    await saveHero(updated);
    return true;
  }

  /// Forgets the hero in memory (storage is cleared separately).
  void clearHero() {
    hero = null;
    lastCompletionLeveledUp = false;
    notifyListeners();
  }
}

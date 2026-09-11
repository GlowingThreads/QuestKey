// App-wide state: the hero and the selected navigation tab.
import 'package:flutter/foundation.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/services/storage.dart';

class AppState extends ChangeNotifier {
  AppState({this.hero, QuestStorage? storage}) : _storage = storage;

  final QuestStorage? _storage;

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

  /// Awards [xp] to the hero for a completed quest, saves, notifies and
  /// returns whether the hero levelled up (also exposed as
  /// [lastCompletionLeveledUp]).
  Future<bool> completeQuestForHero(int xp) async {
    final current = hero;
    if (current == null) {
      lastCompletionLeveledUp = false;
      return false;
    }

    final result = current.gainExperience(xp);
    lastCompletionLeveledUp = result.leveledUp;
    await saveHero(
      result.hero.copyWith(questsCompleted: result.hero.questsCompleted + 1),
    );
    return result.leveledUp;
  }

  /// Forgets the hero in memory (storage is cleared separately).
  void clearHero() {
    hero = null;
    lastCompletionLeveledUp = false;
    notifyListeners();
  }
}

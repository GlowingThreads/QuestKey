// App-wide state: the hero and the selected navigation tab.
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:quest_key/models/achievement_rules.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/models/familiar.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/rewards.dart';
import 'package:quest_key/services/storage.dart';

/// What happened when a quest was completed.
class QuestCompletionResult {
  const QuestCompletionResult({
    required this.xpGained,
    required this.leveledUp,
    required this.unlockedAchievements,
    this.breakdown,
  });

  static const QuestCompletionResult none = QuestCompletionResult(
    xpGained: 0,
    leveledUp: false,
    unlockedAchievements: [],
  );

  final int xpGained;
  final bool leveledUp;
  final List<CharacterAchievement> unlockedAchievements;

  /// How the XP was computed (null when a flat amount was awarded).
  final RewardBreakdown? breakdown;

  bool get critical => breakdown?.critical ?? false;
}

class AppState extends ChangeNotifier {
  AppState({
    this.hero,
    QuestStorage? storage,
    DateTime Function()? now,
    double Function()? roll,
  }) : _storage = storage,
       _now = now ?? DateTime.now,
       _roll = roll ?? Random().nextDouble;

  final QuestStorage? _storage;
  final DateTime Function() _now;

  /// Returns a number in [0, 1); used for critical completions and
  /// encounter outcomes. Inject for deterministic tests.
  final double Function() _roll;

  /// Storage used for persistence; defaults to [StorageService.instance].
  QuestStorage get storage => _storage ?? StorageService.instance;

  DateTime now() => _now();
  double roll() => _roll();

  HeroCharacter? hero;

  /// Index of the selected bottom-navigation tab.
  int currentIndex = 0;

  /// Whether the most recent [completeQuestForHero] call levelled the hero up.
  bool lastCompletionLeveledUp = false;

  /// Report from the most recent [processNewDay], for the Home tab to show.
  RestReport? lastRest;

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

  /// Applies [update] to the hero, unlocks any newly earned honours, saves,
  /// and returns what was unlocked.
  Future<List<CharacterAchievement>> updateHero(
    HeroCharacter Function(HeroCharacter hero) update, {
    Quest? justCompleted,
    int completedToday = 0,
    bool survivedMissedDay = false,
    bool flameWentOut = false,
  }) async {
    final current = hero;
    if (current == null) return const [];
    var updated = update(current);
    final unlocked = evaluateAchievements(
      updated,
      now: _now(),
      completedToday: completedToday,
      justCompleted: justCompleted,
      survivedMissedDay: survivedMissedDay,
      flameWentOut: flameWentOut,
    );
    updated = updated.unlockAchievements(unlocked);
    await saveHero(updated);
    return unlocked;
  }

  /// Runs the daily rest (resource refill, torch damage) if a new day has
  /// begun since the last one. Safe to call often.
  Future<RestReport?> processNewDay() async {
    final current = hero;
    if (current == null) return null;
    final report = current.rest(_now());
    if (report.nothingHappened && report.hero == current) {
      // First run for a legacy hero still needs its clock started.
      if (current.lastRestedOn != null) return null;
    }
    final survived = report.missedDays > 0 && !report.flameWentOut;
    await updateHero(
      (_) => report.hero,
      survivedMissedDay: survived,
      flameWentOut: report.flameWentOut,
    );
    lastRest = report.daysPassed > 0 ? report : null;
    notifyListeners();
    return report;
  }

  /// Awards XP for a completed quest, records the completion (quest count,
  /// streak, regen), unlocks earned honours, saves, and reports what
  /// happened.
  ///
  /// When [quest] is given the reward is computed from difficulty,
  /// attribute affinity, active buffs, encounter bonus and a Luck roll;
  /// otherwise the flat [xp] is used.
  Future<QuestCompletionResult> completeQuestForHero(
    int xp, {
    int completedToday = 1,
    Quest? quest,
    int extraPercent = 0,
    String? extraLabel,
  }) async {
    final current = hero;
    if (current == null) {
      lastCompletionLeveledUp = false;
      return QuestCompletionResult.none;
    }

    final now = _now();
    RewardBreakdown? breakdown;
    var gainedXp = xp;
    var working = current;
    if (quest != null) {
      breakdown = computeReward(
        working,
        quest,
        now: now,
        roll: _roll(),
        extraPercent: extraPercent,
        extraLabel: extraLabel,
      );
      gainedXp = breakdown.total;
      for (final buff in breakdown.consumedBuffs) {
        working = working.consumeBuff(buff);
      }
      if (breakdown.critical) {
        working = working.copyWith(criticalHits: working.criticalHits + 1);
      }
      if (quest.isBoss) {
        working = working.copyWith(bossesSlain: working.bossesSlain + 1);
      }
    }

    final gained = working.gainExperience(gainedXp);
    var updated = gained.hero.recordQuestCompletion(now, quest: quest);
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
      xpGained: gainedXp,
      leveledUp: gained.leveledUp,
      unlockedAchievements: unlocked,
      breakdown: breakdown,
    );
  }

  /// Awards a flat amount of XP without counting a quest (spell and
  /// encounter rewards). Returns whether the hero levelled up.
  Future<bool> awardXp(int xp) async {
    final current = hero;
    if (current == null || xp <= 0) return false;
    final gained = current.gainExperience(xp);
    await updateHero((_) => gained.hero);
    lastCompletionLeveledUp = gained.leveledUp;
    return gained.leveledUp;
  }

  /// Spends [points] stat points on [stat], unlocks any stat achievements,
  /// saves and returns the newly unlocked achievements.
  Future<List<CharacterAchievement>> assignStatPoint(
    String stat, {
    int points = 1,
  }) => updateHero((h) => h.assignStatPoints(stat, points));

  /// Learns [skill] if the hero meets its requirements. Returns the honours
  /// unlocked by learning it, or `null` when it could not be learned.
  Future<List<CharacterAchievement>?> learnSkill(CharacterSkill skill) async {
    final updated = hero?.learnSkill(skill);
    if (updated == null) return null;
    return updateHero((_) => updated);
  }

  /// Wears the honour [achievementId] as a title (must be unlocked), or
  /// removes the title when `null`. Returns any honours unlocked by doing so.
  Future<List<CharacterAchievement>> setTitle(String? achievementId) async {
    final current = hero;
    if (current == null) return const [];
    if (achievementId != null && !current.hasAchievement(achievementId)) {
      return const [];
    }
    return updateHero(
      (h) =>
          achievementId == null
              ? h.copyWith(clearTitle: true)
              : h.copyWith(titleAchievementId: achievementId),
    );
  }

  /// Adopts a familiar (replacing any existing one) and returns the honours
  /// unlocked by doing so.
  Future<List<CharacterAchievement>> adoptFamiliar(
    FamiliarSpecies species,
    String name,
  ) {
    final trimmed = name.trim();
    return updateHero(
      (h) => h.copyWith(
        familiar: Familiar(
          species: species,
          name: trimmed.isEmpty ? species.label : trimmed,
          adoptedOn: _now(),
        ),
      ),
    );
  }

  /// Pets the familiar: bumps its count and returns its reply, or `null`
  /// when there is no familiar.
  Future<String?> petFamiliar() async {
    final f = hero?.familiar;
    if (f == null) return null;
    await updateHero(
      (h) => h.copyWith(familiar: f.copyWith(timesPetted: f.timesPetted + 1)),
    );
    return familiarPettedLine(f);
  }

  void dismissRestReport() {
    lastRest = null;
    notifyListeners();
  }

  /// Forgets the hero in memory (storage is cleared separately).
  void clearHero() {
    hero = null;
    lastCompletionLeveledUp = false;
    lastRest = null;
    notifyListeners();
  }
}

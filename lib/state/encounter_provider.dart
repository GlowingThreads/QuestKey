import 'package:flutter/foundation.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/encounter.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/spells.dart';
import 'package:quest_key/services/storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';

/// How an encounter was resolved.
class EncounterOutcome {
  const EncounterOutcome({
    required this.message,
    this.xpGained = 0,
    this.leveledUp = false,
    this.unlocked = const [],
    this.success = true,
  });

  final String message;
  final int xpGained;
  final bool leveledUp;
  final List<CharacterAchievement> unlocked;
  final bool success;
}

/// Owns today's encounter: rolls it, persists it and resolves the player's
/// choice.
class EncounterProvider extends ChangeNotifier {
  EncounterProvider({
    required this.appState,
    required this.quests,
    QuestStorage? storage,
  }) : _storage = storage;

  final AppState appState;
  final QuestListProvider quests;
  final QuestStorage? _storage;

  QuestStorage get storage => _storage ?? StorageService.instance;

  Encounter? _encounter;

  Encounter? get encounter => _encounter;

  /// The encounter to show on Home, if one is open today.
  Encounter? get open =>
      _encounter != null && _encounter!.isOpen ? _encounter : null;

  /// Loads the stored encounter and rolls a new one if the day changed.
  Future<void> refresh() async {
    final hero = appState.hero;
    final today = _today();
    _encounter ??= _fromStorage(await storage.loadEncounter());
    if (hero == null) {
      _encounter = null;
      notifyListeners();
      return;
    }
    if (_encounter == null || !_sameDay(_encounter!.day, today)) {
      _encounter = rollEncounter(today, hero);
      await storage.saveEncounter(_encounter?.toJson());
    }
    notifyListeners();
  }

  static Encounter? _fromStorage(Map<String, dynamic>? json) =>
      json == null ? null : Encounter.fromJson(json);

  DateTime _today() {
    final n = appState.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _store(Encounter updated) async {
    _encounter = updated;
    await storage.saveEncounter(updated.toJson());
    notifyListeners();
  }

  /// Accept: a bonus quest is added to the log.
  Future<EncounterOutcome> accept() async {
    final e = open;
    if (e == null) {
      return const EncounterOutcome(
        message: 'Nothing to accept.',
        success: false,
      );
    }
    final t = e.template;
    final quest = Quest(
      id: quests.nextQuestId(),
      title: t.questTitle,
      description: t.questDescription,
      category: t.category,
      difficulty: t.difficulty,
      dueDate: appState.now().add(Duration(hours: t.hoursToComplete)),
      xpBonusPercent: t.bonusPercent,
    );
    await quests.saveQuest(quest);
    await _store(
      e.copyWith(status: EncounterStatus.accepted, questId: quest.id),
    );
    return EncounterOutcome(
      message:
          'Accepted. "${quest.title}" is in your log with +${t.bonusPercent}% XP.',
    );
  }

  /// Decline: nothing ventured.
  Future<EncounterOutcome> decline() async {
    final e = open;
    if (e == null) {
      return const EncounterOutcome(
        message: 'Nothing to decline.',
        success: false,
      );
    }
    await _store(
      e.copyWith(status: EncounterStatus.declined, outcome: 'You walked on.'),
    );
    return const EncounterOutcome(message: 'You walk on. The road is long.');
  }

  /// Stealth: slip past for a small reward (costs stamina).
  Future<EncounterOutcome> slipPast() async {
    final e = open;
    final hero = appState.hero;
    if (e == null || hero == null) {
      return const EncounterOutcome(
        message: 'Nothing to slip past.',
        success: false,
      );
    }
    final spell = Spell.forSkill('stealth')!;
    final cost = spell.costFor(hero.learnedSkill('stealth'));
    if (!hero.hasSkill('stealth') ||
        !hero.canAfford(SpellResource.stamina, cost)) {
      return EncounterOutcome(
        message: 'You need Stealth and $cost STA.',
        success: false,
      );
    }
    const xp = 25;
    final paid = await appState.updateHero(
      (h) => h.spend(SpellResource.stamina, cost).useSkill('stealth'),
    );
    final leveled = await appState.awardXp(xp);
    final unlocked = [
      ...paid,
      ...await appState.updateHero(
        (h) => h.copyWith(encountersResolved: h.encountersResolved + 1),
      ),
    ];
    await _store(
      e.copyWith(
        status: EncounterStatus.resolved,
        outcome: 'Slipped past unseen.',
      ),
    );
    return EncounterOutcome(
      message: 'You slip past unseen and pocket $xp XP.',
      xpGained: xp,
      leveledUp: leveled,
      unlocked: unlocked,
    );
  }

  /// Fireball: confront it. Luck decides; failure burns the torch.
  Future<EncounterOutcome> confront() async {
    final e = open;
    final hero = appState.hero;
    if (e == null || hero == null) {
      return const EncounterOutcome(
        message: 'Nothing to confront.',
        success: false,
      );
    }
    final spell = Spell.forSkill('fireball')!;
    final cost = spell.costFor(hero.learnedSkill('fireball'));
    if (!hero.hasSkill('fireball') ||
        !hero.canAfford(SpellResource.mana, cost)) {
      return EncounterOutcome(
        message: 'You need Fireball and $cost MP.',
        success: false,
      );
    }
    final paid = await appState.updateHero(
      (h) => h.spend(SpellResource.mana, cost).useSkill('fireball'),
    );

    final chance = (0.5 + hero.luck * 0.05).clamp(0.0, 0.9);
    final won = appState.roll() < chance;
    if (won) {
      const xp = 120;
      final leveled = await appState.awardXp(xp);
      final unlocked = [
        ...paid,
        ...await appState.updateHero(
          (h) => h.copyWith(encountersResolved: h.encountersResolved + 1),
        ),
      ];
      await _store(
        e.copyWith(status: EncounterStatus.resolved, outcome: 'Victory.'),
      );
      return EncounterOutcome(
        message: 'Fire and fury. The way is clear and you claim $xp XP.',
        xpGained: xp,
        leveledUp: leveled,
        unlocked: unlocked,
      );
    }

    final dmg = (hero.maxHealth * 0.2).round();
    final unlocked = [
      ...paid,
      ...await appState.updateHero(
        (h) => h
            .damage(dmg)
            .copyWith(encountersResolved: h.encountersResolved + 1),
      ),
    ];
    await _store(
      e.copyWith(status: EncounterStatus.resolved, outcome: 'Driven back.'),
    );
    return EncounterOutcome(
      message:
          'The blast goes wide. You are driven back and your torch loses $dmg HP.',
      success: false,
      unlocked: unlocked,
    );
  }

  /// Forgets everything (used when the hero is erased).
  Future<void> clear() async {
    _encounter = null;
    await storage.saveEncounter(null);
    notifyListeners();
  }
}

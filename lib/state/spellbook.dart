import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/rewards.dart';
import 'package:quest_key/models/spells.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';

/// Result of casting a spell.
class SpellResult {
  const SpellResult({
    required this.success,
    required this.message,
    this.xpGained = 0,
    this.leveledUp = false,
    this.unlocked = const [],
  });

  final bool success;
  final String message;
  final int xpGained;
  final bool leveledUp;
  final List<CharacterAchievement> unlocked;
}

/// Executes spells against the hero and the quest list.
///
/// Construct it from the two providers; it holds no state of its own.
class Spellbook {
  Spellbook({required this.appState, required this.quests});

  final AppState appState;
  final QuestListProvider quests;

  HeroCharacter? get hero => appState.hero;

  /// Spells the hero has learned.
  List<Spell> get known {
    final h = hero;
    if (h == null) return const [];
    return [
      for (final learned in h.learnedSkills)
        if (Spell.forSkill(learned.skill.id) case final spell?) spell,
    ];
  }

  /// Known spells that could be cast on [target] (or on the hero itself when
  /// [target] is null).
  List<Spell> castableOn(Quest? target) =>
      known
          .where(
            (s) =>
                target == null
                    ? !s.targetsQuest && s.target != SpellTarget.trivialQuests
                    : s.targetsQuest,
          )
          .toList();

  int costOf(Spell spell) => spell.costFor(hero?.learnedSkill(spell.skillId));

  /// Why [spell] cannot be cast right now, or `null` when it can.
  String? blockedReason(Spell spell, {Quest? target}) {
    final h = hero;
    if (h == null) return 'No hero.';
    if (!h.hasSkill(spell.skillId)) return 'Not learned yet.';
    final cost = costOf(spell);
    if (!h.canAfford(spell.resource, cost)) {
      return 'Needs $cost ${spell.resource.label}; you have ${h.poolOf(spell.resource)}.';
    }
    final now = appState.now();
    switch (spell.target) {
      case SpellTarget.self:
        if (spell.skillId == 'power_strike' &&
            h.hasBuff(BuffType.empowered, now)) {
          return 'Already empowered.';
        }
        if (spell.skillId == 'swift_strike' && h.hasBuff(BuffType.haste, now)) {
          return 'Haste is already active.';
        }
        if ((spell.skillId == 'shield_bash' ||
                spell.skillId == 'mana_shield') &&
            h.shieldCharges >= Spell.maxShieldCharges) {
          return 'Shields are already at full strength.';
        }
        return null;
      case SpellTarget.quest:
        if (target == null) return 'Choose a quest.';
        if (target.isCompleted) return 'That quest is already done.';
        return null;
      case SpellTarget.overdueQuest:
        if (target == null) return 'Choose a quest.';
        if (target.isCompleted) return 'That quest is already done.';
        if (!target.isOverdueAt(now)) return 'Only works on an overdue quest.';
        return null;
      case SpellTarget.trivialQuests:
        if (quests.trivialInProgress.isEmpty) {
          return 'No Trivial quests to sweep.';
        }
        return null;
    }
  }

  /// Casts [spell]. Spends the resource, applies the effect, records the
  /// use and unlocks any honours earned.
  Future<SpellResult> cast(Spell spell, {Quest? target}) async {
    final reason = blockedReason(spell, target: target);
    if (reason != null) return SpellResult(success: false, message: reason);

    final now = appState.now();
    final cost = costOf(spell);

    // Pay first, then apply. Honours earned by paying (e.g. Spellweaver)
    // are merged into the result.
    final paid = await appState.updateHero(
      (hero) => hero.spend(spell.resource, cost).useSkill(spell.skillId),
    );
    List<CharacterAchievement> merge(List<CharacterAchievement> more) => [
      ...paid,
      ...more.where((a) => !paid.any((p) => p.id == a.id)),
    ];

    switch (spell.skillId) {
      case 'power_strike':
        final midnight = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1));
        final unlocked = await appState.updateHero(
          (hero) => hero.withBuff(
            ActiveBuff(type: BuffType.empowered, expiresAt: midnight),
          ),
        );
        return SpellResult(
          success: true,
          message:
              'You feel empowered. Your next Hard or Epic quest pays +$empoweredPercent% XP today.',
          unlocked: merge(unlocked),
        );

      case 'swift_strike':
        final unlocked = await appState.updateHero(
          (hero) => hero.withBuff(
            ActiveBuff(
              type: BuffType.haste,
              expiresAt: now.add(const Duration(hours: 1)),
            ),
          ),
        );
        return SpellResult(
          success: true,
          message:
              'Haste! Finish a quest within the hour for +$hastePercent% XP.',
          unlocked: merge(unlocked),
        );

      case 'shield_bash':
      case 'mana_shield':
        final charges = spell.skillId == 'shield_bash' ? 1 : 2;
        final unlocked = await appState.updateHero(
          (hero) => hero.addShieldCharges(charges),
        );
        final total = appState.hero!.shieldCharges;
        return SpellResult(
          success: true,
          message:
              'Shields raised: $total ${total == 1 ? 'charge' : 'charges'} will guard your torch.',
          unlocked: merge(unlocked),
        );

      case 'heal':
        final quest = target!;
        final tomorrow = quest.dueDate.add(const Duration(days: 1));
        final due =
            tomorrow.isAfter(now) ? tomorrow : now.add(const Duration(days: 1));
        await quests.updateQuest(quest.copyWith(dueDate: due));
        final unlocked = await appState.updateHero(
          (hero) => hero.restore(health: (hero.maxHealth * 0.3).round()),
        );
        return SpellResult(
          success: true,
          message:
              '"${quest.title}" is mended and due tomorrow. Your torch burns brighter.',
          unlocked: merge(unlocked),
        );

      case 'stealth':
        final quest = target!;
        final tomorrowStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1));
        await quests.updateQuest(
          quest.copyWith(
            dueDate: quest.dueDate.add(const Duration(days: 1)),
            snoozedUntil: tomorrowStart,
          ),
        );
        return SpellResult(
          success: true,
          message: '"${quest.title}" slips into the shadows until tomorrow.',
          unlocked: merge(const []),
        );

      case 'fireball':
        final quest = target!;
        final xp = (quest.xpReward / 3).round();
        await quests.removeQuest(quest);
        final leveledUp = await appState.awardXp(xp);
        final unlocked = await appState.updateHero((hero) => hero);
        return SpellResult(
          success: true,
          message:
              '"${quest.title}" burns to ash. You salvage $xp XP from the embers.',
          xpGained: xp,
          leveledUp: leveledUp,
          unlocked: merge(unlocked),
        );

      case 'whirlwind':
        final targets = quests.trivialInProgress;
        var total = 0;
        var leveled = false;
        final unlocked = <CharacterAchievement>[];
        for (final quest in targets) {
          await quests.markQuestCompleted(quest);
          final result = await appState.completeQuestForHero(
            quest.xpReward,
            completedToday: quests.completedTodayCount,
            quest: quest,
            extraPercent: whirlwindPercent,
            extraLabel: 'Whirlwind',
          );
          total += result.xpGained;
          leveled = leveled || result.leveledUp;
          unlocked.addAll(result.unlockedAchievements);
        }
        return SpellResult(
          success: true,
          message:
              'Whirlwind! ${targets.length} trivial ${targets.length == 1 ? 'quest' : 'quests'} swept away for $total XP.',
          xpGained: total,
          leveledUp: leveled,
          unlocked: merge(unlocked),
        );

      default:
        final unlocked = await appState.updateHero((hero) => hero);
        return SpellResult(
          success: true,
          message: 'The spell fizzles harmlessly.',
          unlocked: merge(unlocked),
        );
    }
  }
}

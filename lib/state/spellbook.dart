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
    this.spell,
  });

  final bool success;
  final String message;
  final int xpGained;
  final bool leveledUp;
  final List<CharacterAchievement> unlocked;

  /// The spell that was cast (null for a refused cast).
  final Spell? spell;
}

/// Executes spells against the hero and the quest list.
///
/// Construct it from the two providers; it holds no state of its own.
class Spellbook {
  Spellbook({required this.appState, required this.quests});

  final AppState appState;
  final QuestListProvider quests;

  HeroCharacter? get hero => appState.hero;

  /// Spells the hero has learned (passive skills have none).
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
        return _selfBlockedReason(spell, h, now);
      case SpellTarget.quest:
        if (target == null) return 'Choose a quest.';
        if (target.isCompleted) return 'That quest is already done.';
        if (spell.skillId == 'enchant' && target.isEnchanted) {
          return 'Already enchanted.';
        }
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

  String? _selfBlockedReason(Spell spell, HeroCharacter h, DateTime now) {
    switch (spell.skillId) {
      case 'power_strike':
        return h.hasBuff(BuffType.empowered, now) ? 'Already empowered.' : null;
      case 'swift_strike':
        return h.hasBuff(BuffType.haste, now)
            ? 'Haste is already active.'
            : null;
      case 'battle_cry':
        return h.hasBuff(BuffType.rallied, now) ? 'Already rallied.' : null;
      case 'foresight':
        return h.hasBuff(BuffType.foresight, now)
            ? 'Foresight is already active.'
            : null;
      case 'berserk':
        if (h.hasBuff(BuffType.berserk, now)) return 'Already berserk.';
        if (h.health <= (h.maxHealth * berserkSelfDamage).round()) {
          return 'The torch is too low to rage.';
        }
        return null;
      case 'shield_bash':
      case 'mana_shield':
        return h.shieldCharges >= Spell.maxShieldCharges
            ? 'Shields are already at full strength.'
            : null;
      case 'meditate':
        return h.mana >= h.maxMana ? 'Mana is already full.' : null;
      case 'second_wind':
        return h.stamina >= h.maxStamina ? 'Stamina is already full.' : null;
      case 'divine_favour':
        return h.health >= h.maxHealth &&
                h.shieldCharges >= Spell.maxShieldCharges
            ? 'Nothing left to restore.'
            : null;
      default:
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
    final midnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    // Pay first, then apply. Honours earned by paying (e.g. Spellweaver)
    // are merged into the result.
    final paid = await appState.updateHero(
      (hero) => hero.spend(spell.resource, cost).useSkill(spell.skillId),
    );
    List<CharacterAchievement> merge(List<CharacterAchievement> more) => [
      ...paid,
      ...more.where((a) => !paid.any((p) => p.id == a.id)),
    ];

    SpellResult done(
      String message, {
      List<CharacterAchievement> unlocked = const [],
      int xp = 0,
      bool leveled = false,
    }) => SpellResult(
      success: true,
      message: message,
      unlocked: merge(unlocked),
      xpGained: xp,
      leveledUp: leveled,
      spell: spell,
    );

    switch (spell.skillId) {
      case 'power_strike':
        final unlocked = await appState.updateHero(
          (hero) => hero.withBuff(
            ActiveBuff(type: BuffType.empowered, expiresAt: midnight),
          ),
        );
        return done(
          'You feel empowered. Your next Hard or Epic quest pays +$empoweredPercent% XP today.',
          unlocked: unlocked,
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
        return done(
          'Haste! Finish a quest within the hour for +$hastePercent% XP.',
          unlocked: unlocked,
        );

      case 'battle_cry':
        final unlocked = await appState.updateHero(
          (hero) => hero.withBuff(
            ActiveBuff(type: BuffType.rallied, expiresAt: midnight),
          ),
        );
        return done(
          'Your cry echoes. Every quest until midnight pays +$ralliedPercent% XP.',
          unlocked: unlocked,
        );

      case 'foresight':
        final unlocked = await appState.updateHero(
          (hero) => hero.withBuff(
            ActiveBuff(type: BuffType.foresight, expiresAt: midnight),
          ),
        );
        return done(
          'The dice have already fallen. Your next completion is a critical.',
          unlocked: unlocked,
        );

      case 'berserk':
        final dmg = (appState.hero!.maxHealth * berserkSelfDamage).round();
        final unlocked = await appState.updateHero(
          (hero) => hero
              .damage(dmg)
              .withBuff(
                ActiveBuff(type: BuffType.berserk, expiresAt: midnight),
              ),
        );
        return done(
          'Fury takes you. The torch loses $dmg HP; your next Epic quest pays +$berserkPercent% XP.',
          unlocked: unlocked,
        );

      case 'shield_bash':
      case 'mana_shield':
        final charges = spell.skillId == 'shield_bash' ? 1 : 2;
        final unlocked = await appState.updateHero(
          (hero) => hero.addShieldCharges(charges),
        );
        final total = appState.hero!.shieldCharges;
        return done(
          'Shields raised: $total ${total == 1 ? 'charge' : 'charges'} will guard your torch.',
          unlocked: unlocked,
        );

      case 'meditate':
        final amount = (appState.hero!.maxMana * meditateFraction).round();
        final unlocked = await appState.updateHero(
          (hero) => hero.restore(mana: amount),
        );
        return done(
          'You breathe, and the well refills: +$amount MP.',
          unlocked: unlocked,
        );

      case 'second_wind':
        final amount = (appState.hero!.maxStamina * secondWindFraction).round();
        final unlocked = await appState.updateHero(
          (hero) => hero.restore(stamina: amount),
        );
        return done(
          'Second wind: +$amount STA. Not done yet.',
          unlocked: unlocked,
        );

      case 'divine_favour':
        final unlocked = await appState.updateHero(
          (hero) => hero.restore(health: hero.maxHealth).addShieldCharges(1),
        );
        return done(
          'Light floods the torch. HP is full and a shield stands with you.',
          unlocked: unlocked,
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
        return done(
          '"${quest.title}" is mended and due tomorrow. Your torch burns brighter.',
          unlocked: unlocked,
        );

      case 'stealth':
        final quest = target!;
        await quests.updateQuest(
          quest.copyWith(
            dueDate: quest.dueDate.add(const Duration(days: 1)),
            snoozedUntil: midnight,
          ),
        );
        return done('"${quest.title}" slips into the shadows until tomorrow.');

      case 'chronoshift':
        final quest = target!;
        await quests.updateQuest(
          quest.copyWith(dueDate: quest.dueDate.add(const Duration(days: 2))),
        );
        return done(
          'The sand runs backward. "${quest.title}" is now due two days later.',
        );

      case 'enchant':
        final quest = target!;
        await quests.updateQuest(
          quest.copyWith(enchantPercent: enchantPercent),
        );
        return done(
          '"${quest.title}" glimmers. It will pay +$enchantPercent% XP when done.',
        );

      case 'fireball':
        final quest = target!;
        final xp = (quest.xpReward / 3).round();
        await quests.removeQuest(quest);
        final leveledUp = await appState.awardXp(xp);
        final unlocked = await appState.updateHero((hero) => hero);
        return done(
          '"${quest.title}" burns to ash. You salvage $xp XP from the embers.',
          unlocked: unlocked,
          xp: xp,
          leveled: leveledUp,
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
        return done(
          'Whirlwind! ${targets.length} trivial ${targets.length == 1 ? 'quest' : 'quests'} swept away for $total XP.',
          unlocked: unlocked,
          xp: total,
          leveled: leveled,
        );

      default:
        final unlocked = await appState.updateHero((hero) => hero);
        return done('The spell fizzles harmlessly.', unlocked: unlocked);
    }
  }
}

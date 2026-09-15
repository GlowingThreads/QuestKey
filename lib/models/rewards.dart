/// XP reward calculation: base by difficulty, multiplied by the hero's
/// attribute affinity for the quest's category, active buffs, encounter
/// bonuses, and a Luck-based chance of a critical completion.
library;

import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/spells.dart';

/// Which attribute boosts each category.
String? affinityStatFor(QuestCategory category) => switch (category) {
  QuestCategory.health => 'strength',
  QuestCategory.work => 'dexterity',
  QuestCategory.study => 'intelligence',
  QuestCategory.creative => 'wisdom',
  QuestCategory.social => 'charisma',
  QuestCategory.home => 'constitution',
  QuestCategory.adventure => 'luck',
  QuestCategory.other => null,
};

/// Every point of the affinity attribute above this adds [affinityStepPercent].
const int affinityBaseline = 4;
const int affinityStepPercent = 3;
const int affinityCapPercent = 45;

/// Bonus percentage a hero gets on [category] from its attributes.
int affinityPercent(HeroCharacter hero, QuestCategory category) {
  final stat = affinityStatFor(category);
  if (stat == null) return 0;
  final over = hero.statValue(stat) - affinityBaseline;
  return over <= 0
      ? 0
      : (over * affinityStepPercent).clamp(0, affinityCapPercent);
}

/// Chance (0–1) of a critical completion from Luck.
double criticalChance(HeroCharacter hero) =>
    (hero.luck * 0.025).clamp(0.0, 0.35);

const int empoweredPercent = 50;
const int hastePercent = 25;
const int whirlwindPercent = 10;

/// One line of the reward explanation.
class RewardLine {
  const RewardLine(this.label, this.percent);

  final String label;
  final int percent;
}

class RewardBreakdown {
  const RewardBreakdown({
    required this.base,
    required this.lines,
    required this.critical,
    required this.total,
    required this.consumedBuffs,
  });

  final int base;
  final List<RewardLine> lines;
  final bool critical;
  final int total;

  /// Buffs that were used up by this completion.
  final List<BuffType> consumedBuffs;

  int get bonusPercent => lines.fold(0, (sum, l) => sum + l.percent);

  /// Short human summary, e.g. "200 XP · Intelligence +9% · Empowered +50% · CRITICAL ×2".
  String get summary {
    final parts = <String>['$base XP'];
    for (final line in lines) {
      parts.add('${line.label} +${line.percent}%');
    }
    if (critical) parts.add('CRITICAL ×2');
    return parts.join(' · ');
  }
}

/// Computes the XP for completing [quest].
///
/// [roll] is a number in [0, 1); a roll below [criticalChance] is a
/// critical. Inject it for deterministic tests.
RewardBreakdown computeReward(
  HeroCharacter hero,
  Quest quest, {
  required DateTime now,
  required double roll,
  int extraPercent = 0,
  String? extraLabel,
}) {
  final base = quest.xpReward;
  final lines = <RewardLine>[];
  final consumed = <BuffType>[];

  final affinity = affinityPercent(hero, quest.category);
  if (affinity > 0) {
    lines.add(
      RewardLine(_capitalise(affinityStatFor(quest.category)!), affinity),
    );
  }

  if (hero.hasBuff(BuffType.empowered, now) && quest.difficulty >= 4) {
    lines.add(const RewardLine('Empowered', empoweredPercent));
    consumed.add(BuffType.empowered);
  }
  if (hero.hasBuff(BuffType.haste, now)) {
    lines.add(const RewardLine('Haste', hastePercent));
    consumed.add(BuffType.haste);
  }
  if (quest.xpBonusPercent > 0) {
    lines.add(RewardLine('Encounter', quest.xpBonusPercent));
  }
  if (quest.isBoss) {
    lines.add(const RewardLine('Boss quest', 25));
  }
  if (extraPercent > 0) {
    lines.add(RewardLine(extraLabel ?? 'Bonus', extraPercent));
  }

  final critical = roll < criticalChance(hero);
  final percent = lines.fold(0, (sum, l) => sum + l.percent);
  var total = (base * (1 + percent / 100)).round();
  if (critical) total *= 2;

  return RewardBreakdown(
    base: base,
    lines: lines,
    critical: critical,
    total: total,
    consumedBuffs: consumed,
  );
}

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/rewards.dart';
import 'package:quest_key/models/spells.dart';

import 'helpers/heroes.dart';

void main() {
  final now = DateTime(2030, 6, 1, 12);

  Quest quest({
    QuestCategory category = QuestCategory.other,
    int difficulty = 2,
    int bonus = 0,
    List<QuestStep>? steps,
  }) => Quest(
    id: 1,
    title: 'Q',
    description: 'd',
    dueDate: now,
    category: category,
    difficulty: difficulty,
    xpBonusPercent: bonus,
    steps: steps,
  );

  test('no affinity, no buffs, no crit: base XP', () {
    final r = computeReward(makeHero(), quest(), now: now, roll: 0.99);
    expect(r.base, 100);
    expect(r.total, 100);
    expect(r.lines, isEmpty);
    expect(r.critical, isFalse);
    expect(r.summary, '100 XP');
  });

  test('attribute affinity boosts its category', () {
    // Strength 7 → 3 points over baseline → +9% on Health quests.
    final r = computeReward(
      makeHero(strength: 7),
      quest(category: QuestCategory.health),
      now: now,
      roll: 0.99,
    );
    expect(affinityPercent(makeHero(strength: 7), QuestCategory.health), 9);
    expect(r.total, 109);
    expect(r.lines.single.label, 'Strength');
    // Below baseline there is no penalty.
    expect(affinityPercent(makeHero(intelligence: 2), QuestCategory.study), 0);
    // Capped.
    expect(
      affinityPercent(makeHero(strength: 40), QuestCategory.health),
      affinityCapPercent,
    );
  });

  test('empowered applies only to Hard/Epic and is consumed', () {
    final hero = makeHero().withBuff(
      ActiveBuff(
        type: BuffType.empowered,
        expiresAt: now.add(const Duration(hours: 1)),
      ),
    );
    final easy = computeReward(
      hero,
      quest(difficulty: 2),
      now: now,
      roll: 0.99,
    );
    expect(easy.consumedBuffs, isEmpty);
    expect(easy.total, 100);

    final hard = computeReward(
      hero,
      quest(difficulty: 4),
      now: now,
      roll: 0.99,
    );
    expect(hard.total, 300);
    expect(hard.consumedBuffs, [BuffType.empowered]);
  });

  test('haste applies before expiry only', () {
    final hero = makeHero().withBuff(
      ActiveBuff(
        type: BuffType.haste,
        expiresAt: now.add(const Duration(minutes: 30)),
      ),
    );
    expect(computeReward(hero, quest(), now: now, roll: 0.99).total, 125);
    expect(
      computeReward(
        hero,
        quest(),
        now: now.add(const Duration(hours: 2)),
        roll: 0.99,
      ).total,
      100,
    );
  });

  test('encounter bonus and boss bonus stack additively', () {
    final r = computeReward(
      makeHero(),
      quest(bonus: 50, steps: const [QuestStep(title: 'a', done: true)]),
      now: now,
      roll: 0.99,
    );
    expect(r.bonusPercent, 75);
    expect(r.total, 175);
  });

  test('luck drives critical completions which double the total', () {
    final lucky = makeHero(luck: 10); // 25% chance
    expect(criticalChance(lucky), 0.25);
    expect(
      computeReward(lucky, quest(), now: now, roll: 0.10).critical,
      isTrue,
    );
    expect(computeReward(lucky, quest(), now: now, roll: 0.10).total, 200);
    expect(
      computeReward(lucky, quest(), now: now, roll: 0.30).critical,
      isFalse,
    );
    expect(criticalChance(makeHero(luck: 0)), 0);
    expect(criticalChance(makeHero(luck: 99)), 0.35);
  });
}

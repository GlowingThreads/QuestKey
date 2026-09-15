import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/familiar.dart';
import 'package:quest_key/widgets/familiar/familiar_behaviour.dart';

void main() {
  test('the familiar roams the den without leaving it', () {
    final b = FamiliarBehaviour(random: Random(7));
    final seen = <FamiliarAction>{};
    for (var i = 0; i < 60 * 30; i++) {
      b.tick(1 / 30);
      seen.add(b.action);
      expect(b.x, inInclusiveRange(0.0, 1.0));
    }
    expect(seen, containsAll([FamiliarAction.walk, FamiliarAction.idle]));
    expect(seen.length, greaterThanOrEqualTo(4), reason: 'varied actions');
  });

  test('walking faces the target and arrives', () {
    final b = FamiliarBehaviour(random: Random(3), x: 0.5);
    // Run until a walk begins.
    while (b.action != FamiliarAction.walk) {
      b.tick(0.1);
    }
    final startX = b.x;
    final facingRight = b.facingRight;
    b.tick(0.2);
    expect(b.x > startX, facingRight, reason: 'moves the way it faces');
    expect(b.walkPhase, greaterThan(0));
    while (b.action == FamiliarAction.walk) {
      b.tick(0.1);
    }
    expect(b.action, isNot(FamiliarAction.walk), reason: 'never walks twice');
  });

  test('a startle hops and then resumes', () {
    final b = FamiliarBehaviour(random: Random(1));
    b.startle();
    expect(b.action, FamiliarAction.hop);
    b.tick(0.3);
    expect(b.hopProgress, closeTo(0.3 / FamiliarBehaviour.hopSeconds, 1e-9));
    b.tick(1);
    expect(b.action, isNot(FamiliarAction.hop));
    expect(b.hopProgress, 0);
  });

  test('a sleepy familiar mostly sleeps; a joyful one never does', () {
    var sleeps = 0;
    var total = 0;
    final sleepy = FamiliarBehaviour(
      random: Random(9),
      mood: FamiliarMood.sleepy,
    );
    for (var i = 0; i < 60 * 40; i++) {
      sleepy.tick(1 / 20);
      total++;
      if (sleepy.action == FamiliarAction.sleep) sleeps++;
    }
    expect(sleeps / total, greaterThan(0.4));

    final joyful = FamiliarBehaviour(
      random: Random(9),
      mood: FamiliarMood.joyful,
    );
    for (var i = 0; i < 60 * 40; i++) {
      joyful.tick(1 / 20);
      expect(joyful.action, isNot(FamiliarAction.sleep));
    }
  });
}

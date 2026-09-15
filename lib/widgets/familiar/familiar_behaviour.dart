/// What the familiar is doing in its den, decided by a small stochastic
/// state machine. Pure Dart so it can be unit-tested with a seeded
/// [math.Random]; the stage widget ticks it and any renderer (painter,
/// sprite sheet or Rive) reads [action], [x], [facingRight] and [walkPhase].
library;

import 'dart:math' as math;

import 'package:quest_key/models/familiar.dart';

enum FamiliarAction { idle, walk, sit, sleep, groom, stretch, hop }

class FamiliarBehaviour {
  FamiliarBehaviour({
    math.Random? random,
    this.x = 0.5,
    this.facingRight = true,
    this.mood = FamiliarMood.content,
  }) : _random = random ?? math.Random();

  final math.Random _random;

  /// Position across the den, 0 (left edge) to 1 (right edge).
  double x;
  bool facingRight;
  FamiliarMood mood;
  FamiliarAction action = FamiliarAction.idle;

  /// Seconds left in the current action (walks end on arrival instead).
  double remaining = 1.5;

  /// Accumulates while walking; renderers use it for the leg cycle.
  double walkPhase = 0;

  /// Progress through a hop, 0–1.
  double hopProgress = 0;

  double? _target;

  /// Den widths per second.
  static const double walkSpeed = 0.13;
  static const double hopSeconds = 0.62;

  /// Advances the simulation by [dt] seconds.
  void tick(double dt) {
    if (dt <= 0) return;
    switch (action) {
      case FamiliarAction.walk:
        final target = _target ?? x;
        final step = walkSpeed * dt;
        walkPhase += dt * 2.2;
        if ((target - x).abs() <= step) {
          x = target;
          _target = null;
          _chooseNext(afterWalk: true);
        } else {
          x += target > x ? step : -step;
        }
      case FamiliarAction.hop:
        hopProgress = (hopProgress + dt / hopSeconds).clamp(0.0, 1.0);
        if (hopProgress >= 1) {
          hopProgress = 0;
          _chooseNext();
        }
      default:
        remaining -= dt;
        if (remaining <= 0) _chooseNext();
    }
  }

  /// A tap or a completed quest: the familiar hops, whatever it was doing.
  void startle() {
    action = FamiliarAction.hop;
    hopProgress = 0;
    _target = null;
  }

  /// Weighted choice of the next action; the mood tilts the odds.
  void _chooseNext({bool afterWalk = false}) {
    final weights = switch (mood) {
      FamiliarMood.sleepy => {
        FamiliarAction.sleep: 5.0,
        FamiliarAction.idle: 3.0,
        FamiliarAction.sit: 2.0,
        FamiliarAction.walk: 1.0,
        FamiliarAction.groom: 1.0,
        FamiliarAction.stretch: 1.0,
      },
      FamiliarMood.watchful => {
        FamiliarAction.idle: 3.0,
        FamiliarAction.walk: 3.0,
        FamiliarAction.sit: 2.0,
        FamiliarAction.groom: 1.0,
        FamiliarAction.stretch: 1.0,
        FamiliarAction.sleep: 0.5,
      },
      FamiliarMood.content => {
        FamiliarAction.walk: 3.0,
        FamiliarAction.idle: 2.0,
        FamiliarAction.sit: 2.0,
        FamiliarAction.groom: 2.0,
        FamiliarAction.stretch: 1.0,
        FamiliarAction.sleep: 1.0,
      },
      FamiliarMood.joyful => {
        FamiliarAction.walk: 4.0,
        FamiliarAction.hop: 2.0,
        FamiliarAction.idle: 1.0,
        FamiliarAction.stretch: 1.0,
        FamiliarAction.groom: 1.0,
        FamiliarAction.sit: 1.0,
      },
    };
    // Never walk twice in a row; do something on arrival.
    if (afterWalk) weights.remove(FamiliarAction.walk);

    final total = weights.values.fold(0.0, (a, b) => a + b);
    var roll = _random.nextDouble() * total;
    var next = weights.keys.first;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) {
        next = entry.key;
        break;
      }
    }
    _begin(next);
  }

  void _begin(FamiliarAction next) {
    action = next;
    hopProgress = 0;
    switch (next) {
      case FamiliarAction.walk:
        // Somewhere at least a fifth of the den away, inside the margins.
        double target;
        do {
          target = 0.08 + _random.nextDouble() * 0.84;
        } while ((target - x).abs() < 0.2);
        _target = target;
        facingRight = target > x;
      case FamiliarAction.idle:
        remaining = _between(1.5, 3.5);
      case FamiliarAction.sit:
        remaining = _between(3, 6);
      case FamiliarAction.sleep:
        remaining = _between(6, 12);
      case FamiliarAction.groom:
        remaining = _between(2, 4);
      case FamiliarAction.stretch:
        remaining = _between(1.5, 2.5);
      case FamiliarAction.hop:
        remaining = hopSeconds;
    }
  }

  double _between(double a, double b) => a + _random.nextDouble() * (b - a);
}

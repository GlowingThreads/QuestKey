/// Level / experience progression for a hero.
///
/// Immutable: [applyExperience] returns a new instance rather than mutating.
class LevelUp {
  /// Extra XP needed for each successive level.
  static const int expIncrementPerLevel = 100;

  /// Stat points granted on each level up.
  static const int statPointsPerLevel = 3;

  final int level;
  final int exp;
  final int maxExp;
  final int statPoints;

  const LevelUp({
    this.level = 1,
    this.exp = 0,
    this.maxExp = 100,
    this.statPoints = 0,
  });

  /// Fraction of the way to the next level, from 0.0 to 1.0.
  double get progress =>
      maxExp <= 0 ? 0.0 : (exp / maxExp).clamp(0.0, 1.0).toDouble();

  /// XP still needed to reach the next level.
  int get expToNextLevel => (maxExp - exp).clamp(0, maxExp);

  /// Adds [amount] XP, levelling up as many times as the XP allows and
  /// carrying any excess XP over to the next level.
  ///
  /// Returns the new state and whether at least one level was gained.
  ({LevelUp next, bool leveledUp}) applyExperience(int amount) {
    if (amount <= 0) return (next: this, leveledUp: false);

    var newLevel = level;
    var newExp = exp + amount;
    var newMaxExp = maxExp;
    var newStatPoints = statPoints;
    var leveledUp = false;

    while (newExp >= newMaxExp) {
      newExp -= newMaxExp;
      newLevel += 1;
      newMaxExp += expIncrementPerLevel;
      newStatPoints += statPointsPerLevel;
      leveledUp = true;
    }

    return (
      next: LevelUp(
        level: newLevel,
        exp: newExp,
        maxExp: newMaxExp,
        statPoints: newStatPoints,
      ),
      leveledUp: leveledUp,
    );
  }

  LevelUp copyWith({int? level, int? exp, int? maxExp, int? statPoints}) {
    return LevelUp(
      level: level ?? this.level,
      exp: exp ?? this.exp,
      maxExp: maxExp ?? this.maxExp,
      statPoints: statPoints ?? this.statPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'exp': exp,
      'maxExp': maxExp,
      'statPoints': statPoints,
    };
  }

  factory LevelUp.fromJson(Map<String, dynamic> json) {
    return LevelUp(
      level: (json['level'] as num?)?.toInt() ?? 1,
      exp: (json['exp'] as num?)?.toInt() ?? 0,
      maxExp: (json['maxExp'] as num?)?.toInt() ?? 100,
      statPoints: (json['statPoints'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LevelUp &&
        other.level == level &&
        other.exp == exp &&
        other.maxExp == maxExp &&
        other.statPoints == statPoints;
  }

  @override
  int get hashCode => Object.hash(level, exp, maxExp, statPoints);

  @override
  String toString() {
    return 'LevelUp(level: $level, exp: $exp, maxExp: $maxExp, '
        'statPoints: $statPoints)';
  }
}

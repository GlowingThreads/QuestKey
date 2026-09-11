import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/level_up.dart';

HeroCharacter _hero() => HeroCharacter(
  name: 'H',
  motto: '',
  classes: wizard,
  description: '',
  imageUrl: '',
  levelUp: const LevelUp(),
);

void main() {
  final day1 = DateTime(2030, 3, 1, 9);

  test('first completion starts a streak of 1', () {
    final hero = _hero().recordQuestCompletion(day1);
    expect(hero.questsCompleted, 1);
    expect(hero.currentStreak, 1);
    expect(hero.longestStreak, 1);
    expect(hero.lastQuestCompletedOn, DateTime(2030, 3, 1));
  });

  test('several completions on the same day keep the streak at 1', () {
    var hero = _hero().recordQuestCompletion(day1);
    hero = hero.recordQuestCompletion(day1.add(const Duration(hours: 5)));
    expect(hero.questsCompleted, 2);
    expect(hero.currentStreak, 1);
  });

  test('consecutive days extend the streak', () {
    var hero = _hero();
    for (var i = 0; i < 4; i++) {
      hero = hero.recordQuestCompletion(day1.add(Duration(days: i)));
    }
    expect(hero.currentStreak, 4);
    expect(hero.longestStreak, 4);
  });

  test('a missed day resets the streak but keeps the longest', () {
    var hero = _hero();
    for (var i = 0; i < 3; i++) {
      hero = hero.recordQuestCompletion(day1.add(Duration(days: i)));
    }
    hero = hero.recordQuestCompletion(day1.add(const Duration(days: 5)));
    expect(hero.currentStreak, 1);
    expect(hero.longestStreak, 3);
  });

  test('late-night completion counts for its calendar day', () {
    var hero = _hero().recordQuestCompletion(DateTime(2030, 3, 1, 23, 59));
    hero = hero.recordQuestCompletion(DateTime(2030, 3, 2, 0, 1));
    expect(hero.currentStreak, 2);
  });

  test('isStreakAliveAt', () {
    final hero = _hero().recordQuestCompletion(day1);
    expect(hero.isStreakAliveAt(day1), isTrue);
    expect(hero.isStreakAliveAt(day1.add(const Duration(days: 1))), isTrue);
    expect(hero.isStreakAliveAt(day1.add(const Duration(days: 2))), isFalse);
    expect(_hero().isStreakAliveAt(day1), isFalse);
  });

  test(
    'streak fields survive a JSON round trip and default for legacy data',
    () {
      final hero = _hero().recordQuestCompletion(day1);
      final again = HeroCharacter.fromJson(hero.toJson());
      expect(again.currentStreak, 1);
      expect(again.lastQuestCompletedOn, DateTime(2030, 3, 1));

      final legacy = HeroCharacter.fromJson(
        hero.toJson()
          ..remove('currentStreak')
          ..remove('longestStreak')
          ..remove('lastQuestCompletedOn'),
      );
      expect(legacy.currentStreak, 0);
      expect(legacy.lastQuestCompletedOn, isNull);
    },
  );
}

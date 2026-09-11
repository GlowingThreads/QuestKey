import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/quest.dart';

void main() {
  final now = DateTime(2030, 1, 10, 12, 0);

  Quest due(DateTime dueDate) =>
      Quest(id: 1, title: 'T', description: 'D', dueDate: dueDate);

  group('Quest.timeRemainingLabelAt', () {
    test('overdue', () {
      final q = due(now.subtract(const Duration(minutes: 1)));
      expect(q.timeRemainingLabelAt(now), 'Overdue');
      expect(q.isOverdueAt(now), isTrue);
      expect(q.timeUntilDueAt(now).isNegative, isTrue);
    });

    test('completed quests are never overdue', () {
      final q = due(
        now.subtract(const Duration(days: 1)),
      ).copyWith(status: QuestStatus.completed);
      expect(q.isOverdueAt(now), isFalse);
    });

    test('due now (under a minute)', () {
      expect(
        due(now.add(const Duration(seconds: 30))).timeRemainingLabelAt(now),
        'Due now',
      );
      expect(due(now).timeRemainingLabelAt(now), 'Due now');
    });

    test('less than one hour', () {
      expect(
        due(now.add(const Duration(minutes: 45))).timeRemainingLabelAt(now),
        '45 mins',
      );
      expect(
        due(now.add(const Duration(minutes: 1))).timeRemainingLabelAt(now),
        '1 min',
      );
    });

    test('less than one day', () {
      expect(
        due(
          now.add(const Duration(hours: 3, minutes: 7)),
        ).timeRemainingLabelAt(now),
        '3 hrs, 7 mins',
      );
      expect(
        due(now.add(const Duration(hours: 1))).timeRemainingLabelAt(now),
        '1 hr, 0 mins',
      );
    });

    test('more than one day', () {
      expect(
        due(
          now.add(const Duration(days: 2, hours: 3, minutes: 59)),
        ).timeRemainingLabelAt(now),
        '2 days, 3 hrs',
      );
      expect(
        due(
          now.add(const Duration(days: 1, hours: 1)),
        ).timeRemainingLabelAt(now),
        '1 day, 1 hr',
      );
    });

    test('formatTimeRemaining is the single formatter', () {
      expect(
        Quest.formatTimeRemaining(const Duration(days: 5)),
        '5 days, 0 hrs',
      );
      expect(Quest.formatTimeRemaining(const Duration(seconds: -1)), 'Overdue');
    });
  });
}

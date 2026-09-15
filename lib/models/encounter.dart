/// Daily encounters: a small story that appears on the Home tab and offers a
/// bonus quest, or a shortcut for heroes who know the right spell.
library;

import 'dart:math';

import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';

class EncounterTemplate {
  const EncounterTemplate({
    required this.id,
    required this.title,
    required this.story,
    required this.questTitle,
    required this.questDescription,
    required this.category,
    required this.difficulty,
    required this.hoursToComplete,
    this.minLevel = 1,
    this.bonusPercent = 50,
    this.classNames = const [],
  });

  final String id;
  final String title;
  final String story;
  final String questTitle;
  final String questDescription;
  final QuestCategory category;
  final int difficulty;
  final int hoursToComplete;
  final int minLevel;
  final int bonusPercent;

  /// Restrict to these classes (empty = any).
  final List<String> classNames;

  bool eligibleFor(HeroCharacter hero) =>
      hero.levelUp.level >= minLevel &&
      (classNames.isEmpty || classNames.contains(hero.classes.className));
}

const List<EncounterTemplate> encounterTemplates = [
  EncounterTemplate(
    id: 'courier',
    title: 'The Courier',
    story:
        'A breathless courier stops you at the crossroads. "One message, one '
        'errand, before dusk. The guild pays well for reliable hands."',
    questTitle: 'Run one overdue errand',
    questDescription: 'The thing you keep postponing. Do it before dusk.',
    category: QuestCategory.home,
    difficulty: 2,
    hoursToComplete: 8,
  ),
  EncounterTemplate(
    id: 'hermit',
    title: 'The Hermit\'s Riddle',
    story:
        'An old hermit taps a book against your chest. "Learn one thing you '
        'did not know this morning, and I will teach you a trick in return."',
    questTitle: 'Learn something new',
    questDescription: 'Read, watch or practise something for 25 minutes.',
    category: QuestCategory.study,
    difficulty: 2,
    hoursToComplete: 10,
  ),
  EncounterTemplate(
    id: 'training',
    title: 'The Sparring Ground',
    story:
        'The garrison sergeant grins. "Care to keep those muscles honest? '
        'Twenty minutes, no excuses, and the coin is yours."',
    questTitle: 'Twenty minutes of movement',
    questDescription:
        'Walk, run, lift or stretch. Anything that raises your pulse.',
    category: QuestCategory.health,
    difficulty: 2,
    hoursToComplete: 12,
  ),
  EncounterTemplate(
    id: 'tavern',
    title: 'A Face at the Tavern',
    story:
        'Across the tavern you spot someone you have been meaning to talk to. '
        'They raise a cup. The moment will not come twice.',
    questTitle: 'Reach out to someone',
    questDescription:
        'Send the message or make the call you have been putting off.',
    category: QuestCategory.social,
    difficulty: 1,
    hoursToComplete: 6,
  ),
  EncounterTemplate(
    id: 'workshop',
    title: 'The Locked Workshop',
    story:
        'The workshop door is jammed with half-finished projects. The '
        'artificer sighs: "Finish one. Just one. Then we can both breathe."',
    questTitle: 'Finish one lingering task',
    questDescription:
        'Pick the smallest unfinished thing on your list and close it.',
    category: QuestCategory.work,
    difficulty: 3,
    hoursToComplete: 9,
    minLevel: 2,
    bonusPercent: 60,
  ),
  EncounterTemplate(
    id: 'muse',
    title: 'The Wandering Muse',
    story:
        'A figure in patchwork silks hums a tune only you can hear. "Make '
        'something today, and I will remember your name."',
    questTitle: 'Make something',
    questDescription: 'Write, draw, cook or build for thirty minutes.',
    category: QuestCategory.creative,
    difficulty: 2,
    hoursToComplete: 12,
    minLevel: 2,
  ),
  EncounterTemplate(
    id: 'dragon',
    title: 'Smoke Over the Ridge',
    story:
        'Smoke curls over the ridge. Something large has been sleeping on a '
        'problem you have avoided for weeks. Time to face it.',
    questTitle: 'Face the thing you have been avoiding',
    questDescription:
        'The big, uncomfortable task. Ninety minutes of honest effort.',
    category: QuestCategory.adventure,
    difficulty: 5,
    hoursToComplete: 14,
    minLevel: 3,
    bonusPercent: 80,
  ),
];

enum EncounterStatus { pending, accepted, declined, resolved }

/// The encounter for a given day and how it was handled.
class Encounter {
  const Encounter({
    required this.templateId,
    required this.day,
    this.status = EncounterStatus.pending,
    this.outcome,
    this.questId,
  });

  final String templateId;

  /// Calendar day (time stripped).
  final DateTime day;
  final EncounterStatus status;

  /// Short narration of what happened, once resolved.
  final String? outcome;

  /// Id of the quest created when accepted.
  final int? questId;

  EncounterTemplate get template =>
      encounterTemplates.firstWhere((t) => t.id == templateId);

  bool get isOpen => status == EncounterStatus.pending;

  Encounter copyWith({
    EncounterStatus? status,
    String? outcome,
    int? questId,
  }) => Encounter(
    templateId: templateId,
    day: day,
    status: status ?? this.status,
    outcome: outcome ?? this.outcome,
    questId: questId ?? this.questId,
  );

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'day': day.toIso8601String(),
    'status': status.name,
    'outcome': outcome,
    'questId': questId,
  };

  static Encounter? fromJson(Map<String, dynamic> json) {
    final id = json['templateId'] as String?;
    final day = DateTime.tryParse(json['day'] as String? ?? '');
    if (id == null || day == null) return null;
    if (!encounterTemplates.any((t) => t.id == id)) return null;
    return Encounter(
      templateId: id,
      day: day,
      status: EncounterStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EncounterStatus.pending,
      ),
      outcome: json['outcome'] as String?,
      questId: (json['questId'] as num?)?.toInt(),
    );
  }
}

/// Chance that a given day has an encounter at all.
const double encounterChance = 0.8;

/// Deterministically picks the encounter for [day] and [hero] (same day,
/// same hero level/class → same encounter), or `null` for a quiet day.
Encounter? rollEncounter(DateTime day, HeroCharacter hero) {
  final d = DateTime(day.year, day.month, day.day);
  final seed = d.year * 10000 + d.month * 100 + d.day + hero.name.hashCode;
  final random = Random(seed);
  if (random.nextDouble() > encounterChance) return null;

  final eligible =
      encounterTemplates.where((t) => t.eligibleFor(hero)).toList();
  if (eligible.isEmpty) return null;
  final template = eligible[random.nextInt(eligible.length)];
  return Encounter(templateId: template.id, day: d);
}

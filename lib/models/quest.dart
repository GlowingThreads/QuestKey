/// Quest model.
///
/// A quest is an immutable value object. Use [copyWith] to derive a changed
/// copy. JSON serialisation is backward compatible with the original schema
/// (string `status`, `startDate`/`endDate` strings, stored `timeRemaining`).
library;

/// Status of a quest.
enum QuestStatus {
  inProgress('In Progress'),
  completed('Completed');

  const QuestStatus(this.label);

  /// Human readable label. Also the value written to JSON so that data saved
  /// by older versions of the app (which stored this exact string) still
  /// parses.
  final String label;

  String toJson() => label;

  /// Parses a stored value, accepting either the [label] or the enum [name].
  /// Falls back to [inProgress] for anything unknown.
  static QuestStatus fromJson(Object? value) => fromString(value?.toString());

  /// Parses [value] with a safe fallback to [inProgress].
  static QuestStatus fromString(String? value) {
    if (value == null) return QuestStatus.inProgress;
    final normalized = value.trim().toLowerCase();
    for (final status in QuestStatus.values) {
      if (status.label.toLowerCase() == normalized ||
          status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return QuestStatus.inProgress;
  }
}

/// Lowest selectable difficulty.
const int minDifficulty = 1;

/// Highest selectable difficulty.
const int maxDifficulty = 5;

/// XP granted per point of difficulty.
const int xpPerDifficulty = 50;

/// Default image shown for a quest that is still in progress.
const String defaultQuestImage = 'assets/images/app_assets/todo.png';

/// Single source of truth for how much XP a quest of difficulty [difficulty]
/// is worth.
int xpForDifficulty(int difficulty) =>
    xpPerDifficulty * difficulty.clamp(minDifficulty, maxDifficulty);

class Quest {
  final int id;
  final String title;
  final String description;
  final QuestStatus status;

  /// Difficulty from [minDifficulty] to [maxDifficulty]. Drives [xpReward].
  final int difficulty;

  /// When the quest is due.
  final DateTime dueDate;
  final String questImageUrl;

  /// Whether the user asked to be reminded shortly before [dueDate].
  final bool remindMe;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = QuestStatus.inProgress,
    int difficulty = minDifficulty,
    this.questImageUrl = defaultQuestImage,
    this.remindMe = false,
  }) : difficulty = difficulty.clamp(minDifficulty, maxDifficulty);

  /// XP awarded on completion. Always derived from [difficulty].
  int get xpReward => xpForDifficulty(difficulty);

  bool get isCompleted => status == QuestStatus.completed;

  /// Time left until [dueDate], measured from the wall clock.
  Duration get timeUntilDue => timeUntilDueAt(DateTime.now());

  /// Time left until [dueDate], measured from [now]. Negative when overdue.
  Duration timeUntilDueAt(DateTime now) => dueDate.difference(now);

  /// Whether the quest is past due and still not completed.
  bool get isOverdue => isOverdueAt(DateTime.now());

  bool isOverdueAt(DateTime now) =>
      !isCompleted && timeUntilDueAt(now).isNegative;

  /// Human readable time remaining, e.g. "2 days, 3 hrs" or "Overdue".
  String get timeRemainingLabel => timeRemainingLabelAt(DateTime.now());

  /// Human readable time remaining measured from [now].
  String timeRemainingLabelAt(DateTime now) =>
      formatTimeRemaining(timeUntilDueAt(now));

  /// Formats a remaining [duration] for display.
  ///
  /// * negative → "Overdue"
  /// * under a minute → "Due now"
  /// * under an hour → "N mins"
  /// * under a day → "H hrs, M mins"
  /// * otherwise → "D days, H hrs"
  static String formatTimeRemaining(Duration duration) {
    if (duration.isNegative) return 'Overdue';
    if (duration.inMinutes < 1) return 'Due now';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${_plural(days, 'day')}, ${_plural(hours, 'hr')}';
    }
    if (hours > 0) {
      return '${_plural(hours, 'hr')}, ${_plural(minutes, 'min')}';
    }
    return _plural(minutes, 'min');
  }

  static String _plural(int value, String unit) =>
      '$value $unit${value == 1 ? '' : 's'}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toJson(),
      'difficulty': difficulty,
      // Kept for readers of the old schema; `difficulty` is the source of truth.
      'xpReward': xpReward,
      'dueDate': dueDate.toIso8601String(),
      'questImageUrl': questImageUrl,
      'remindMe': remindMe,
    };
  }

  /// Builds a quest from JSON written by this or any earlier version of the
  /// app.
  ///
  /// Legacy keys handled: string `status`, `startDate`/`endDate` strings
  /// (used when `dueDate` is absent), `xpReward` (used to derive
  /// `difficulty` when absent) and `timeRemaining` (ignored; it is now
  /// computed).
  factory Quest.fromJson(Map<String, dynamic> json) {
    final difficulty = _readDifficulty(json);
    final dueDate =
        _parseDate(json['dueDate']) ??
        _parseDate(json['endDate']) ??
        _parseDate(json['startDate']) ??
        DateTime.now();

    return Quest(
      id: (json['id'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Empty Quest',
      description: json['description'] as String? ?? 'No quest description',
      status: QuestStatus.fromJson(json['status']),
      difficulty: difficulty,
      dueDate: dueDate,
      questImageUrl: json['questImageUrl'] as String? ?? defaultQuestImage,
      remindMe: json['remindMe'] == true,
    );
  }

  static int _readDifficulty(Map<String, dynamic> json) {
    final stored = json['difficulty'];
    if (stored is num) return stored.toInt().clamp(minDifficulty, maxDifficulty);

    final xp = json['xpReward'];
    if (xp is num && xp > 0) {
      return (xp / xpPerDifficulty).round().clamp(minDifficulty, maxDifficulty);
    }
    return minDifficulty;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Quest copyWith({
    int? id,
    String? title,
    String? description,
    QuestStatus? status,
    int? difficulty,
    DateTime? dueDate,
    String? questImageUrl,
    bool? remindMe,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      dueDate: dueDate ?? this.dueDate,
      questImageUrl: questImageUrl ?? this.questImageUrl,
      remindMe: remindMe ?? this.remindMe,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Quest &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.status == status &&
        other.difficulty == difficulty &&
        other.dueDate == dueDate &&
        other.questImageUrl == questImageUrl &&
        other.remindMe == remindMe;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    status,
    difficulty,
    dueDate,
    questImageUrl,
    remindMe,
  );

  @override
  String toString() =>
      'Quest(id: $id, title: $title, status: ${status.label}, '
      'difficulty: $difficulty, dueDate: $dueDate)';
}

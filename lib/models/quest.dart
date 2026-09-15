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

/// What kind of task a quest is. Gives each quest an icon and colour so the
/// list is scannable without custom image assets.
enum QuestCategory {
  health('Health', '💪', 0xFFC62828),
  work('Work', '💼', 0xFFB8860B),
  study('Study', '📚', 0xFF1E5AA8),
  home('Home', '🏠', 0xFF2E7D5B),
  social('Social', '🤝', 0xFFAD3E7A),
  creative('Creative', '🎨', 0xFF7E57C2),
  adventure('Adventure', '🗺️', 0xFF1F8F86),
  other('Other', '📜', 0xFF5E35B1);

  const QuestCategory(this.label, this.icon, this.colorValue);

  final String label;

  /// Emoji shown on the quest tile.
  final String icon;

  /// ARGB colour used for the tile accent (kept as an int so the model has
  /// no Flutter dependency).
  final int colorValue;

  static QuestCategory fromJson(Object? value) {
    final name = value?.toString().toLowerCase();
    for (final category in QuestCategory.values) {
      if (category.name == name) return category;
    }
    return QuestCategory.other;
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

/// Player-facing name for a difficulty level.
String difficultyLabel(int difficulty) => switch (difficulty.clamp(
  minDifficulty,
  maxDifficulty,
)) {
  1 => 'Trivial',
  2 => 'Easy',
  3 => 'Normal',
  4 => 'Hard',
  _ => 'Epic',
};

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

  final QuestCategory category;

  /// When the quest was completed; `null` while in progress.
  final DateTime? completedAt;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = QuestStatus.inProgress,
    int difficulty = minDifficulty,
    this.questImageUrl = defaultQuestImage,
    this.remindMe = false,
    this.category = QuestCategory.other,
    this.completedAt,
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

  /// Whether the quest is due on the same calendar day as [now].
  bool isDueOn(DateTime day) => _sameDay(dueDate, day);

  /// Whether the quest was completed on the calendar day of [day].
  bool wasCompletedOn(DateTime day) {
    final at = completedAt;
    return at != null && _sameDay(at, day);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
      'category': category.name,
      'completedAt': completedAt?.toIso8601String(),
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
      category: QuestCategory.fromJson(json['category']),
      completedAt: _parseDate(json['completedAt']),
    );
  }

  static int _readDifficulty(Map<String, dynamic> json) {
    final stored = json['difficulty'];
    if (stored is num) {
      return stored.toInt().clamp(minDifficulty, maxDifficulty);
    }

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
    QuestCategory? category,
    DateTime? completedAt,
    bool clearCompletedAt = false,
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
      category: category ?? this.category,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
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
        other.remindMe == remindMe &&
        other.category == category &&
        other.completedAt == completedAt;
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
    category,
    completedAt,
  );

  @override
  String toString() =>
      'Quest(id: $id, title: $title, status: ${status.label}, '
      'difficulty: $difficulty, dueDate: $dueDate)';
}

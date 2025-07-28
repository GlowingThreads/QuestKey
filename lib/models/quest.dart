//quest class
class Quest {
  int id;
  String title;
  String description;
  String status;
  int xpReward;
  String startDate;
  String endDate;
  String timeRemaining = '0';
  String questImageUrl = 'assets/images/app_assets/todo.png';

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.xpReward,
    required this.startDate,
    required this.endDate,
    required this.timeRemaining,
    required this.questImageUrl,
  });

  // method to convert
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'xpReward': xpReward,
      'startDate': startDate,
      'endDate': endDate,
      'timeRemaining': timeRemaining,
      'questImageUrl': questImageUrl,
    };
  }

  /// factory const to create a new instance and init/convert
  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] ?? 1,
      title: json['title'] ?? 'Empty Quest',
      description: json['description'] ?? 'No quest description',
      status: json['status'] ?? 'In Progress',
      xpReward: json['xpReward'] ?? 0,
      startDate: json['startDate'] ?? 'Date not set',
      endDate: json['endDate'] ?? 'Date not set',
      timeRemaining: json['timeRemaining'] ?? '? days',
      questImageUrl:
          json['questImageUrl'] ?? 'assets/images/quest_images/quest_1.png',
    );
  }

  // add copywith method for quest comp
  Quest copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    int? xpReward,
    String? startDate,
    String? endDate,
    String? timeRemaining,
    String? questImageUrl,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      xpReward: xpReward ?? this.xpReward,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      questImageUrl: questImageUrl ?? this.questImageUrl,
    );
  }
}

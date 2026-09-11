import 'package:flutter/foundation.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/storage.dart';

/// Holds the quest list, persists every change and notifies listeners.
class QuestListProvider with ChangeNotifier {
  QuestListProvider({QuestStorage? storage}) : _storage = storage;

  final QuestStorage? _storage;

  /// Storage used for persistence; defaults to [StorageService.instance].
  QuestStorage get storage => _storage ?? StorageService.instance;

  final List<Quest> _quests = [];

  /// Quest currently being edited on the create/edit page, if any.
  Quest? selectedQuest;

  /// Read-only view of all quests.
  List<Quest> get quests => List.unmodifiable(_quests);

  List<Quest> get inProgressQuests =>
      getFilteredQuests(QuestStatus.inProgress);

  List<Quest> get completedQuests => getFilteredQuests(QuestStatus.completed);

  /// Nullable for reset.
  void setSelectedQuest(Quest? quest) {
    selectedQuest = quest;
    notifyListeners();
  }

  /// Returns the next free quest id: (highest existing id) + 1, or 1 when
  /// the list is empty. Derived from the loaded list; nothing extra is stored.
  int nextQuestId() {
    if (_quests.isEmpty) return 1;
    return _quests.map((q) => q.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  Quest? questById(int id) {
    for (final quest in _quests) {
      if (quest.id == id) return quest;
    }
    return null;
  }

  Future<void> addQuest(Quest quest) async {
    _quests.add(quest);
    notifyListeners();
    await saveQuestsToStorage();
  }

  Future<void> removeQuest(Quest quest) => removeQuestById(quest.id);

  Future<void> removeQuestById(int id) async {
    final before = _quests.length;
    _quests.removeWhere((q) => q.id == id);
    if (_quests.length == before) return;
    notifyListeners();
    await saveQuestsToStorage();
  }

  /// Replaces the quest with the same id as [quest]. No-op if not found.
  Future<void> updateQuest(Quest quest) async {
    final index = _quests.indexWhere((q) => q.id == quest.id);
    if (index == -1) return;
    _quests[index] = quest;
    notifyListeners();
    await saveQuestsToStorage();
  }

  Future<void> updateQuestStatus(int questId, QuestStatus status) async {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index == -1) return;
    _quests[index] = _quests[index].copyWith(status: status);
    notifyListeners();
    await saveQuestsToStorage();
  }

  Future<void> markQuestCompleted(Quest quest) =>
      updateQuestStatus(quest.id, QuestStatus.completed);

  /// Quests with [filterStatus], or all quests when it is `null`.
  List<Quest> getFilteredQuests(QuestStatus? filterStatus) {
    if (filterStatus == null) return quests;
    return _quests.where((quest) => quest.status == filterStatus).toList();
  }

  Future<void> loadQuestsFromStorage() async {
    final loadedQuests = await storage.loadQuests();
    _quests
      ..clear()
      ..addAll(loadedQuests);
    notifyListeners();
  }

  Future<void> saveQuestsToStorage() => storage.saveQuests(_quests);
}

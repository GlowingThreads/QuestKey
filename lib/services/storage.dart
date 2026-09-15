// Persistence for quests, the hero and the day's encounter.
//
// Everything lives in `shared_preferences` as JSON strings. Writes keep the
// previous good copy of each record under a `.backup` key, and reads fall
// back to it when the primary copy cannot be parsed, so one bad write can
// never cost the player their hero. A record that fails to parse is moved
// aside under a `.corrupt` key rather than overwritten.
import 'dart:convert';

import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage contract for quests and the hero.
///
/// The app uses [SharedPrefsQuestStorage]; tests can inject an in-memory
/// implementation (see `InMemoryQuestStorage`).
abstract class QuestStorage {
  Future<void> saveQuests(List<Quest> quests);
  Future<List<Quest>> loadQuests();
  Future<void> deleteQuest(Quest quest);
  Future<void> saveHero(HeroCharacter hero);
  Future<HeroCharacter?> loadHero();

  /// Today's encounter state as a JSON map (`null` when none is stored).
  Future<Map<String, dynamic>?> loadEncounter();
  Future<void> saveEncounter(Map<String, dynamic>? json);
  Future<void> clearAllData();
}

/// [QuestStorage] backed by `shared_preferences`.
class SharedPrefsQuestStorage implements QuestStorage {
  static const String questsKey = 'quests';
  static const String heroKey = 'hero';
  static const String heroExistsKey = 'heroExists';
  static const String encounterKey = 'encounter';

  static const String backupSuffix = '.backup';
  static const String corruptSuffix = '.corrupt';

  /// Writes [value] under [key], keeping the previous value as the backup
  /// when it still parses (so a bad primary never displaces a good backup).
  Future<void> _write(
    SharedPreferences prefs,
    String key,
    String value,
    bool Function(String raw) parses,
  ) async {
    final previous = prefs.getString(key);
    if (previous != null && previous != value && parses(previous)) {
      await prefs.setString('$key$backupSuffix', previous);
    }
    await prefs.setString(key, value);
  }

  /// Reads [key], falling back to its backup. A primary that fails to parse
  /// is preserved under the corrupt key. Returns `null` when nothing usable
  /// is stored.
  Future<T?> _read<T>(
    SharedPreferences prefs,
    String key,
    T? Function(String raw) parse,
  ) async {
    final raw = prefs.getString(key);
    if (raw != null) {
      final value = parse(raw);
      if (value != null) return value;
      await prefs.setString('$key$corruptSuffix', raw);
    }
    final backup = prefs.getString('$key$backupSuffix');
    if (backup != null) {
      final value = parse(backup);
      if (value != null) return value;
    }
    return null;
  }

  static List<Quest>? _parseQuests(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((quest) => Quest.fromJson(Map<String, dynamic>.from(quest)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static HeroCharacter? _parseHero(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      return HeroCharacter.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveQuests(List<Quest> quests) async {
    final prefs = await SharedPreferences.getInstance();
    final questListJson = jsonEncode(
      quests.map((quest) => quest.toJson()).toList(),
    );
    await _write(
      prefs,
      questsKey,
      questListJson,
      (raw) => _parseQuests(raw) != null,
    );
  }

  @override
  Future<List<Quest>> loadQuests() async {
    final prefs = await SharedPreferences.getInstance();
    return await _read(prefs, questsKey, _parseQuests) ?? [];
  }

  @override
  Future<void> deleteQuest(Quest quest) async {
    final currentQuests = await loadQuests();
    currentQuests.removeWhere((q) => q.id == quest.id);
    await saveQuests(currentQuests);
  }

  @override
  Future<void> saveHero(HeroCharacter hero) async {
    final prefs = await SharedPreferences.getInstance();
    await _write(
      prefs,
      heroKey,
      jsonEncode(hero.toJson()),
      (raw) => _parseHero(raw) != null,
    );
    await prefs.setBool(heroExistsKey, true);
  }

  @override
  Future<HeroCharacter?> loadHero() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs, heroKey, _parseHero);
  }

  @override
  Future<Map<String, dynamic>?> loadEncounter() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(encounterKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveEncounter(Map<String, dynamic>? json) async {
    final prefs = await SharedPreferences.getInstance();
    if (json == null) {
      await prefs.remove(encounterKey);
    } else {
      await prefs.setString(encounterKey, jsonEncode(json));
    }
  }

  /// Erases everything, including backups and corrupt copies.
  @override
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [heroKey, questsKey]) {
      await prefs.remove(key);
      await prefs.remove('$key$backupSuffix');
      await prefs.remove('$key$corruptSuffix');
    }
    await prefs.remove(encounterKey);
    await prefs.setBool(heroExistsKey, false);
  }
}

/// Export and import of a complete save as one JSON document, so players
/// can move between devices or keep their own copy.
class SaveCodex {
  const SaveCodex(this.storage);

  static const String format = 'questkey-save';
  static const int version = 1;

  final QuestStorage storage;

  /// The whole save as pretty JSON.
  Future<String> export({DateTime? now}) async {
    final hero = await storage.loadHero();
    final quests = await storage.loadQuests();
    final encounter = await storage.loadEncounter();
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'hero': hero?.toJson(),
      'quests': quests.map((q) => q.toJson()).toList(),
      'encounter': encounter,
    });
  }

  /// Parses [text] without writing anything. Throws [FormatException] with
  /// a player-readable message when it is not a usable save.
  static ({
    HeroCharacter? hero,
    List<Quest> quests,
    Map<String, dynamic>? encounter,
  })
  parse(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text.trim());
    } on FormatException {
      throw const FormatException('That is not a Quest Key save.');
    }
    if (decoded is! Map || decoded['format'] != format) {
      throw const FormatException('That is not a Quest Key save.');
    }
    final version = decoded['version'];
    if (version is! num || version > SaveCodex.version) {
      throw const FormatException(
        'This save comes from a newer version of Quest Key.',
      );
    }

    HeroCharacter? hero;
    final heroJson = decoded['hero'];
    if (heroJson is Map) {
      try {
        hero = HeroCharacter.fromJson(Map<String, dynamic>.from(heroJson));
      } catch (_) {
        throw const FormatException('The hero in this save is damaged.');
      }
    }

    final questsJson = decoded['quests'];
    final quests = <Quest>[];
    if (questsJson is List) {
      for (final q in questsJson) {
        if (q is! Map) continue;
        try {
          quests.add(Quest.fromJson(Map<String, dynamic>.from(q)));
        } catch (_) {
          throw const FormatException('A quest in this save is damaged.');
        }
      }
    }

    final encounterJson = decoded['encounter'];
    return (
      hero: hero,
      quests: quests,
      encounter:
          encounterJson is Map
              ? Map<String, dynamic>.from(encounterJson)
              : null,
    );
  }

  /// Validates [text] and replaces the stored save with it. Nothing is
  /// written unless the whole document parses.
  Future<void> import(String text) async {
    final save = parse(text);
    final hero = save.hero;
    if (hero != null) await storage.saveHero(hero);
    await storage.saveQuests(save.quests);
    await storage.saveEncounter(save.encounter);
  }
}

/// Static-style facade over [StorageService.instance].
///
/// Existing call sites keep working unchanged; tests can swap the backing
/// implementation with `StorageService.instance = InMemoryQuestStorage()`.
class StorageService {
  StorageService._();

  /// The storage implementation used by the static helpers below and, by
  /// default, by the providers.
  static QuestStorage instance = SharedPrefsQuestStorage();

  static Future<void> saveQuests(List<Quest> quests) =>
      instance.saveQuests(quests);

  static Future<List<Quest>> loadQuests() => instance.loadQuests();

  static Future<void> deleteQuest(Quest quest) => instance.deleteQuest(quest);

  static Future<void> saveHero(HeroCharacter hero) => instance.saveHero(hero);

  static Future<HeroCharacter?> loadHero() => instance.loadHero();

  static Future<void> clearAllData() => instance.clearAllData();
}

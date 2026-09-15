import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/heroes.dart';

/// Persistence safety: backups, corrupt data and the save codex.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storage = SharedPrefsQuestStorage();
  final now = DateTime(2030, 6, 1, 12);

  Quest quest(int id) =>
      Quest(id: id, title: 'Q$id', description: 'd', dueDate: now);

  group('backups', () {
    test('saving rotates the previous good copy into the backup', () async {
      SharedPreferences.setMockInitialValues({});
      await storage.saveHero(makeHero().copyWith(name: 'First'));
      await storage.saveHero(makeHero().copyWith(name: 'Second'));
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('hero')!)['name'], 'Second');
      expect(jsonDecode(prefs.getString('hero.backup')!)['name'], 'First');
    });

    test('a corrupt primary falls back to the backup and is kept', () async {
      final good = jsonEncode(makeHero().copyWith(name: 'Kept').toJson());
      SharedPreferences.setMockInitialValues({
        'hero': '{"name": "trunc',
        'hero.backup': good,
      });
      final hero = await storage.loadHero();
      expect(hero!.name, 'Kept');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('hero.corrupt'), '{"name": "trunc');
    });

    test('a wrong-typed hero never throws', () async {
      SharedPreferences.setMockInitialValues({
        'hero': jsonEncode({'name': 5, 'classes': 'not a map'}),
      });
      expect(await storage.loadHero(), isNull);
    });

    test('a bad primary never displaces a good backup on save', () async {
      final good = jsonEncode(makeHero().copyWith(name: 'Kept').toJson());
      SharedPreferences.setMockInitialValues({
        'hero': 'garbage',
        'hero.backup': good,
      });
      await storage.saveHero(makeHero().copyWith(name: 'New'));
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('hero.backup')!)['name'], 'Kept');
      expect((await storage.loadHero())!.name, 'New');
    });

    test('quests fall back to their backup too', () async {
      SharedPreferences.setMockInitialValues({
        'quests': '[{"id": 1, "title": ',
        'quests.backup': jsonEncode([quest(1).toJson(), quest(2).toJson()]),
      });
      expect((await storage.loadQuests()).map((q) => q.id), [1, 2]);
    });

    test('clearAllData removes backups and corrupt copies', () async {
      SharedPreferences.setMockInitialValues({
        'hero': 'x',
        'hero.backup': 'y',
        'hero.corrupt': 'z',
        'quests': '[]',
        'quests.backup': '[]',
      });
      await storage.clearAllData();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((k) => k != 'heroExists'), isEmpty);
    });
  });

  group('save codex', () {
    test('export and import round-trip the whole save', () async {
      final source = InMemoryQuestStorage();
      await source.saveHero(makeHero().copyWith(name: 'Isolde'));
      await source.saveQuests([quest(1), quest(2)]);
      await source.saveEncounter({'templateId': 'courier'});
      final text = await SaveCodex(source).export(now: now);
      expect(text, contains('"format": "questkey-save"'));

      final target = InMemoryQuestStorage();
      await SaveCodex(target).import(text);
      expect((await target.loadHero())!.name, 'Isolde');
      expect((await target.loadQuests()).length, 2);
      expect((await target.loadEncounter())!['templateId'], 'courier');
    });

    test('garbage and foreign documents are refused untouched', () async {
      final target = InMemoryQuestStorage();
      await target.saveHero(makeHero().copyWith(name: 'Untouched'));
      final codex = SaveCodex(target);
      expect(() => codex.import('not json'), throwsFormatException);
      expect(() => codex.import('{"format": "other"}'), throwsFormatException);
      expect(
        () => codex.import(
          '{"format": "questkey-save", "version": 99, "hero": null}',
        ),
        throwsFormatException,
      );
      expect(
        () => codex.import(
          '{"format": "questkey-save", "version": 1, "hero": {"name": 3, "classes": 1}}',
        ),
        throwsFormatException,
      );
      expect((await target.loadHero())!.name, 'Untouched');
    });
  });
}

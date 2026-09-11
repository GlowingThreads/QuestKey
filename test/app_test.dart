import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/level_up.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  HeroCharacter makeHero({LevelUp levelUp = const LevelUp(statPoints: 3)}) {
    return HeroCharacter(
      name: 'TestHero',
      motto: 'To glory!',
      classes: fighter,
      description: 'A brave fighter',
      imageUrl: '',
      levelUp: levelUp,
    );
  }

  test('Creating and saving hero should update AppState', () async {
    final storage = InMemoryQuestStorage();
    final appState = AppState(storage: storage);

    await appState.saveHero(makeHero());

    expect(appState.hero, isNotNull);
    expect(appState.hero!.name, equals('TestHero'));
    expect(appState.hero!.levelUp.level, equals(1));
    expect(storage.heroSaveCount, 1);
    expect((await storage.loadHero())!.name, 'TestHero');
  });

  test('completeQuestForHero awards XP, counts the quest and persists',
      () async {
    final storage = InMemoryQuestStorage();
    final appState = AppState(storage: storage);
    await appState.saveHero(
      makeHero(levelUp: const LevelUp(level: 1, exp: 10, maxExp: 100)),
    );

    final leveledUp = await appState.completeQuestForHero(50);

    expect(leveledUp, isFalse);
    expect(appState.lastCompletionLeveledUp, isFalse);
    expect(appState.hero!.levelUp.exp, 60);
    expect(appState.hero!.questsCompleted, 1);
    expect((await storage.loadHero())!.levelUp.exp, 60);
  });

  test('completeQuestForHero reports a level up', () async {
    final appState = AppState(storage: InMemoryQuestStorage());
    await appState.saveHero(
      makeHero(levelUp: const LevelUp(level: 1, exp: 90, maxExp: 100)),
    );

    final leveledUp = await appState.completeQuestForHero(50);

    expect(leveledUp, isTrue);
    expect(appState.lastCompletionLeveledUp, isTrue);
    expect(appState.hero!.levelUp.level, 2);
    expect(appState.hero!.levelUp.exp, 40);
  });

  test('completeQuestForHero without a hero is a no-op', () async {
    final appState = AppState(storage: InMemoryQuestStorage());
    expect(await appState.completeQuestForHero(50), isFalse);
    expect(appState.hero, isNull);
  });

  test('clearHero forgets the hero', () async {
    final appState = AppState(storage: InMemoryQuestStorage());
    await appState.saveHero(makeHero());
    appState.clearHero();
    expect(appState.hero, isNull);
  });
}

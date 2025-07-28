import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/models/character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Creating and saving hero should update AppState', () {
    final appState = AppState();

    final newHero = HeroCharacter(
      name: 'TestHero',
      motto: 'To glory!',
      classes: fighter,
      description: 'A brave fighter',
      imageUrl: '',
      levelUp: LevelUp(level: 1, exp: 0, maxExp: 100, statPoints: 3),
    );

    appState.saveHero(newHero);

    expect(appState.hero, isNotNull);
    expect(appState.hero!.name, equals('TestHero'));
    expect(appState.hero!.levelUp.level, equals(1));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/widgets/familiar/familiar_behaviour.dart';
import 'package:quest_key/widgets/familiar/sprite_sheet.dart';

void main() {
  test('a manifest parses rows, frames and fallbacks', () {
    final m = SpriteSheetManifest.parse('''
      {"frameWidth": 32, "frameHeight": 32, "fps": 6, "facing": "left",
       "animations": {
         "idle": {"row": 0, "frames": 4},
         "walk": {"row": 1, "frames": 6, "fps": 10, "start": 2},
         "sleep": {"row": 3, "frames": 2, "loop": false}
       }}
    ''');
    expect(m.frameWidth, 32);
    expect(m.facesRight, isFalse);
    expect(m.animations['walk']!.fps, 10);
    expect(m.animations['walk']!.start, 2);
    expect(m.animations['idle']!.fps, 6);
    expect(m.animations['sleep']!.loop, isFalse);
    // Fallbacks: groom borrows sit, then idle; hop borrows walk.
    expect(m.animationFor(FamiliarAction.groom), same(m.animations['idle']));
    expect(m.animationFor(FamiliarAction.hop), same(m.animations['walk']));
    expect(m.animationFor(FamiliarAction.sleep), same(m.animations['sleep']));
  });

  test('bad manifests are refused', () {
    expect(() => SpriteSheetManifest.parse('[]'), throwsFormatException);
    expect(
      () => SpriteSheetManifest.parse('{"frameWidth": 0, "frameHeight": 8}'),
      throwsFormatException,
    );
    expect(
      () => SpriteSheetManifest.parse(
        '{"frameWidth": 8, "frameHeight": 8, "animations": {"x": {"row": 0}}}',
      ),
      throwsFormatException,
    );
  });

  test('a missing sheet loads as null rather than throwing', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await SpriteSheet.load('cat'), isNull);
  });
}

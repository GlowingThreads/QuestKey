import 'package:flutter_test/flutter_test.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/familiar.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/rewards.dart';
import 'package:quest_key/services/in_memory_quest_storage.dart';
import 'package:quest_key/state/app_state.dart';

import 'helpers/heroes.dart';

void main() {
  final now = DateTime(2030, 6, 1, 12);

  Familiar cat({int bond = 0}) => Familiar(
    species: FamiliarSpecies.cat,
    name: 'Nyx',
    adoptedOn: now,
    bond: bond,
  );

  Quest quest(int id) =>
      Quest(id: id, title: 'Q', description: 'd', dueDate: now);

  test('bond tiers and bonus', () {
    expect(cat().tierTitle, 'Stray');
    expect(cat().bonusPercent, 0);
    expect(cat(bond: 10).tierTitle, 'Companion');
    expect(cat(bond: 10).bonusPercent, 2);
    expect(cat(bond: 29).tier, 1);
    expect(cat(bond: 30).tierTitle, 'Bonded');
    expect(cat(bond: 60).isSoulbound, isTrue);
    expect(cat(bond: 60).nextTierBond, isNull);
    expect(cat(bond: 5).tierProgress, 0.5);
  });

  test('every quest completion deepens the bond', () {
    final hero = makeHero().copyWith(familiar: cat());
    final after = hero.recordQuestCompletion(now, quest: quest(1));
    expect(after.familiar!.bond, 1);
    expect(
      makeHero().recordQuestCompletion(now).familiar,
      isNull,
      reason: 'no familiar, nothing to bond',
    );
  });

  test('a bonded familiar lends XP with its name on the line', () {
    final hero = makeHero().copyWith(familiar: cat(bond: 30));
    final r = computeReward(hero, quest(1), now: now, roll: 0.99);
    expect(r.lines.single.label, 'Nyx');
    expect(r.total, 52);
    final stray = makeHero().copyWith(familiar: cat());
    expect(computeReward(stray, quest(1), now: now, roll: 0.99).lines, isEmpty);
  });

  test('mood follows the torch, the day and the streak', () {
    final hero = makeHero(restedOn: now, lastCompletedOn: now, streak: 5);
    expect(
      familiarMoodFor(hero.copyWith(health: 10), now: now, completedToday: 1),
      FamiliarMood.sleepy,
    );
    expect(
      familiarMoodFor(hero, now: now, completedToday: 0),
      FamiliarMood.watchful,
    );
    expect(
      familiarMoodFor(hero, now: now, completedToday: 1),
      FamiliarMood.joyful,
    );
    expect(
      familiarMoodFor(
        hero.copyWith(currentStreak: 1),
        now: now,
        completedToday: 1,
      ),
      FamiliarMood.content,
    );
    for (final species in FamiliarSpecies.values) {
      for (final mood in FamiliarMood.values) {
        final f = Familiar(species: species, name: 'X', adoptedOn: now);
        expect(familiarLine(f, mood), contains('X'));
      }
    }
  });

  test('JSON round trip and legacy defaults', () {
    final hero = makeHero().copyWith(familiar: cat(bond: 3));
    final back = HeroCharacter.fromJson(hero.toJson());
    expect(back.familiar, cat(bond: 3));
    final legacy = hero.toJson()..remove('familiar');
    expect(HeroCharacter.fromJson(legacy).familiar, isNull);
    expect(
      Familiar.fromJson({'species': 'dragon', 'name': 'x'}),
      isNull,
      reason: 'unknown species is dropped, not crashed on',
    );
    expect(Familiar.fromJson({'species': 'owl', 'name': '  '})!.name, 'Owl');
  });

  test('adopting, petting and Soulbound honours', () async {
    final storage = InMemoryQuestStorage();
    final state = AppState(storage: storage, now: () => now, roll: () => 0.99);
    await state.saveHero(makeHero());
    final unlocked = await state.adoptFamiliar(FamiliarSpecies.hound, '  ');
    expect(state.hero!.familiar!.name, 'Hound');
    expect(unlocked.map((a) => a.id), contains('hearth_friend'));
    expect(await state.petFamiliar(), contains('Hound'));
    expect(state.hero!.familiar!.timesPetted, 1);
    expect((await storage.loadHero())!.familiar!.timesPetted, 1);

    final soul = await state.updateHero(
      (h) => h.copyWith(familiar: h.familiar!.copyWith(bond: 60)),
    );
    expect(soul.map((a) => a.id), contains('kindred'));
  });
}

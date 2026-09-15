# Quest Key: gameplay and UX features

## The den (Phase 12): a familiar that lives, not just blinks

**Behaviour** (`lib/widgets/familiar/familiar_behaviour.dart`). A small
stochastic state machine chooses what the familiar does: idle, walk to a
random spot, sit, sleep (with drifting Zs), groom, stretch, hop. The mood
tilts the odds (sleepy familiars mostly sleep; joyful ones never do, and
hop on their own). It never walks twice in a row and always does something
on arrival. Taps and completed quests startle it into a hop. Pure Dart,
tested with a seeded random.

**The den** (`familiar_stage.dart`). The hearth panel is now a wide box
with a warm glow at the fireside and a floor rule; a ticker advances the
behaviour and places the creature along the floor, mirrored when it faces
left, with a shadow that shrinks as it hops.

**Renderers** (`familiar_sprite.dart`), chosen per species at start-up:

1. **Sprite sheet**: `<species>.png` plus a JSON manifest naming each
   animation's row, frame count, speed and facing (`sprite_sheet.dart`).
   Missing animations borrow from others so a pack with only idle, walk
   and sleep still looks right. Pixel art is drawn without smoothing.
2. **Rive**: `<species>.riv` with a `Familiar` state machine and optional
   `action`, `walking`, `mood`, `facingLeft` and `hop` inputs
   (`rive_familiar.dart`), on the pure-Dart `rive` 0.13 runtime. The
   0.14 line was tried first and does not compile against the pinned
   Flutter 3.29, so stay on 0.13 until the Flutter pin moves.
3. **Painter**: the built-in shadow creatures, now with walk (leg swing,
   bob, lean), sleep (lying, eyes shut), groom (head dip, paw up) and
   stretch poses, plus a fourth species, the **weasel**, drawn in profile.

`assets/REQUIRED_ASSETS.md` lists free packs for each species and the exact
manifest format.

## Familiars and the Save Codex (Phase 11)

**Familiars** (`lib/models/familiar.dart`, `lib/widgets/familiar/`). The
hearth on the Home tab shows a stray until one is adopted: a shadow cat,
hound or owl with a name. It is drawn procedurally (`FamiliarSprite`) with
an idle loop (breathing, blinks, tail swish or wag, ear twitch, head tilt),
a hop on tap and on every quest completion, and a mood read from the hero
each time it is drawn: sleepy when the torch is low, watchful before the
first quest of the day, content after one, joyful on a strong streak with a
full torch. Each mood has a line per species. Every completed quest deepens
the bond: Stray → Companion (10) → Bonded (30) → Soulbound (60), lending
+2/4/6% XP on every quest with the familiar's name on the reward line. Two
honours: Hearth Friend (adopt) and Kindred Spirit (Soulbound). A sprite
strip at `assets/images/familiars/<species>.png` replaces the painter (see
`assets/REQUIRED_ASSETS.md`). Stored inside the hero JSON as `familiar`;
older saves load without one.

**Save safety** (`lib/services/storage.dart`). Every change is still written
immediately to `shared_preferences`, and now:

- each write keeps the previous good copy under `hero.backup` /
  `quests.backup`, and a primary that no longer parses is skipped in favour
  of the backup (the bad copy is preserved under `.corrupt`, never
  overwritten);
- parsing catches every error, not only `FormatException`, so a wrong-typed
  field can no longer crash the app before its first frame;
- a bad primary never displaces a good backup on the next save;
- `android:allowBackup="true"` is explicit, so the save rides Android Auto
  Backup across reinstalls on the same account.

**Attribute sigil.** `StatRadar` is now a magic circle: bronze rings with
runic ticks and a band of seeded glyph script that turn slowly against each
other on the Hero page, a faint heptagram binding the seven axes, seal
nodes on the outer ring carrying the attribute abbreviations, and the
hero's values as a glowing gradient shape with gem nodes over the class
baseline in bronze.

**Save Codex** (Guide tab). *Copy save* puts the whole save (hero, quests,
encounter) on the clipboard as one JSON document; *Restore save* pastes one
back after validating it in full. Nothing is written unless the document
parses. `test/storage_test.dart` covers rotation, fallback, corrupt and
wrong-typed data, and the codex round trip.

## The wider grimoire (Phase 10)

**Nineteen skills** (`lib/models/character_skill.dart`), grouped into four
schools in the grimoire: Martial Arts, Arcana, Craft and Disciplines. The
original eight keep their ids, so saved heroes load unchanged.

New active spells (`lib/models/spells.dart`, executed in
`lib/state/spellbook.dart`):

| Skill | Cost | Effect |
| --- | --- | --- |
| Meditate | 15 STA | Restore 35% of max MP |
| Second Wind (Rally) | 15 MP | Restore 40% of max STA |
| Enchant | 20 MP | Target quest pays +25% XP on completion (once per quest) |
| Battle Cry (Roar) | 20 STA | Rallied: +15% XP on every quest until midnight; not consumed |
| Chronoshift (Shift) | 20 MP | Target quest's due date moves two days later, stays visible |
| Foresight (Foresee) | 40 MP | Next completion is a guaranteed critical (×2) |
| Berserk (Rage) | 30 STA + 10% HP | Next Epic quest today pays +100% XP |
| Divine Favour (Pray) | 45 MP | Torch to full HP and one shield charge |

Passive disciplines have no spell; they change a rule permanently once
learned and are listed on the Attribute Sigil panel:

| Discipline | Effect |
| --- | --- |
| Scholar's Focus | +10% XP on Study and Creative quests |
| Iron Will | A missed day burns 15% of the torch instead of 25% |
| Keen Edge | +5% critical chance |

`Quest.enchantPercent` is a new, backward-compatible field (default 0).
`BuffType` gains `rallied`, `foresight` and `berserk`; `rallied` persists
through completions. The completion summary reads `FORESEEN ×2` when
Foresight, not the dice, made the critical.

**Thirty-eight honours** (`lib/models/character_achievement.dart`) in four
halls: The Road (progress), Trials (challenge), Mastery and Wayfaring. New:
Kindling (3-day streak), Adept (level 5), Seasoned (50 quests), Centurion
(100), Champion (level 20), Heraldry (wear a title), Eternal Flame (30-day
streak), Dragonheart (an Epic quest), Clockwork (10 on-time completions),
Blessed by Fortune (10 criticals), Dragonslayer (5 bosses), Bulwark (three
shield charges), Paragon (10 in every attribute), Apprentice (first skill),
Grand Magus (100 spells), Gilded Hand (complete an enchanted quest),
Loremaster (every skill), Wayfarer (10 encounters), Well Travelled (a quest
in every category), plus hidden Dawn Patrol (5–7 am), Weekend Warrior (3
quests on a weekend day) and From the Ashes (lose the flame). The hero now
records `onTimeCompletions` and `categoriesCompleted`; the daily rest passes
`flameWentOut` to the rules. Learning a skill and wearing a title now
evaluate honours too.

**Visual elements** (`lib/widgets/common/sigils.dart`,
`lib/widgets/spell_flash.dart`):

- `WaxSeal`: scalloped, embossed seal coloured by rarity; locked honours are
  unpressed grey wax, the worn title glows. `RarityPips` read Common to
  Legendary under each seal and in the unlock dialog.
- `ArcaneCircle`: concentric runic rings with a hexagram that slowly turn
  behind learned and castable spells, and hold still when they cannot be
  cast.
- `TorchFlame`: a flickering flame beside the torch bar on the hero card and
  in the rest banner; its height and colour follow HP (gold when full, low
  and red when dying).
- `showSpellFlash`: on every cast a runic ring expands over the screen with
  the spell's incantation ("Ash keeps no debts.") in the school's colour.
- The grimoire and Hall of Honours are grouped under school and hall
  headers with per-group counts and an overall progress bar.

## Game mechanics (Phase 9): skills and honours now do things

**Resources.** HP, MP and Stamina are pools, not decorations. Maximums grow
with level (`maxHealthFor` etc. in `character.dart`). MP and Stamina refill
every dawn; every completed quest restores 10% of each pool.

**Spells** (`lib/models/spells.dart`, executed by `lib/state/spellbook.dart`).
Each of the eight skills maps to a spell with a cost, a target and an effect.
Cast from a quest tile (wand icon or long press) or from the grimoire:

| Skill | Cost | Effect |
| --- | --- | --- |
| Power Strike (Empower) | 15 STA | Next Hard/Epic quest today pays +50% XP |
| Swift Strike (Hasten) | 10 STA | Next quest finished within an hour pays +25% |
| Fireball (Burn) | 25 MP | Removes a quest, keeps a third of its XP |
| Heal (Mend) | 20 MP | Overdue quest becomes due tomorrow; torch +30% HP |
| Stealth (Snooze) | 10 STA | Quest moves a day later and hides from Home until tomorrow |
| Shield Bash (Bulwark) | 12 STA | +1 shield charge (max 3) |
| Mana Shield (Ward) | 30 MP | +2 shield charges |
| Whirlwind (Sweep) | 35 STA | Completes every Trivial quest at once, +10% |

Proficiency rises one level per five casts (max 3) and cuts the cost 15% per
level.

**Rewards** (`lib/models/rewards.dart`). XP = base × (1 + affinity + buffs +
encounter bonus + boss bonus), doubled on a critical. Affinity: each point of
the category's attribute above 4 adds 3% (Strength→Health, Dexterity→Work,
Intelligence→Study, Wisdom→Creative, Charisma→Social, Constitution→Home,
Luck→Adventure), capped at 45%. Critical chance = Luck × 2.5% (max 35%).
The completion toast shows the breakdown.

**The torch** (`HeroCharacter.rest`). On each new day, every day since the
last rest with no completed quest burns 25% of max HP; shield charges absorb
one day each. If HP reaches zero the flame goes out (streak resets, torch
relights at a quarter). A streak now survives a missed day as long as the
torch is lit. The Home tab reports what happened while you were away.

**Encounters** (`lib/models/encounter.dart`, `EncounterProvider`). Most days a
short story appears on Home, chosen deterministically from the date, hero
level and class. Accept it for a bonus quest (+50–80% XP), walk on, slip
past with Stealth (+25 XP) or confront it with Fireball (Luck roll: +120 XP
or torch damage).

**Boss quests.** Any quest can carry steps (added on the forge). Steps are
ticked on the tile; the quest completes only when all are done and pays
+25%.

**Titles.** Tap an unlocked honour on the Hero tab to wear it: "Isolde Vane,
the Night Owl". Six new honours: Spellweaver, Archmage, Fortune's Favourite,
Trailblazer, Giant Slayer, Torch Bearer.

All of this is local; existing saves load unchanged (new fields default and
the rest clock starts on first launch without damage).


## Art-directed UI (Phase 8)

Built on the committed artwork instead of emoji and stock Material chips:

- Palette from the illustrations (obsidian, amethyst, bronze, teal gems,
  gold) in `lib/constants/app_colors.dart`; bundled OFL fonts, Cinzel for
  display and Spectral for reading text (`assets/fonts`, `AppFonts`).
- `lib/widgets/common/ui_kit.dart`: `ArcanePanel` (bronze double frame with
  gem-set corner brackets), `GemRing`, `RuneTag`, `RuneDivider`,
  `PortholeBadge` (the hand-lettered badge art), `FramedPortrait`,
  `ManaOrb` (level + XP ring), `StatRadar` (seven-axis attribute sigil),
  `AnimatedBar`, `QuestButton`, `PageBackground` with vignette.
- `lib/theme/iconography.dart` maps categories, origins, skills and
  achievements to icons and the badge/background art paths.
- Nav bar uses the porthole badges as the tabs (their art carries the
  labels). Level-up uses the gold arrow with a rotating sunburst; quest
  completion releases golden embers; the class step of the hero wizard
  shows the class glyph tiles and a radar of starting attributes.
- Skills and achievements are still cosmetic: see the roadmap discussion in
  the pull request for the planned mana / spell mechanics.


## UI upgrade (Phase 7)

- **Shared theme** (`lib/theme/app_theme.dart`): one dark-fantasy palette,
  input/chip/button/snackbar styling and page transitions for the whole app.
  `lib/widgets/common/ui_kit.dart` holds the building blocks: `GlassPanel`
  (frosted cards), `FadeSlideIn` (staggered entrance), `PulseGlow`,
  `AnimatedBar`, `AnimatedCount`, `QuestButton` (press-to-shrink gradient
  CTA) and `PageBackground` (asset with gradient fallback).
- **Hero creation is its own page** (`lib/pages/hero_creation_page.dart`):
  a five-step wizard (Identity → Class → Origin → Avatar → Summon) with a
  step bar, slide transitions, class cards with animated stat bars, the
  previously unused **origins** (`backgroundsList`) applying their stat
  bonuses, a portrait grid, a summon preview and confetti. It is shown
  automatically as onboarding when no hero exists and from the Guide tab to
  replace a hero.
- **Quest forge** (`lib/pages/create_quest.dart`): sectioned form with
  quick-start templates, category chips, a five-star difficulty picker with
  live XP label, a due-date card with "Today 6 pm / Tomorrow 9 am / In a
  week" chips, a reminder switch and a **live preview** of the quest tile.
- **Home**: time-of-day greeting, open-quest count, animated counters and
  staggered entrance. **Quest Log**: completion bar, sliding segmented
  filter with counts, full-height list and a "New quest" FAB. **Hero**:
  glowing portrait, class/origin/level tags, animated HP/MP/Stamina bars and
  a stat-points banner. **Guide**: illustrated how-to cards, hero
  management and a danger zone.
- Nav bar: sliding highlight, scale and haptic feedback, icon fallbacks when
  the PNGs are missing. Level-up popup bounces in with a glow.

## Gameplay loop (Phase 6)

Everything below is local-only, needs no new image assets, and is covered by
unit/widget tests under `test/`.

## Quests

- **Categories.** Every quest has a `QuestCategory` (Health, Work, Study,
  Home, Social, Creative, Adventure, Other) chosen with chips on the create
  page. The tile shows the category emoji in a coloured badge, so quests are
  visually distinct without per-quest images. Legacy quests load as *Other*.
- **Due-date chips.** Tiles show time remaining ("2 days, 3 hrs"), turn amber
  on the due day and red with a red border when overdue. Difficulty shows as
  ★ stars with the XP reward.
- **Sorting.** In-progress quests are ordered by due date (soonest first);
  completed quests by completion time (latest first). The "All" view lists
  in-progress before completed.
- **Quick start.** One-tap templates (Drink water, Exercise, Read, Tidy up,
  Reach out, Unwind) fill in title, description and category. "Today 6 pm" /
  "Tomorrow 9 am" chips set the due time without opening the pickers.
- **Safer actions.** Swipe left asks "Delete quest?" before removing. Swipe
  right (or the ✓ button on the tile) completes a quest on any list,
  including "All". The Quest Log filter tabs show counts.
- **Completion timestamps.** `Quest.completedAt` records when a quest was
  finished (drives "done today" and the Speedrunner achievement).

## Hero progression

- **Confetti + XP toast** on every completion; the existing level-up popup
  follows when a level is gained.
- **Achievements are live.** `lib/models/achievement_rules.dart` evaluates
  the predefined achievements after every quest completion and stat
  assignment: Quest Initiate, Leveled Up, Quest Master (10 quests), Veteran
  (level 10), Stat Allocator, Speedrunner (5 in a day), Perfectionist (10-day
  streak), Balanced Hero (all stats ≥ 5), Specialist (a stat ≥ 10) and the
  hidden **Night Owl** (complete a quest between midnight and 4 am). New
  unlocks pop up in a dialog. The Hero page's Achievements tab now shows all
  of them, locked ones dimmed and hidden ones as ???.
- **Skills can be learned.** The Skills tab lists every skill with its level
  and stat requirements ("Lv. 3 · dexterity 4/6") and a Learn button that
  enables once the hero qualifies. Spending stat points therefore has a goal.
- **Daily streak.** `HeroCharacter.currentStreak` / `longestStreak` track
  consecutive days with at least one completed quest. The Home tab shows a
  🔥 streak tile, ✅ quests done today, and either ⏰ overdue count or ⬆️ XP to
  the next level.
- **Quests completed** is finally incremented (it was always 0 before).

## Fixes from the code review

- Home no longer reloads hero and quests from storage every time the tab is
  opened (the spinner flash on each visit).
- XP and stat bars size themselves with `FractionallySizedBox` instead of
  screen-width arithmetic, so they are correct inside any parent.
- Info page text matched the real gestures ("Tap to edit", not long press),
  and "Create Hero" asks before replacing an existing hero.
- Missing image assets fall back to icons instead of throwing.
- Dead code removed: `CreateHeroWidget`, `StatPoints`, and the unused
  `crystal_navigation_bar` dependency.

## Ideas not done yet (from README wish-list)

- Sounds on level-up/completion (needs an audio package + asset).
- Editing hero name/motto/avatar after creation.
- Main/side quest lists or "Encounter" quests that unlock by class/level.

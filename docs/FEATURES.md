# Quest Key: gameplay and UX features

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

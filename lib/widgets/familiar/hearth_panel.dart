import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/familiar.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/widgets/achievement_unlocked_dialog.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/familiar/familiar_sprite.dart';

/// The hearth on the Home tab: the familiar, its mood and its bond, or the
/// stray waiting to be adopted.
class HearthPanel extends StatelessWidget {
  const HearthPanel({super.key, required this.hero});

  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final familiar = hero.familiar;
    if (familiar == null) return _StrayPanel(hero: hero);

    final now = DateTime.now();
    final completedToday = context.watch<QuestListProvider>().completedOn(now);
    final mood = familiarMoodFor(
      hero,
      now: now,
      completedToday: completedToday,
    );
    final next = familiar.nextTierBond;

    return ArcanePanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FamiliarSprite(
            species: familiar.species,
            mood: mood,
            size: 92,
            hopTrigger: hero.questsCompleted,
            onTap: () => _pet(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        familiar.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.heading(size: 16, letterSpacing: 0.6),
                      ),
                    ),
                    if (familiar.bonusPercent > 0)
                      RuneTag(
                        text: '+${familiar.bonusPercent}% XP',
                        color: AppColors.gold,
                        filled: true,
                      ),
                  ],
                ),
                Text(
                  'SHADOW ${familiar.species.label.toUpperCase()} · ${familiar.tierTitle.toUpperCase()}',
                  style: AppFonts.label(size: 9, color: AppColors.teal),
                ),
                const SizedBox(height: 5),
                Text(
                  familiarLine(familiar, mood),
                  style: AppFonts.body(
                    size: 12.5,
                    color: AppColors.inkMuted,
                    style: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedBar(
                        fraction: familiar.tierProgress,
                        height: 5,
                        colors: const [AppColors.amethyst, AppColors.magenta],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      next == null
                          ? 'BOND ${familiar.bond}'
                          : 'BOND ${familiar.bond}/$next',
                      style: AppFonts.label(size: 8, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final line = await context.read<AppState>().petFamiliar();
    if (line == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(line)));
  }
}

class _StrayPanel extends StatelessWidget {
  const _StrayPanel({required this.hero});

  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    return ArcanePanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const FamiliarSprite(
            species: FamiliarSpecies.cat,
            mood: FamiliarMood.watchful,
            size: 80,
            dimmed: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Hearth',
                  style: AppFonts.heading(size: 15, letterSpacing: 0.6),
                ),
                const SizedBox(height: 3),
                Text(
                  'Something watches from beyond the firelight. It has been '
                  'following you for days.',
                  style: AppFonts.body(
                    size: 12.5,
                    color: AppColors.inkMuted,
                    style: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                QuestButton(
                  label: 'Adopt a familiar',
                  icon: Icons.pets_rounded,
                  compact: true,
                  expand: false,
                  style: QuestButtonStyle.gold,
                  onPressed: () => showAdoptFamiliarDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the player pick a species and a name, then adopts.
Future<void> showAdoptFamiliarDialog(BuildContext context) async {
  final choice = await showDialog<(FamiliarSpecies, String)>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => const _AdoptDialog(),
  );
  if (choice == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final unlocked = await context.read<AppState>().adoptFamiliar(
    choice.$1,
    choice.$2,
  );
  final name =
      context.mounted ? context.read<AppState>().hero?.familiar?.name : null;
  messenger.showSnackBar(
    SnackBar(content: Text('${name ?? choice.$1.label} settles by the fire.')),
  );
  if (!context.mounted) return;
  await showAchievementsUnlocked(context, unlocked);
}

class _AdoptDialog extends StatefulWidget {
  const _AdoptDialog();

  @override
  State<_AdoptDialog> createState() => _AdoptDialogState();
}

class _AdoptDialogState extends State<_AdoptDialog> {
  FamiliarSpecies _species = FamiliarSpecies.cat;
  late final TextEditingController _name = TextEditingController(
    text: _randomName(FamiliarSpecies.cat),
  );

  static String _randomName(FamiliarSpecies species) {
    final names = familiarNames[species]!;
    return names[math.Random().nextInt(names.length)];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ArcanePanel(
        accent: AppColors.gold,
        glow: AppColors.amethystBright,
        fillOpacity: 0.97,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADOPT A FAMILIAR',
              style: AppFonts.heading(
                size: 14,
                color: AppColors.gold,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 8),
            const RuneDivider(color: AppColors.gold),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final species in FamiliarSpecies.values)
                  _SpeciesChoice(
                    species: species,
                    selected: species == _species,
                    onTap:
                        () => setState(() {
                          _species = species;
                          _name.text = _randomName(species);
                        }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _species.lore,
              style: AppFonts.body(
                size: 13,
                color: AppColors.inkMuted,
                style: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              maxLength: 16,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: 'Roll a name',
                  icon: const Icon(Icons.casino_rounded),
                  onPressed:
                      () => setState(() => _name.text = _randomName(_species)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A familiar grows a bond with every quest you finish and, once '
              'bonded, lends a little XP to each one.',
              style: AppFonts.body(size: 12, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: QuestButton(
                    label: 'Not yet',
                    compact: true,
                    style: QuestButtonStyle.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuestButton(
                    label: 'Adopt',
                    compact: true,
                    style: QuestButtonStyle.gold,
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).pop((_species, _name.text.trim())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesChoice extends StatelessWidget {
  const _SpeciesChoice({
    required this.species,
    required this.selected,
    required this.onTap,
  });

  final FamiliarSpecies species;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              selected
                  ? AppColors.amethyst.withValues(alpha: 0.45)
                  : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.bronze,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FamiliarSprite(
              species: species,
              mood: selected ? FamiliarMood.joyful : FamiliarMood.watchful,
              size: 72,
              dimmed: !selected,
            ),
            Text(
              species.label.toUpperCase(),
              style: AppFonts.label(
                size: 9,
                color: selected ? AppColors.gold : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

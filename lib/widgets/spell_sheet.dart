import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/spells.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/state/spellbook.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/achievement_unlocked_dialog.dart';
import 'package:quest_key/widgets/celebration_overlay.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/lvl_notifcation.dart';

/// Opens the spellbook. With a [target] it lists quest spells for that
/// quest; without one it lists self-cast spells (buffs, shields, sweeps).
Future<void> showSpellSheet(BuildContext context, {Quest? target}) async {
  final result = await showModalBottomSheet<SpellResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SpellSheet(target: target),
  );
  if (result == null || !context.mounted) return;
  await presentSpellResult(context, result);
}

/// Shows the outcome of a cast: toast, embers, level-up and honours.
Future<void> presentSpellResult(
  BuildContext context,
  SpellResult result,
) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            result.success ? Icons.auto_fix_high_rounded : Icons.block_rounded,
            color: result.success ? AppColors.teal : AppColors.ruby,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(result.message)),
        ],
      ),
    ),
  );
  if (!result.success) return;
  if (result.xpGained > 0) showCelebration(context);

  final hero = context.read<AppState>().hero;
  if (result.leveledUp && hero != null) {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (context, _, _) =>
              Center(child: LevelUpWidget(levelUp: hero.levelUp)),
    );
    if (!context.mounted) return;
  }
  await showAchievementsUnlocked(context, result.unlocked);
}

class _SpellSheet extends StatelessWidget {
  const _SpellSheet({this.target});

  final Quest? target;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final quests = context.watch<QuestListProvider>();
    final spellbook = Spellbook(appState: appState, quests: quests);
    final hero = appState.hero;
    final spells = spellbook.castableOn(target);
    if (target == null) {
      // Self-cast sheet also offers the sweep.
      spells.addAll(
        spellbook.known.where((s) => s.target == SpellTarget.trivialQuests),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ArcanePanel(
          accent: AppColors.amethystBright,
          glow: AppColors.amethystBright,
          fillOpacity: 0.97,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      target == null
                          ? 'Spellbook'
                          : 'Cast upon "${target!.title}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.heading(size: 16),
                    ),
                  ),
                  if (hero != null) ...[
                    RuneTag(
                      text: '${hero.mana} MP',
                      color: AppColors.arcaneBlue,
                      filled: true,
                    ),
                    const SizedBox(width: 6),
                    RuneTag(
                      text: '${hero.stamina} STA',
                      color: AppColors.gold,
                      filled: true,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              const RuneDivider(),
              const SizedBox(height: 8),
              if (spells.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    hero == null || hero.learnedSkills.isEmpty
                        ? 'You know no spells yet. Learn them in the grimoire on the Hero tab.'
                        : 'None of your spells can be cast here.',
                    textAlign: TextAlign.center,
                    style: AppFonts.body(
                      size: 14,
                      color: AppColors.inkMuted,
                      style: FontStyle.italic,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: spells.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final spell = spells[index];
                      final reason = spellbook.blockedReason(
                        spell,
                        target: target,
                      );
                      final learned = hero?.learnedSkill(spell.skillId);
                      return _SpellRow(
                        spell: spell,
                        cost: spellbook.costOf(spell),
                        proficiency: learned?.level ?? 1,
                        casts: learned?.timesUsed ?? 0,
                        blockedReason: reason,
                        onCast: () async {
                          final result = await spellbook.cast(
                            spell,
                            target: target,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop(result);
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpellRow extends StatelessWidget {
  const _SpellRow({
    required this.spell,
    required this.cost,
    required this.proficiency,
    required this.casts,
    required this.blockedReason,
    required this.onCast,
  });

  final Spell spell;
  final int cost;
  final int proficiency;
  final int casts;
  final String? blockedReason;
  final Future<void> Function() onCast;

  @override
  Widget build(BuildContext context) {
    final skill = spell.skill;
    final color = skillCategoryColor(skill.category);
    final castable = blockedReason == null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.obsidian.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: castable ? color : AppColors.bronze),
      ),
      child: Row(
        children: [
          GemRing(
            icon: skillIcon(skill.id),
            color: color,
            size: 42,
            dimmed: !castable,
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
                        skill.name,
                        style: AppFonts.heading(size: 13, letterSpacing: 0.6),
                      ),
                    ),
                    RuneTag(
                      text: '$cost ${spell.resource.label}',
                      color:
                          spell.resource == SpellResource.mana
                              ? AppColors.arcaneBlue
                              : AppColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  spell.effect,
                  style: AppFonts.body(size: 12, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  blockedReason ??
                      'PROFICIENCY $proficiency · $casts ${casts == 1 ? 'CAST' : 'CASTS'}',
                  style: AppFonts.label(
                    size: 8,
                    color: castable ? AppColors.teal : AppColors.ruby,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          QuestButton(
            label: spell.verb,
            compact: true,
            expand: false,
            style: QuestButtonStyle.gold,
            onPressed: castable ? onCast : null,
          ),
        ],
      ),
    );
  }
}

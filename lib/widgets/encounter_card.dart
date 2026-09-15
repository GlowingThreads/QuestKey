import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/encounter.dart';
import 'package:quest_key/models/spells.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/encounter_provider.dart';
import 'package:quest_key/state/spellbook.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/spell_sheet.dart';

/// Today's encounter on the Home tab, with the choices the hero can make.
class EncounterCard extends StatelessWidget {
  const EncounterCard({super.key, required this.encounter});

  final Encounter encounter;

  @override
  Widget build(BuildContext context) {
    final t = encounter.template;
    final hero = context.watch<AppState>().hero;
    final knowsStealth = hero?.hasSkill('stealth') ?? false;
    final knowsFireball = hero?.hasSkill('fireball') ?? false;
    final stealthCost = Spell.forSkill(
      'stealth',
    )!.costFor(hero?.learnedSkill('stealth'));
    final fireballCost = Spell.forSkill(
      'fireball',
    )!.costFor(hero?.learnedSkill('fireball'));

    return ArcanePanel(
      accent: AppColors.gold,
      glow: AppColors.magenta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GemRing(
                icon: categoryIcon(t.category),
                color: categoryColor(t.category),
                size: 44,
                selected: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENCOUNTER',
                      style: AppFonts.label(size: 9, color: AppColors.magenta),
                    ),
                    Text(t.title, style: AppFonts.heading(size: 16)),
                  ],
                ),
              ),
              RuneTag(
                text: '+${t.bonusPercent}% XP',
                color: AppColors.gold,
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.story,
            style: AppFonts.body(
              size: 14,
              style: FontStyle.italic,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quest: ${t.questTitle} · ${difficultyLabelFor(t.difficulty)} · ${t.hoursToComplete}h',
            style: AppFonts.label(size: 9, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              QuestButton(
                label: 'Accept',
                icon: Icons.flag_rounded,
                style: QuestButtonStyle.gold,
                compact: true,
                expand: false,
                onPressed: () => _resolve(context, (p) => p.accept()),
              ),
              if (knowsStealth)
                QuestButton(
                  label: 'Slip past · $stealthCost STA',
                  icon: Icons.visibility_off_rounded,
                  compact: true,
                  expand: false,
                  onPressed: () => _resolve(context, (p) => p.slipPast()),
                ),
              if (knowsFireball)
                QuestButton(
                  label: 'Confront · $fireballCost MP',
                  icon: Icons.local_fire_department_rounded,
                  style: QuestButtonStyle.danger,
                  compact: true,
                  expand: false,
                  onPressed: () => _resolve(context, (p) => p.confront()),
                ),
              QuestButton(
                label: 'Walk on',
                style: QuestButtonStyle.ghost,
                compact: true,
                expand: false,
                onPressed: () => _resolve(context, (p) => p.decline()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolve(
    BuildContext context,
    Future<EncounterOutcome> Function(EncounterProvider provider) action,
  ) async {
    final provider = context.read<EncounterProvider>();
    final outcome = await action(provider);
    if (!context.mounted) return;
    await presentSpellResult(
      context,
      SpellResult(
        success: outcome.success,
        message: outcome.message,
        xpGained: outcome.xpGained,
        leveledUp: outcome.leveledUp,
        unlocked: outcome.unlocked,
      ),
    );
  }
}

String difficultyLabelFor(int difficulty) => switch (difficulty) {
  1 => 'Trivial',
  2 => 'Easy',
  3 => 'Normal',
  4 => 'Hard',
  _ => 'Epic',
};

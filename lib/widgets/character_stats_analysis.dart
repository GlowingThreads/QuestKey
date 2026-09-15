import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/models/rewards.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Radar chart of the hero's attributes next to a compact record of level,
/// quests, skills and achievements.
class CharacterStatsAnalysis extends StatelessWidget {
  final HeroCharacter hero;

  const CharacterStatsAnalysis({super.key, required this.hero});

  @override
  Widget build(BuildContext context) {
    final values = {for (final s in heroStatNames) s: hero.statValue(s)};
    final base = {
      'strength': hero.classes.strength,
      'dexterity': hero.classes.dexterity,
      'intelligence': hero.classes.intelligence,
      'wisdom': hero.classes.wisdom,
      'charisma': hero.classes.charisma,
      'constitution': hero.classes.constitution,
      'luck': hero.classes.luck,
    };
    final maxValue = [12, ...values.values].reduce((a, b) => a > b ? a : b);
    final background = hero.background;

    return ArcanePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.hexagon_outlined,
            title: 'Attribute Sigil',
            subtitle: 'Teal is your hero; bronze is the class baseline.',
          ),
          const SizedBox(height: 8),
          Center(
            child: StatRadar(
              values: values,
              compare: base,
              maxValue: maxValue,
              size: 230,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Record(
                icon: Icons.military_tech_rounded,
                value: '${hero.levelUp.level}',
                label: 'LEVEL',
              ),
              _Record(
                icon: Icons.emoji_events_rounded,
                value: '${hero.questsCompleted}',
                label: 'QUESTS',
              ),
              _Record(
                icon: Icons.auto_fix_high_rounded,
                value: '${hero.learnedSkills.length}',
                label: 'SKILLS',
              ),
              _Record(
                icon: Icons.workspace_premium_rounded,
                value: '${hero.unlockedAchievements.length}',
                label: 'HONOURS',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const RuneDivider(),
          const SizedBox(height: 10),
          Text(
            'AFFINITIES',
            style: AppFonts.label(size: 9, color: AppColors.gold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final category in QuestCategory.values)
                if (affinityStatFor(category) != null)
                  RuneTag(
                    text:
                        '${category.label.toUpperCase()} +${affinityPercent(hero, category)}%',
                    color:
                        affinityPercent(hero, category) > 0
                            ? categoryColor(category)
                            : AppColors.bronze,
                    icon: categoryIcon(category),
                    filled: affinityPercent(hero, category) > 0,
                  ),
              RuneTag(
                text: 'CRITICAL ${(criticalChance(hero) * 100).round()}%',
                color: AppColors.magenta,
                icon: Icons.bolt_rounded,
                filled: criticalChance(hero) > 0,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Each attribute point above $affinityBaseline adds $affinityStepPercent% XP to its '
            'category. Luck sets the critical chance (double XP).',
            style: AppFonts.body(
              size: 12,
              color: AppColors.inkMuted,
              style: FontStyle.italic,
            ),
          ),
          if (background != null) ...[
            const SizedBox(height: 12),
            const RuneDivider(),
            const SizedBox(height: 10),
            Row(
              children: [
                GemRing(
                  icon: originIcon(background.id),
                  color: AppColors.amethyst,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORIGIN · ${background.name.toUpperCase()}',
                        style: AppFonts.label(size: 10, color: AppColors.teal),
                      ),
                      Text(
                        background.flavorText,
                        style: AppFonts.body(
                          size: 13,
                          color: AppColors.inkMuted,
                          style: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Record extends StatelessWidget {
  const _Record({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(height: 2),
        Text(value, style: AppFonts.heading(size: 18, letterSpacing: 0)),
        Text(label, style: AppFonts.label(size: 8, color: AppColors.inkMuted)),
      ],
    );
  }
}

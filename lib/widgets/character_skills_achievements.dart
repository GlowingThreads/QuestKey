import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/models/spells.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/spell_sheet.dart';

/// Grimoire (skills to learn) and Hall of Honours (achievements).
class CharacterSkillsAchievements extends StatefulWidget {
  final HeroCharacter hero;

  const CharacterSkillsAchievements({super.key, required this.hero});

  @override
  State<CharacterSkillsAchievements> createState() =>
      _CharacterSkillsAchievementsState();
}

class _CharacterSkillsAchievementsState
    extends State<CharacterSkillsAchievements>
    with TickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;

    return ArcanePanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelStyle: AppFonts.label(size: 11, color: AppColors.gold),
            unselectedLabelStyle: AppFonts.label(
              size: 11,
              color: AppColors.inkMuted,
            ),
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.inkMuted,
            indicatorColor: AppColors.teal,
            dividerColor: AppColors.bronze,
            tabs: [
              Tab(
                text:
                    'GRIMOIRE ${hero.learnedSkills.length}/${allSkills.length}',
              ),
              Tab(
                text:
                    'HONOURS ${hero.unlockedAchievements.length}/${allAchievements.length}',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSkillsTab(hero), _buildAchievementsTab(hero)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab(HeroCharacter hero) {
    final skills = [...allSkills]
      ..sort((a, b) => a.levelRequired.compareTo(b.levelRequired));

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: skills.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final skill = skills[index];
        final learned = hero.hasSkill(skill.id);
        final canLearn = !learned && hero.canLearnSkill(skill);
        final color = skillCategoryColor(skill.category);
        final spell = Spell.forSkill(skill.id);
        final learnedSkill = hero.learnedSkill(skill.id);
        final cost = spell?.costFor(learnedSkill) ?? skill.costPerUse;
        final resource = spell?.resource.label ?? 'MP';

        return Opacity(
          opacity: learned || canLearn ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.obsidian.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: learned ? color : AppColors.bronze,
                width: learned ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                GemRing(
                  icon: skillIcon(skill.id),
                  color: color,
                  size: 42,
                  dimmed: !learned && !canLearn,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: AppFonts.heading(size: 13, letterSpacing: 0.6),
                      ),
                      Text(
                        _requirementsLabel(skill, hero),
                        style: AppFonts.label(
                          size: 9,
                          color:
                              canLearn || learned
                                  ? AppColors.teal
                                  : AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        spell?.effect ?? skill.description,
                        style: AppFonts.body(
                          size: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          RuneTag(
                            text: '$cost $resource',
                            color: AppColors.arcaneBlue,
                          ),
                          if (learnedSkill != null)
                            RuneTag(
                              text:
                                  'PROF ${learnedSkill.level} · ${learnedSkill.timesUsed} CASTS',
                              color: AppColors.teal,
                            ),
                          if (spell != null && spell.targetsQuest)
                            const RuneTag(
                              text: 'CAST FROM A QUEST',
                              color: AppColors.bronzeLight,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (learned && spell != null && !spell.targetsQuest)
                  QuestButton(
                    label: spell.verb,
                    compact: true,
                    expand: false,
                    style: QuestButtonStyle.gold,
                    onPressed: () => showSpellSheet(context),
                  )
                else if (learned)
                  RuneTag(text: 'LEARNED', color: color, filled: true)
                else
                  QuestButton(
                    label: 'Learn',
                    compact: true,
                    expand: false,
                    onPressed: canLearn ? () => _learn(context, skill) : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _requirementsLabel(CharacterSkill skill, HeroCharacter hero) {
    final parts = <String>['LV ${skill.levelRequired}'];
    for (final req in skill.requirements) {
      final split = req.split(':');
      if (split.length == 2) {
        final needed = int.tryParse(split[1]) ?? 0;
        parts.add(
          '${statAbbreviation(split[0])} ${hero.statValue(split[0])}/$needed',
        );
      }
    }
    return parts.join(' · ');
  }

  Future<void> _learn(BuildContext context, CharacterSkill skill) async {
    final messenger = ScaffoldMessenger.of(context);
    final learned = await context.read<AppState>().learnSkill(skill);
    if (!learned) return;
    messenger.showSnackBar(SnackBar(content: Text('Learned ${skill.name}.')));
  }

  Future<void> _wearTitle(
    BuildContext context,
    CharacterAchievement achievement,
    bool alreadyWorn,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<AppState>().setTitle(
      alreadyWorn ? null : achievement.id,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          alreadyWorn
              ? 'Title removed.'
              : 'You are now known as the ${achievement.name}.',
        ),
      ),
    );
  }

  Widget _buildAchievementsTab(HeroCharacter hero) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: allAchievements.length,
      itemBuilder: (context, index) {
        final achievement = allAchievements[index];
        final unlocked = hero.hasAchievement(achievement.id);
        final secret = achievement.hidden && !unlocked;
        final worn = hero.titleAchievementId == achievement.id;
        final color =
            unlocked ? rarityColor(achievement.rarityScore) : AppColors.bronze;

        return Tooltip(
          message:
              secret
                  ? 'A hidden honour. Keep questing.'
                  : unlocked
                  ? '${achievement.description} Tap to wear as your title.'
                  : achievement.description,
          triggerMode:
              unlocked ? TooltipTriggerMode.longPress : TooltipTriggerMode.tap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap:
                unlocked ? () => _wearTitle(context, achievement, worn) : null,
            child: Opacity(
              opacity: unlocked ? 1 : 0.5,
              child: Column(
                children: [
                  unlocked
                      ? PulseGlow(
                        color: color,
                        radius: 10,
                        enabled: worn,
                        child: GemRing(
                          icon: achievementIcon(achievement.id),
                          color: color,
                          size: 50,
                          selected: worn,
                        ),
                      )
                      : GemRing(
                        icon:
                            secret
                                ? Icons.question_mark_rounded
                                : Icons.lock_outline_rounded,
                        color: AppColors.midnight,
                        size: 50,
                        dimmed: true,
                      ),
                  const SizedBox(height: 6),
                  Text(
                    secret ? '???' : achievement.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.label(
                      size: 8,
                      color:
                          worn
                              ? AppColors.gold
                              : unlocked
                              ? AppColors.ink
                              : AppColors.inkMuted,
                    ),
                  ),
                  if (worn)
                    Text(
                      'WORN',
                      style: AppFonts.label(size: 7, color: AppColors.gold),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

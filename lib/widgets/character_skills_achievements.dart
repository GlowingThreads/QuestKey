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
import 'package:quest_key/widgets/achievement_unlocked_dialog.dart';
import 'package:quest_key/widgets/common/sigils.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/spell_sheet.dart';

/// Grimoire (skills, grouped by school) and Hall of Honours (achievements,
/// grouped by category and pressed in wax).
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
              children: [_GrimoireTab(hero: hero), _HonoursTab(hero: hero)],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- grimoire

class _GrimoireTab extends StatelessWidget {
  const _GrimoireTab({required this.hero});

  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final learnable = allSkills.where(
      (s) => !hero.hasSkill(s.id) && hero.canLearnSkill(s),
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          sliver: SliverToBoxAdapter(
            child: _ProgressLine(
              value: hero.learnedSkills.length,
              total: allSkills.length,
              label:
                  learnable.isEmpty
                      ? 'Raise your level and attributes to unlock more.'
                      : '${learnable.length} ${learnable.length == 1 ? 'skill is' : 'skills are'} ready to learn.',
              color: AppColors.amethystBright,
            ),
          ),
        ),
        for (final school in skillSchools) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            sliver: SliverToBoxAdapter(
              child: _SchoolHeader(
                icon: skillSchoolIcon(school),
                title: skillSchoolLabel(school),
                color: skillCategoryColor(school),
                subtitle:
                    school == 'passive'
                        ? 'Always on once learned.'
                        : '${allSkills.where((s) => s.category == school && hero.hasSkill(s.id)).length}'
                            ' of ${allSkills.where((s) => s.category == school).length} learned',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverList.separated(
              itemCount: allSkills.where((s) => s.category == school).length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final skills =
                    allSkills.where((s) => s.category == school).toList()..sort(
                      (a, b) => a.levelRequired.compareTo(b.levelRequired),
                    );
                return _SkillRow(skill: skills[index], hero: hero);
              },
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 14)),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.hero});

  final CharacterSkill skill;
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
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
            ArcaneCircle(
              color: color,
              size: 50,
              active: learned,
              child: GemRing(
                icon: skillIcon(skill.id),
                color: color,
                size: 34,
                dimmed: !learned && !canLearn,
              ),
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
                    style: AppFonts.body(size: 12, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (skill.isPassive)
                        RuneTag(
                          text: learned ? 'ALWAYS ON' : 'PASSIVE',
                          color: AppColors.teal,
                          filled: learned,
                        )
                      else
                        RuneTag(
                          text: '$cost $resource',
                          color:
                              spell?.resource == SpellResource.mana
                                  ? AppColors.arcaneBlue
                                  : AppColors.gold,
                        ),
                      if (learnedSkill != null && !skill.isPassive)
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
    final unlocked = await context.read<AppState>().learnSkill(skill);
    if (unlocked == null) return;
    messenger.showSnackBar(SnackBar(content: Text('Learned ${skill.name}.')));
    if (!context.mounted) return;
    await showAchievementsUnlocked(context, unlocked);
  }
}

// ---------------------------------------------------------------- honours

class _HonoursTab extends StatelessWidget {
  const _HonoursTab({required this.hero});

  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final groups = achievementsByCategory();
    final unlockedCount = hero.unlockedAchievements.length;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          sliver: SliverToBoxAdapter(
            child: _ProgressLine(
              value: unlockedCount,
              total: allAchievements.length,
              label:
                  hero.title == null
                      ? 'Tap an unlocked honour to wear it as your title.'
                      : 'Worn: the ${hero.title!.name}.',
              color: AppColors.gold,
            ),
          ),
        ),
        for (final entry in groups.entries) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            sliver: SliverToBoxAdapter(
              child: _SchoolHeader(
                icon: achievementCategoryIcon(entry.key),
                title: achievementCategoryLabels[entry.key]!,
                color: AppColors.gold,
                subtitle:
                    '${entry.value.where((a) => hero.hasAchievement(a.id)).length}'
                    ' of ${entry.value.length}',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _HonourTile(achievement: entry.value[index], hero: hero),
                childCount: entry.value.length,
              ),
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 14)),
      ],
    );
  }
}

class _HonourTile extends StatelessWidget {
  const _HonourTile({required this.achievement, required this.hero});

  final CharacterAchievement achievement;
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final unlocked = hero.hasAchievement(achievement.id);
    final secret = achievement.hidden && !unlocked;
    final worn = hero.titleAchievementId == achievement.id;
    final color = rarityColor(achievement.rarityScore);

    return Tooltip(
      message:
          secret
              ? 'A hidden honour. Keep questing.'
              : unlocked
              ? '${achievement.description} Tap to wear as your title.'
              : '${achievement.description} (${rarityLabel(achievement.rarityScore)})',
      triggerMode:
          unlocked ? TooltipTriggerMode.longPress : TooltipTriggerMode.tap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: unlocked ? () => _wearTitle(context, achievement, worn) : null,
        child: Column(
          children: [
            WaxSeal(
              icon:
                  secret
                      ? Icons.question_mark_rounded
                      : unlocked
                      ? achievementIcon(achievement.id)
                      : Icons.lock_outline_rounded,
              color: color,
              size: 54,
              dimmed: !unlocked,
              glow: worn,
            ),
            const SizedBox(height: 5),
            RarityPips(
              rarity: achievement.rarityScore,
              color: unlocked ? color : AppColors.bronze,
              size: 4,
            ),
            const SizedBox(height: 4),
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
    );
  }

  Future<void> _wearTitle(
    BuildContext context,
    CharacterAchievement achievement,
    bool alreadyWorn,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final unlocked = await context.read<AppState>().setTitle(
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
    if (!context.mounted) return;
    await showAchievementsUnlocked(context, unlocked);
  }
}

// ---------------------------------------------------------------- shared

class _SchoolHeader extends StatelessWidget {
  const _SchoolHeader({
    required this.icon,
    required this.title,
    required this.color,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: AppFonts.label(size: 10, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: RuneDivider(color: color.withValues(alpha: 0.5))),
        const SizedBox(width: 10),
        Text(
          subtitle.toUpperCase(),
          style: AppFonts.label(size: 8, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.value,
    required this.total,
    required this.label,
    required this.color,
  });

  final int value;
  final int total;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (value * 100 / total).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppFonts.body(
                  size: 12,
                  color: AppColors.inkMuted,
                  style: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$percent%', style: AppFonts.label(size: 10, color: color)),
          ],
        ),
        const SizedBox(height: 5),
        AnimatedBar(
          fraction: total == 0 ? 0 : value / total,
          height: 5,
          colors: [Color.lerp(color, AppColors.obsidian, 0.4)!, color],
        ),
      ],
    );
  }
}

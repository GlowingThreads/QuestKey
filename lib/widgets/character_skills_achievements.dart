import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/state/app_state.dart';

/// Skills the hero can learn and achievements it can earn, with progress.
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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final unlockedCount = hero.unlockedAchievements.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgOverlay,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.borderLight,
          width: AppBorders.thin,
        ),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accentGreen,
            tabs: [
              Tab(
                text:
                    'Skills (${hero.learnedSkills.length}/${allSkills.length})',
              ),
              Tab(
                text: 'Achievements ($unlockedCount/${allAchievements.length})',
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

    return ListView.builder(
      padding: const EdgeInsets.all(AppPadding.lg),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final learned = hero.hasSkill(skill.id);
        final canLearn = !learned && hero.canLearnSkill(skill);
        final color = _getCategoryColor(skill.category);

        return Opacity(
          opacity: learned || canLearn ? 1 : 0.55,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppPadding.md),
            padding: const EdgeInsets.all(AppPadding.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryDarker,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: learned ? color : AppColors.borderLight,
                width: learned ? AppBorders.medium : AppBorders.thin,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(skill.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppPadding.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill.name,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _requirementsLabel(skill, hero),
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color:
                                  canLearn || learned
                                      ? AppColors.accentGreen
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (learned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.sm,
                          vertical: AppPadding.xs,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          'Learned',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: color),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed:
                            canLearn ? () => _learn(context, skill) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.md,
                          ),
                        ),
                        child: const Text('Learn'),
                      ),
                  ],
                ),
                const SizedBox(height: AppPadding.sm),
                Text(
                  skill.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _requirementsLabel(CharacterSkill skill, HeroCharacter hero) {
    final parts = <String>['Lv. ${skill.levelRequired}'];
    for (final req in skill.requirements) {
      final split = req.split(':');
      if (split.length == 2) {
        final stat = split[0];
        final needed = int.tryParse(split[1]) ?? 0;
        parts.add('$stat ${hero.statValue(stat)}/$needed');
      }
    }
    return parts.join(' · ');
  }

  Future<void> _learn(BuildContext context, CharacterSkill skill) async {
    final messenger = ScaffoldMessenger.of(context);
    final learned = await context.read<AppState>().learnSkill(skill);
    if (!learned) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${skill.icon} Learned ${skill.name}!')),
    );
  }

  Widget _buildAchievementsTab(HeroCharacter hero) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppPadding.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppPadding.md,
        mainAxisSpacing: AppPadding.md,
        childAspectRatio: 1.15,
      ),
      itemCount: allAchievements.length,
      itemBuilder: (context, index) {
        final achievement = allAchievements[index];
        final unlocked = hero.hasAchievement(achievement.id);
        final secret = achievement.hidden && !unlocked;

        return _buildAchievementCard(
          context,
          icon: secret ? '❓' : achievement.icon,
          name: secret ? '???' : achievement.name,
          description:
              secret
                  ? 'Hidden achievement. Keep questing!'
                  : achievement.description,
          rarityColor:
              unlocked
                  ? _getRarityColor(achievement.rarityScore)
                  : AppColors.borderLight,
          unlocked: unlocked,
        );
      },
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required String icon,
    required String name,
    required String description,
    required Color rarityColor,
    required bool unlocked,
  }) {
    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryDarker,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: rarityColor, width: AppBorders.medium),
          boxShadow:
              unlocked
                  ? [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppPadding.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: AppPadding.sm),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: AppPadding.sm,
              right: AppPadding.sm,
              child: Tooltip(
                message: description,
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(
                  unlocked ? Icons.info_outline : Icons.lock_outline,
                  color: rarityColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'combat':
        return Colors.red[400]!;
      case 'magic':
        return Colors.purple[400]!;
      case 'utility':
        return Colors.blue[400]!;
      case 'passive':
        return Colors.green[400]!;
      default:
        return AppColors.borderLight;
    }
  }

  Color _getRarityColor(int rarityScore) {
    switch (rarityScore) {
      case 1:
        return Colors.grey[400]!;
      case 2:
        return Colors.blue[400]!;
      case 3:
        return Colors.purple[400]!;
      case 4:
        return Colors.orange[400]!;
      case 5:
        return Colors.red[400]!;
      default:
        return AppColors.borderLight;
    }
  }
}

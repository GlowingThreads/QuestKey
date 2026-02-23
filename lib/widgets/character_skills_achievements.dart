import 'package:flutter/material.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_skill.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

/// Display character skills and achievements
class CharacterSkillsAchievements extends StatefulWidget {
  final HeroCharacter hero;

  const CharacterSkillsAchievements({
    super.key,
    required this.hero,
  });

  @override
  State<CharacterSkillsAchievements> createState() =>
      _CharacterSkillsAchievementsState();
}

class _CharacterSkillsAchievementsState
    extends State<CharacterSkillsAchievements> with TickerProviderStateMixin {
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
                    'Skills (${widget.hero.learnedSkills.length})',
              ),
              Tab(
                text:
                    'Achievements (${widget.hero.unlockedAchievements.length})',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSkillsTab(),
                _buildAchievementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    if (widget.hero.learnedSkills.isEmpty) {
      return Center(
        child: Text(
          'No skills learned yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppPadding.lg),
      itemCount: widget.hero.learnedSkills.length,
      itemBuilder: (context, index) {
        final learnedSkill = widget.hero.learnedSkills[index];
        final skill = learnedSkill.skill;

        return Container(
          margin: const EdgeInsets.only(bottom: AppPadding.md),
          padding: const EdgeInsets.all(AppPadding.lg),
          decoration: BoxDecoration(
            color: AppColors.primaryDarker,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _getCategoryColor(skill.category),
              width: AppBorders.thin,
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
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Lv. ${learnedSkill.level}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.sm,
                      vertical: AppPadding.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      '${skill.costPerUse} mana',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.cyan[300],
                          ),
                    ),
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
              if (learnedSkill.timesUsed > 0) ...[
                const SizedBox(height: AppPadding.sm),
                Text(
                  'Used ${learnedSkill.timesUsed} times',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    if (widget.hero.unlockedAchievements.isEmpty) {
      return Center(
        child: Text(
          'No achievements unlocked yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppPadding.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppPadding.md,
        mainAxisSpacing: AppPadding.md,
      ),
      itemCount: widget.hero.unlockedAchievements.length,
      itemBuilder: (context, index) {
        final unlocked = widget.hero.unlockedAchievements[index];
        final achievement = unlocked.achievement;

        return _buildAchievementCard(
          context,
          achievement.icon,
          achievement.name,
          achievement.description,
          _getRarityColor(achievement.rarityScore),
        );
      },
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    String icon,
    String name,
    String description,
    Color rarityColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDarker,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: rarityColor,
          width: AppBorders.medium,
        ),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: AppPadding.md),
              Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          Positioned(
            top: AppPadding.sm,
            right: AppPadding.sm,
            child: Tooltip(
              message: description,
              child: Icon(
                Icons.info_outline,
                color: rarityColor,
                size: 20,
              ),
            ),
          ),
        ],
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

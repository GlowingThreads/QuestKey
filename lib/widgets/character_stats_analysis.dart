import 'package:flutter/material.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

/// Detailed character stats analysis and comparison
class CharacterStatsAnalysis extends StatelessWidget {
  final HeroCharacter hero;

  const CharacterStatsAnalysis({
    super.key,
    required this.hero,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _getStatsList();
    final maxStatValue =
        stats.fold<int>(0, (max, stat) => stat['value'] > max ? stat['value'] : max);

    return Container(
      padding: const EdgeInsets.all(AppPadding.xl),
      decoration: BoxDecoration(
        color: AppColors.bgOverlay,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.borderLight,
          width: AppBorders.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Character Stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppPadding.lg),
          // Stats grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppPadding.md,
              mainAxisSpacing: AppPadding.md,
              childAspectRatio: 3,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              final progress = (stat['value'] / 15).clamp(0.0, 1.0);
              return _buildStatItem(
                context,
                stat['name'],
                stat['value'],
                stat['icon'],
                progress,
              );
            },
          ),
          const SizedBox(height: AppPadding.xl),
          // Character info
          _buildCharacterInfo(context),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String name,
    int value,
    String icon,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryDarker,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.borderLight,
          width: AppBorders.thin,
        ),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: AppPadding.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.primaryDarker,
                    valueColor: AlwaysStoppedAnimation(
                      _getStatColor(value),
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppPadding.sm),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryDarker,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.borderLight,
          width: AppBorders.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                context,
                'Level',
                hero.levelUp.level.toString(),
                '🎯',
              ),
              _buildInfoItem(
                context,
                'Quests',
                hero.questsCompleted.toString(),
                '📋',
              ),
              _buildInfoItem(
                context,
                'Skills',
                hero.learnedSkills.length.toString(),
                '⚡',
              ),
              _buildInfoItem(
                context,
                'Achievements',
                hero.unlockedAchievements.length.toString(),
                '🏆',
              ),
            ],
          ),
          if (hero.background != null) ...[
            const SizedBox(height: AppPadding.lg),
            Row(
              children: [
                Text(
                  hero.background!.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppPadding.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        hero.background!.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.w600,
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

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    String icon,
  ) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: AppPadding.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getStatsList() {
    return [
      {'name': 'Strength', 'value': hero.strength, 'icon': '💪'},
      {'name': 'Dexterity', 'value': hero.dexterity, 'icon': '🎯'},
      {'name': 'Intelligence', 'value': hero.intelligence, 'icon': '🧠'},
      {'name': 'Wisdom', 'value': hero.wisdom, 'icon': '💡'},
      {'name': 'Charisma', 'value': hero.charisma, 'icon': '✨'},
      {'name': 'Constitution', 'value': hero.constitution, 'icon': '🛡️'},
      {'name': 'Luck', 'value': hero.luck, 'icon': '🍀'},
    ];
  }

  Color _getStatColor(int value) {
    if (value <= 3) return Colors.red[400]!;
    if (value <= 5) return Colors.orange[400]!;
    if (value <= 7) return Colors.yellow[400]!;
    if (value <= 9) return Colors.green[400]!;
    return Colors.cyan[400]!;
  }
}

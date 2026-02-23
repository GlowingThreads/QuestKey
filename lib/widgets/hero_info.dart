import 'package:flutter/material.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

class HeroProfileCard extends StatelessWidget {
  final HeroCharacter hero;

  const HeroProfileCard({super.key, required this.hero});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.xl),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.borderLight,
          width: AppBorders.medium,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: AppBorders.thin,
                    ),
                  ),
                  child: Image.asset(
                    hero.imageUrl,
                    height: AppImageSizes.heroAvatar,
                    width: AppImageSizes.heroAvatar,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: AppPadding.xl),
              // Hero info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hero.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Text(
                      '"${hero.motto}"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppPadding.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.md,
                        vertical: AppPadding.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarker,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: AppBorders.thin,
                        ),
                      ),
                      child: Text(
                        '${hero.classes.className} Lv. ${hero.levelUp.level}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.xl),
          // Divider
          Container(
            height: 1,
            color: AppColors.borderLight,
          ),
          const SizedBox(height: AppPadding.lg),
          // Resource stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                context,
                'HP',
                hero.health.toString(),
                Icons.favorite,
                Colors.redAccent,
              ),
              _buildStatCard(
                context,
                'MP',
                hero.mana.toString(),
                Icons.bolt,
                Colors.blueAccent,
              ),
              _buildStatCard(
                context,
                'Stamina',
                hero.stamina.toString(),
                Icons.flash_on,
                Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.md,
        vertical: AppPadding.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryDarker,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: AppBorders.thin,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppIconSizes.md),
          const SizedBox(height: AppPadding.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppPadding.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

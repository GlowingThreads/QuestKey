import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/pages/hero_creation_page.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Compact hero card for the Home tab.
class HeroProfileCard extends StatelessWidget {
  final HeroCharacter hero;

  const HeroProfileCard({super.key, required this.hero});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.accentGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
              child: SizedBox(
                height: AppImageSizes.heroAvatar,
                width: AppImageSizes.heroAvatar,
                child: HeroAvatar(imageUrl: hero.imageUrl),
              ),
            ),
          ),
          const SizedBox(width: AppPadding.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hero.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.accentGold),
                      ),
                      child: Text(
                        'Lv. ${hero.levelUp.level}',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: AppFontSizes.xs,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${classEmoji(hero.classes.className)} '
                  '${hero.classes.className}'
                  '${hero.background == null ? '' : ' · ${hero.background!.name}'}',
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: AppFontSizes.xs,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppPadding.xs),
                Text(
                  '"${hero.motto}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: AppFontSizes.xs,
                  ),
                ),
                const SizedBox(height: AppPadding.sm),
                Row(
                  children: [
                    _MiniStat(Icons.favorite, hero.health, Colors.redAccent),
                    const SizedBox(width: AppPadding.md),
                    _MiniStat(Icons.bolt, hero.mana, Colors.lightBlueAccent),
                    const SizedBox(width: AppPadding.md),
                    _MiniStat(
                      Icons.flash_on,
                      hero.stamina,
                      Colors.orangeAccent,
                    ),
                    const Spacer(),
                    _MiniStat(
                      Icons.emoji_events,
                      hero.questsCompleted,
                      AppColors.accentGold,
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
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.value, this.color);

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        AnimatedCount(
          value: value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: AppFontSizes.xs,
          ),
        ),
      ],
    );
  }
}

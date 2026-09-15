import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/pages/hero_creation_page.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/character_skills_achievements.dart';
import 'package:quest_key/widgets/character_stats_analysis.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/stats_panel.dart';
import 'package:quest_key/widgets/xp_bar.dart';

class HeroPage extends StatelessWidget {
  const HeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hero = context.watch<AppState>().hero;

    return Scaffold(
      body: PageBackground(
        asset: 'assets/images/app_assets/hero_bkg.jpg',
        child: SafeArea(
          child:
              hero == null
                  ? const Center(
                    child: Text(
                      'No hero yet.',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                  : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppPadding.xxl,
                      AppPadding.lg,
                      AppPadding.xxl,
                      110,
                    ),
                    children: [
                      FadeSlideIn(child: _HeroHeader(hero: hero)),
                      const SizedBox(height: AppPadding.lg),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: XpBar(
                          currentXp: hero.levelUp.exp,
                          maxXp: hero.levelUp.maxExp,
                        ),
                      ),
                      const SizedBox(height: AppPadding.lg),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: CharacterStatsAnalysis(hero: hero),
                      ),
                      const SizedBox(height: AppPadding.lg),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 240),
                        child: SizedBox(
                          height: 340,
                          child: CharacterSkillsAchievements(hero: hero),
                        ),
                      ),
                      const SizedBox(height: AppPadding.lg),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 320),
                        child: StatPanel(hero: hero),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

/// Portrait with a glowing ring, name, class/origin chips and animated
/// HP / MP / Stamina bars.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.hero});

  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final background = hero.background;
    final hasPoints = hero.levelUp.statPoints > 0;

    return GlassPanel(
      glowColor: hasPoints ? AppColors.accentGold : null,
      child: Column(
        children: [
          Row(
            children: [
              PulseGlow(
                enabled: hasPoints,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentGold, width: 2),
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: AppImageSizes.heroAvatar,
                      height: AppImageSizes.heroAvatar,
                      child: HeroAvatar(imageUrl: hero.imageUrl),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppPadding.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hero.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    Wrap(
                      spacing: AppPadding.xs,
                      runSpacing: AppPadding.xs,
                      children: [
                        _Tag(
                          '${classEmoji(hero.classes.className)} '
                          '${hero.classes.className}',
                        ),
                        if (background != null)
                          _Tag('${background.icon} ${background.name}'),
                        _Tag('Lv. ${hero.levelUp.level}', gold: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasPoints) ...[
            const SizedBox(height: AppPadding.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.md,
                vertical: AppPadding.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.accentGold),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars,
                    color: AppColors.accentGold,
                    size: 18,
                  ),
                  const SizedBox(width: AppPadding.sm),
                  Expanded(
                    child: Text(
                      '${hero.levelUp.statPoints} stat '
                      '${hero.levelUp.statPoints == 1 ? 'point' : 'points'} '
                      'to spend. Scroll down to allocate.',
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: AppFontSizes.xs,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppPadding.lg),
          _ResourceBar(
            label: 'HP',
            icon: Icons.favorite,
            value: hero.health,
            max: 100 + hero.levelUp.level * 5,
            colors: const [Color(0xFFB71C1C), Colors.redAccent],
          ),
          const SizedBox(height: AppPadding.sm),
          _ResourceBar(
            label: 'MP',
            icon: Icons.bolt,
            value: hero.mana,
            max: 50 + hero.levelUp.level * 5,
            colors: const [Color(0xFF0D47A1), Colors.lightBlueAccent],
          ),
          const SizedBox(height: AppPadding.sm),
          _ResourceBar(
            label: 'STA',
            icon: Icons.flash_on,
            value: hero.stamina,
            max: 75 + hero.levelUp.level * 8,
            colors: const [Color(0xFFE65100), Colors.orangeAccent],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.gold = false});

  final String text;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color:
            gold ? AppColors.accentGold.withValues(alpha: 0.2) : Colors.black38,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: gold ? AppColors.accentGold : AppColors.borderLight,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppFontSizes.xs,
          color: gold ? AppColors.accentGold : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  const _ResourceBar({
    required this.label,
    required this.icon,
    required this.value,
    required this.max,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final int value;
  final int max;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= 0 ? 1 : (value > max ? value : max);
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.last),
        const SizedBox(width: AppPadding.xs),
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.xs,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: AnimatedBar(
            fraction: value / safeMax,
            height: 10,
            colors: colors,
          ),
        ),
        const SizedBox(width: AppPadding.sm),
        SizedBox(
          width: 64,
          child: Text(
            '$value / $safeMax',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: AppFontSizes.xs),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/character_skills_achievements.dart';
import 'package:quest_key/widgets/character_stats_analysis.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/hero_info.dart';
import 'package:quest_key/widgets/stats_panel.dart';
import 'package:quest_key/widgets/xp_bar.dart';

class HeroPage extends StatelessWidget {
  const HeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hero = context.watch<AppState>().hero;

    return Scaffold(
      body: PageBackground(
        asset: Art.heroBackground,
        child: SafeArea(
          child:
              hero == null
                  ? Center(child: Text('No hero yet.', style: AppFonts.body()))
                  : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
                    children: [
                      FadeSlideIn(
                        child: Row(
                          children: [
                            const PortholeBadge(
                              asset: Art.hero,
                              size: 64,
                              glow: AppColors.gold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Character Sheet',
                                    style: AppFonts.heading(size: 22),
                                  ),
                                  Text(
                                    hero.levelUp.statPoints > 0
                                        ? '${hero.levelUp.statPoints} attribute '
                                            '${hero.levelUp.statPoints == 1 ? 'point' : 'points'} unspent'
                                        : 'Level ${hero.levelUp.level} ${hero.classes.className}',
                                    style: AppFonts.body(
                                      size: 13,
                                      color:
                                          hero.levelUp.statPoints > 0
                                              ? AppColors.teal
                                              : AppColors.inkMuted,
                                      style: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppPadding.lg),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: HeroProfileCard(hero: hero),
                      ),
                      const SizedBox(height: AppPadding.md),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: XpBar(
                          currentXp: hero.levelUp.exp,
                          maxXp: hero.levelUp.maxExp,
                        ),
                      ),
                      const SizedBox(height: AppPadding.md),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: CharacterStatsAnalysis(hero: hero),
                      ),
                      const SizedBox(height: AppPadding.md),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 260),
                        child: StatPanel(hero: hero),
                      ),
                      const SizedBox(height: AppPadding.md),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 320),
                        child: SizedBox(
                          height: 520,
                          child: CharacterSkillsAchievements(hero: hero),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

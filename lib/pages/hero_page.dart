import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/widgets/hero_info.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/stats_panel.dart';
import 'package:quest_key/widgets/xp_bar.dart';
import 'package:quest_key/widgets/character_stats_analysis.dart';
import 'package:quest_key/widgets/character_skills_achievements.dart';
import 'package:quest_key/constants/app_dimens.dart';

class HeroPage extends StatefulWidget {
  const HeroPage({super.key});

  @override
  State<HeroPage> createState() => _HeroState();
}

class _HeroState extends State<HeroPage> {
  @override
  Widget build(BuildContext context) {
    final hero = context.watch<AppState>().hero;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_assets/hero_bkg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  hero != null
                      ? HeroProfileCard(hero: hero)
                      : const Center(
                        child: Text(
                          'Loading hero...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  const SizedBox(height: AppPadding.xl),
                  if (hero != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppPadding.lg),
                      child: XpBar(
                        currentXp: hero.levelUp.exp,
                        maxXp: hero.levelUp.maxExp,
                      ),
                    ),
                  if (hero != null) ...[
                    // Character stats analysis
                    CharacterStatsAnalysis(hero: hero),
                    const SizedBox(height: AppPadding.xl),
                    // Skills and achievements
                    SizedBox(
                      height: 300,
                      child: CharacterSkillsAchievements(hero: hero),
                    ),
                    const SizedBox(height: AppPadding.lg),
                    // Stat allocation panel
                    StatPanel(hero: hero),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

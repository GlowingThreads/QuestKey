import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/widgets/hero_info.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/stats_panel.dart';
import 'package:quest_key/widgets/xp_bar.dart';

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
                  const SizedBox(height: 20),
                  if (hero != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: XpBar(
                        currentXp: hero.levelUp.exp,
                        maxXp: hero.levelUp.maxExp,
                      ),
                    ),
                  if (hero != null) StatPanel(hero: hero),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

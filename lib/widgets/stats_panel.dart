// stats collection panel w/ increment on points
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/widgets/status_bar.dart';
import 'package:quest_key/state/app_state.dart';

class StatPanel extends StatefulWidget {
  final HeroCharacter hero;

  const StatPanel({super.key, required this.hero});

  @override
  State<StatPanel> createState() => _StatPanelState();
}

class _StatPanelState extends State<StatPanel> {
  late HeroCharacter hero;
  // hero character
  @override
  void initState() {
    super.initState();
    hero = widget.hero;
  }

  // increment stat points
  void _incrementStat(String stat) {
    if (hero.levelUp.statPoints > 0) {
      setState(() {
        hero.assignStatPoints(stat, 1);
      });
      context.read<AppState>().saveHero(hero);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(128, 2, 2, 2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  hero.levelUp.statPoints > 0
                      ? 'Stat Points (${hero.levelUp.statPoints})'
                      : 'No Stat Points Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        hero.levelUp.statPoints > 0
                            ? Colors.white
                            : const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 18),
                // stats collection - increment
                StatBar(
                  label: 'Strength',
                  value: hero.strength,
                  onAdd:
                      hero.levelUp.statPoints > 0
                          ? () => _incrementStat('strength')
                          : null,
                ),
                StatBar(
                  label: 'Dexterity',
                  value: hero.dexterity,
                  onAdd:
                      hero.levelUp.statPoints > 0
                          ? () => _incrementStat('dexterity')
                          : null,
                ),
                StatBar(
                  label: 'Intelligence',
                  value: hero.intelligence,
                  onAdd:
                      hero.levelUp.statPoints > 0
                          ? () => _incrementStat('intelligence')
                          : null,
                ),
                StatBar(
                  label: 'Wisdom',
                  value: hero.wisdom,
                  onAdd:
                      hero.levelUp.statPoints > 0
                          ? () => _incrementStat('wisdom')
                          : null,
                ),
                StatBar(
                  label: 'Charisma',
                  value: hero.charisma,
                  onAdd:
                      hero.levelUp.statPoints > 0
                          ? () => _incrementStat('charisma')
                          : null,
                ),
                StatBar(
                  label: 'Constitution',
                  value: hero.constitution,
                  onAdd:
                      hero.levelUp.statPoints > 0
                          ? () => _incrementStat('constitution')
                          : null,
                ),
                StatBar(
                  label: 'Luck',
                  value: hero.luck,
                  onAdd:
                      hero.levelUp.statPoints > 0
                          ? () => _incrementStat('luck')
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

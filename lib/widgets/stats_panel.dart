// stats collection panel w/ increment on points
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/status_bar.dart';

class StatPanel extends StatelessWidget {
  final HeroCharacter hero;

  const StatPanel({super.key, required this.hero});

  static const List<({String key, String label})> _stats = [
    (key: 'strength', label: 'Strength'),
    (key: 'dexterity', label: 'Dexterity'),
    (key: 'intelligence', label: 'Intelligence'),
    (key: 'wisdom', label: 'Wisdom'),
    (key: 'charisma', label: 'Charisma'),
    (key: 'constitution', label: 'Constitution'),
    (key: 'luck', label: 'Luck'),
  ];

  // increment stat points
  void _incrementStat(BuildContext context, String stat) {
    if (hero.levelUp.statPoints <= 0) return;
    final updated = hero.assignStatPoints(stat, 1);
    context.read<AppState>().saveHero(updated);
  }

  @override
  Widget build(BuildContext context) {
    final hasPoints = hero.levelUp.statPoints > 0;

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
                  hasPoints
                      ? 'Stat Points (${hero.levelUp.statPoints})'
                      : 'No Stat Points Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        hasPoints
                            ? Colors.white
                            : const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 18),
                // stats collection - increment
                for (final stat in _stats)
                  StatBar(
                    label: stat.label,
                    value: hero.statValue(stat.key),
                    onAdd:
                        hasPoints
                            ? () => _incrementStat(context, stat.key)
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

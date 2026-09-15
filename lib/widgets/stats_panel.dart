import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/achievement_unlocked_dialog.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/status_bar.dart';

/// Attribute allocation: spend stat points earned from levelling.
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

  Future<void> _incrementStat(BuildContext context, String stat) async {
    if (hero.levelUp.statPoints <= 0) return;
    final unlocked = await context.read<AppState>().assignStatPoint(stat);
    if (!context.mounted) return;
    await showAchievementsUnlocked(context, unlocked);
  }

  @override
  Widget build(BuildContext context) {
    final points = hero.levelUp.statPoints;
    final hasPoints = points > 0;

    return ArcanePanel(
      glow: hasPoints ? AppColors.teal : null,
      accent: hasPoints ? AppColors.teal : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.tune_rounded,
            title: 'Attributes',
            subtitle:
                hasPoints
                    ? '$points ${points == 1 ? 'point' : 'points'} to spend. Tap + to allocate.'
                    : 'Level up to earn ${3} more points.',
            trailing:
                hasPoints
                    ? RuneTag(
                      text: '$points LEFT',
                      color: AppColors.teal,
                      filled: true,
                    )
                    : null,
          ),
          const SizedBox(height: 6),
          for (final stat in _stats)
            StatBar(
              label: stat.label.toUpperCase(),
              value: hero.statValue(stat.key),
              onAdd: hasPoints ? () => _incrementStat(context, stat.key) : null,
            ),
        ],
      ),
    );
  }
}

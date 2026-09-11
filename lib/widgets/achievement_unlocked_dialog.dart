import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/character_achievement.dart';

/// Shows a dialog listing newly unlocked [achievements]. No-op when empty.
Future<void> showAchievementsUnlocked(
  BuildContext context,
  List<CharacterAchievement> achievements,
) async {
  if (achievements.isEmpty) return;

  await showDialog<void>(
    context: context,
    builder: (context) => AchievementUnlockedDialog(achievements: achievements),
  );
}

class AchievementUnlockedDialog extends StatelessWidget {
  const AchievementUnlockedDialog({super.key, required this.achievements});

  final List<CharacterAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(
          color: AppColors.accentGold,
          width: AppBorders.thick,
        ),
      ),
      title: Text(
        achievements.length == 1
            ? 'Achievement unlocked!'
            : '${achievements.length} achievements unlocked!',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.accentGold,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final achievement in achievements)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(
                achievement.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                achievement.description,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Nice!',
            style: TextStyle(color: AppColors.accentGreen),
          ),
        ),
      ],
    );
  }
}

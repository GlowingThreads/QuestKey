import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/character_achievement.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Shows a dialog listing newly unlocked [achievements]. No-op when empty.
Future<void> showAchievementsUnlocked(
  BuildContext context,
  List<CharacterAchievement> achievements,
) async {
  if (achievements.isEmpty) return;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => AchievementUnlockedDialog(achievements: achievements),
  );
}

class AchievementUnlockedDialog extends StatelessWidget {
  const AchievementUnlockedDialog({super.key, required this.achievements});

  final List<CharacterAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ArcanePanel(
        accent: AppColors.gold,
        glow: AppColors.gold,
        fillOpacity: 0.95,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievements.length == 1
                  ? 'ACHIEVEMENT UNLOCKED'
                  : '${achievements.length} ACHIEVEMENTS UNLOCKED',
              textAlign: TextAlign.center,
              style: AppFonts.heading(
                size: 15,
                color: AppColors.gold,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 8),
            const RuneDivider(color: AppColors.gold),
            const SizedBox(height: 12),
            for (final achievement in achievements)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    GemRing(
                      icon: achievementIcon(achievement.id),
                      color: rarityColor(achievement.rarityScore),
                      size: 48,
                      selected: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.name,
                            style: AppFonts.heading(
                              size: 14,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            achievement.description,
                            style: AppFonts.body(
                              size: 13,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            QuestButton(
              label: 'Nice!',
              style: QuestButtonStyle.gold,
              compact: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

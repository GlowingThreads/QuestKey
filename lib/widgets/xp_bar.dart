import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Experience bar in a bronze frame.
class XpBar extends StatelessWidget {
  final int currentXp;
  final int maxXp;

  const XpBar({super.key, required this.currentXp, required this.maxXp});

  @override
  Widget build(BuildContext context) {
    final progress = maxXp == 0 ? 0.0 : (currentXp / maxXp).clamp(0.0, 1.0);
    final percentage = (progress * 100).toStringAsFixed(0);

    return ArcanePanel(
      ornate: false,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.gold,
              ),
              const SizedBox(width: 6),
              Text(
                'EXPERIENCE',
                style: AppFonts.label(size: 10, color: AppColors.gold),
              ),
              const Spacer(),
              Text(
                '$currentXp / $maxXp XP  ·  $percentage%',
                style: AppFonts.body(size: 12, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBar(fraction: progress, height: 12),
          const SizedBox(height: 6),
          Text(
            '${maxXp - currentXp} XP to the next level',
            style: AppFonts.body(
              size: 12,
              color: AppColors.inkMuted,
              style: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

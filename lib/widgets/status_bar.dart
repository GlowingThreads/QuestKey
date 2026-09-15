import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// One attribute row: name, value, bronze bar and an optional "+" gem.
class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onAdd;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.onAdd,
  });

  static const int _maxStat = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: AppFonts.label(size: 10, color: AppColors.ink),
            ),
          ),
          Expanded(
            child: AnimatedBar(
              fraction: value / _maxStat,
              height: 9,
              colors: AppColors.statGradient,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: AppFonts.body(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            height: 30,
            child:
                onAdd == null
                    ? const SizedBox.shrink()
                    : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onAdd,
                        customBorder: const CircleBorder(),
                        child: const GemRing(
                          icon: Icons.add_rounded,
                          color: AppColors.teal,
                          size: 30,
                          iconColor: AppColors.obsidian,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

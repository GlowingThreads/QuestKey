import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

class CustomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  final List<String> navIcons = [
    'assets/images/app_assets/home.png',
    'assets/images/app_assets/quest_log.png',
    'assets/images/app_assets/create.png',
    'assets/images/app_assets/hero.png',
    'assets/images/app_assets/info.png',
  ];

  final List<String> navLabels = ['Home', 'Quests', 'Create', 'Hero', 'Info'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.sm),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: AppBorders.thin),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navIcons.length, (index) {
          final isSelected = widget.currentIndex == index;
          return GestureDetector(
            onTap: () => widget.onTap(index),
            child: AnimatedOpacity(
              opacity: isSelected ? AppOpacity.full : AppOpacity.disabled,
              duration: AppDurations.short,
              child: Tooltip(
                message: navLabels[index],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppPadding.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentPurple.withOpacity(0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Image.asset(
                        navIcons[index],
                        height: AppIconSizes.md,
                        width: AppIconSizes.md,
                      ),
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Text(
                      navLabels[index],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

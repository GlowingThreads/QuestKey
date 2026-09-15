import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<({String asset, IconData icon, String label})> _items = [
    (
      asset: 'assets/images/app_assets/home.png',
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    (
      asset: 'assets/images/app_assets/quest_log.png',
      icon: Icons.list_alt_rounded,
      label: 'Quests',
    ),
    (
      asset: 'assets/images/app_assets/create.png',
      icon: Icons.add_circle_rounded,
      label: 'Create',
    ),
    (
      asset: 'assets/images/app_assets/hero.png',
      icon: Icons.person_rounded,
      label: 'Hero',
    ),
    (
      asset: 'assets/images/app_assets/info.png',
      icon: Icons.menu_book_rounded,
      label: 'Guide',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: AppPadding.sm,
        bottom: AppPadding.sm + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE6140C2E), Color(0xFF0B0718)],
        ),
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var index = 0; index < _items.length; index++)
            _NavItem(
              item: _items[index],
              selected: currentIndex == index,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(index);
              },
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({String asset, IconData icon, String label}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: item.label,
        child: AnimatedContainer(
          duration: AppDurations.short,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.md,
            vertical: AppPadding.xs,
          ),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.accentPurple.withValues(alpha: 0.35)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color:
                  selected
                      ? AppColors.accentGold.withValues(alpha: 0.6)
                      : Colors.transparent,
            ),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: AppColors.shadowPurple.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.15 : 1,
                duration: AppDurations.short,
                child: AnimatedOpacity(
                  opacity: selected ? AppOpacity.full : AppOpacity.medium,
                  duration: AppDurations.short,
                  child: Image.asset(
                    item.asset,
                    height: AppIconSizes.md,
                    width: AppIconSizes.md,
                    errorBuilder:
                        (_, _, _) => Icon(
                          item.icon,
                          size: AppIconSizes.md,
                          color: selected ? AppColors.accentGold : Colors.white,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.xs),
              AnimatedDefaultTextStyle(
                duration: AppDurations.short,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color:
                      selected ? AppColors.accentGold : AppColors.textSecondary,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

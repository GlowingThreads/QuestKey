import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/theme/iconography.dart';

/// Bottom navigation built from the porthole badge illustrations. The art
/// carries its own lettering, so no text labels are drawn; the active
/// badge lifts, brightens and glows teal.
class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<({String asset, IconData icon, String label})> _items = [
    (asset: Art.home, icon: Icons.home_rounded, label: 'Home'),
    (asset: Art.questLog, icon: Icons.list_alt_rounded, label: 'Quests'),
    (asset: Art.create, icon: Icons.add_circle_rounded, label: 'Create'),
    (asset: Art.hero, icon: Icons.person_rounded, label: 'Hero'),
    (asset: Art.info, icon: Icons.menu_book_rounded, label: 'Guide'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: 8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xD9140C2E), Color(0xFF0B0718)],
        ),
        border: Border(top: BorderSide(color: AppColors.bronze, width: 1.2)),
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
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Tooltip(
          message: item.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            // Decorations (shadows) must not overshoot: a blur radius below
            // zero asserts. Only the scale below uses an overshooting curve.
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, selected ? -8 : 0, 0),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow:
                  selected
                      ? [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.55),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                      : null,
            ),
            child: AnimatedScale(
              scale: selected ? 1.12 : 0.92,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: selected ? 1 : 0.62,
                duration: const Duration(milliseconds: 200),
                child: Image.asset(
                  item.asset,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, _, _) => Icon(
                        item.icon,
                        size: 30,
                        color: selected ? AppColors.gold : AppColors.ink,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

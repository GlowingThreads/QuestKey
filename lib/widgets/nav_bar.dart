import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navIcons.length, (index) {
          final isSelected = widget.currentIndex == index;
          return GestureDetector(
            onTap: () => widget.onTap(index),
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 200),
              child: Tooltip(
                message: navLabels[index],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.deepPurple.withOpacity(0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        navIcons[index],
                        height: 32,
                        width: 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      navLabels[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white70,
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

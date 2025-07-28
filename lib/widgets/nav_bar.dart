//navigation
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

// assets
class _CustomNavBarState extends State<CustomNavBar> {
  final List<String> navIcons = [
    'assets/images/app_assets/home.png',
    'assets/images/app_assets/quest_log.png',
    'assets/images/app_assets/create.png',
    'assets/images/app_assets/hero.png',
    'assets/images/app_assets/info.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: const Border(top: BorderSide(color: Colors.white24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navIcons.length, (index) {
          return GestureDetector(
            onTap: () => widget.onTap(index),
            child: Opacity(
              opacity: widget.currentIndex == index ? 1.0 : 0.5,
              child: Image.asset(navIcons[index], height: 78, width: 78),
            ),
          );
        }),
      ),
    );
  }
}

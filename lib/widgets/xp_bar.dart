// xp bar in another color - wider
import 'package:flutter/material.dart';

class XpBar extends StatelessWidget {
  final int currentXp;
  final int maxXp;

  const XpBar({super.key, required this.currentXp, required this.maxXp});

  @override
  Widget build(BuildContext context) {
    double progress = (currentXp / maxXp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'XP: $currentXp / $maxXp',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Container(
                height: 30,
                width: MediaQuery.of(context).size.width * progress * 0.6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 98, 0, 234),
                      Color.fromARGB(255, 186, 104, 200),
                      Color.fromARGB(255, 255, 171, 255),
                      Color.fromARGB(255, 255, 255, 255),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(225, 230, 112, 251),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

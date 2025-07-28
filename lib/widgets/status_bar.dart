//status bar item
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    double fillPercent = (value / 20).clamp(0.0, 1.0); // 0-1 range

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text('$value', style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              if (onAdd != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(4),
                  ),
                  onPressed: onAdd,
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Filled gradient
              Container(
                height: 20,
                width:
                    // scale
                    MediaQuery.of(context).size.width * fillPercent * 0.6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.redAccent,
                      Colors.deepOrange,
                      Colors.orange,
                      Colors.yellowAccent,
                      Colors.white70,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.lightGreenAccent.withValues(alpha: 0.6),
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

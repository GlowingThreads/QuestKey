import 'package:flutter/material.dart';
import 'package:popup_card/popup_card.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:provider/provider.dart';

class LevelUpWidget extends StatefulWidget {
  final LevelUp levelUp;

  const LevelUpWidget({super.key, required this.levelUp});

  @override
  State<LevelUpWidget> createState() => _LevelUpWidgetState();
}

// display lvl up
class _LevelUpWidgetState extends State<LevelUpWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  // animation for glow
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowAnimation = Tween(begin: 0.6, end: 1.0).animate(_glowController);

    return GestureDetector(
      onTap: () {
        context.read<AppState>().setIndex(3);
        Navigator.of(context).pop();
      },
      child: PopUpItem(
        color: Colors.transparent,
        tag: 'level_up',
        padding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: FadeTransition(
          opacity: glowAnimation,
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Color.fromARGB(230, 55, 0, 179),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amberAccent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(128, 255, 191, 0),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You are now level ${widget.levelUp.level}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '+${widget.levelUp.statPoints} stat points',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap to continue...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

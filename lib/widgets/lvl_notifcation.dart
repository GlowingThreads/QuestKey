import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/level_up.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// "LEVEL UP!" popup shown in a dialog after a quest completion levels the
/// hero. Bounces in, glows, and jumps to the Hero tab on tap.
class LevelUpWidget extends StatefulWidget {
  final LevelUp levelUp;

  const LevelUpWidget({super.key, required this.levelUp});

  @override
  State<LevelUpWidget> createState() => _LevelUpWidgetState();
}

class _LevelUpWidgetState extends State<LevelUpWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _entrance, curve: Curves.elasticOut);

    return GestureDetector(
      onTap: () {
        context.read<AppState>().setIndex(3);
        Navigator.of(context).pop();
      },
      child: ScaleTransition(
        scale: scale,
        child: Material(
          color: Colors.transparent,
          child: PulseGlow(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            radius: 30,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF37008F), Color(0xFF1D113E)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentAmber, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  const Text(
                    'LEVEL UP!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppColors.accentAmber,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You are now level ${widget.levelUp.level}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentGreen),
                    ),
                    child: Text(
                      '+${LevelUp.statPointsPerLevel} stat points to spend '
                      '(${widget.levelUp.statPoints} available)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap to visit your hero',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

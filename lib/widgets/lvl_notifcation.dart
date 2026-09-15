import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/level_up.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Level-up proclamation: rotating sunburst, the gold arrow illustration
/// rising, and the new level. Tap to go to the Hero tab.
class LevelUpWidget extends StatefulWidget {
  final LevelUp levelUp;

  const LevelUpWidget({super.key, required this.levelUp});

  @override
  State<LevelUpWidget> createState() => _LevelUpWidgetState();
}

class _LevelUpWidgetState extends State<LevelUpWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final AnimationController _rays = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _rays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _entrance, curve: Curves.elasticOut);
    final rise = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.1, 1, curve: Curves.easeOutBack),
    );

    return GestureDetector(
      onTap: () {
        context.read<AppState>().setIndex(3);
        Navigator.of(context).pop();
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _rays,
              builder:
                  (context, _) => Transform.rotate(
                    angle: _rays.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(420, 420),
                      painter: _SunburstPainter(),
                    ),
                  ),
            ),
            ScaleTransition(
              scale: pop,
              child: ArcanePanel(
                accent: AppColors.gold,
                glow: AppColors.gold,
                fillOpacity: 0.94,
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(rise),
                      child: PulseGlow(
                        color: AppColors.gold,
                        radius: 34,
                        child: Image.asset(
                          Art.levelUp,
                          width: 110,
                          height: 110,
                          errorBuilder:
                              (_, _, _) => const Icon(
                                Icons.arrow_upward_rounded,
                                size: 90,
                                color: AppColors.gold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'LEVEL UP',
                      style: AppFonts.heading(
                        size: 30,
                        color: AppColors.gold,
                        weight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const RuneDivider(color: AppColors.gold),
                    const SizedBox(height: 10),
                    Text(
                      'You have reached level ${widget.levelUp.level}',
                      style: AppFonts.body(size: 16),
                    ),
                    const SizedBox(height: 10),
                    RuneTag(
                      text:
                          '+${LevelUp.statPointsPerLevel} STAT POINTS · '
                          '${widget.levelUp.statPoints} TO SPEND',
                      color: AppColors.teal,
                      icon: Icons.stars_rounded,
                      filled: true,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tap to visit your hero',
                      style: AppFonts.body(
                        size: 13,
                        color: AppColors.inkMuted,
                        style: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    const rays = 18;
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0.35),
              AppColors.gold.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r));
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      final path =
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(
              c.dx + math.cos(a - 0.06) * r,
              c.dy + math.sin(a - 0.06) * r,
            )
            ..lineTo(
              c.dx + math.cos(a + 0.06) * r,
              c.dy + math.sin(a + 0.06) * r,
            )
            ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter oldDelegate) => false;
}

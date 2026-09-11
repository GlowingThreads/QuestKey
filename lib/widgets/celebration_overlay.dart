import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';

/// Shows a short burst of confetti over the whole screen. Non-blocking: it
/// ignores pointer events and removes itself when the animation ends.
void showCelebration(BuildContext context, {Duration? duration}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (_) => _ConfettiBurst(
          duration: duration ?? const Duration(milliseconds: 1400),
          onFinished: () {
            if (entry.mounted) entry.remove();
          },
        ),
  );
  overlay.insert(entry);
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({required this.duration, required this.onFinished});

  final Duration duration;
  final VoidCallback onFinished;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const int _count = 48;
  static const List<Color> _palette = [
    AppColors.accentGold,
    AppColors.accentGreen,
    AppColors.shadowPurple,
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.white,
  ];

  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _particles = List.generate(_count, (i) {
      final angle = -pi / 2 + (random.nextDouble() - 0.5) * pi * 0.9;
      final speed = 0.55 + random.nextDouble() * 0.6;
      return _Particle(
        color: _palette[i % _palette.length],
        dx: cos(angle) * speed,
        dy: sin(angle) * speed,
        size: 5 + random.nextDouble() * 6,
        spin: (random.nextDouble() - 0.5) * 12,
        delay: random.nextDouble() * 0.15,
      );
    });
    _controller =
        AnimationController(vsync: this, duration: widget.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) widget.onFinished();
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder:
            (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(_particles, _controller.value),
            ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.color,
    required this.dx,
    required this.dy,
    required this.size,
    required this.spin,
    required this.delay,
  });

  final Color color;
  final double dx;
  final double dy;
  final double size;
  final double spin;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.55);
    final paint = Paint();

    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t == 0) continue;
      // Launch outwards, then let gravity pull the particle down.
      final x = origin.dx + p.dx * size.width * 0.9 * t;
      final y =
          origin.dy + p.dy * size.height * 0.8 * t + size.height * 0.9 * t * t;
      final opacity = (1 - t).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

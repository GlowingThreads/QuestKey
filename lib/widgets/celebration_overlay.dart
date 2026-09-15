import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';

/// Golden embers and teal motes drift up over the screen for a moment.
/// Non-blocking: ignores pointer events and removes itself when done.
void showCelebration(BuildContext context, {Duration? duration}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (_) => _EmberBurst(
          duration: duration ?? const Duration(milliseconds: 1700),
          onFinished: () {
            if (entry.mounted) entry.remove();
          },
        ),
  );
  overlay.insert(entry);
}

class _EmberBurst extends StatefulWidget {
  const _EmberBurst({required this.duration, required this.onFinished});

  final Duration duration;
  final VoidCallback onFinished;

  @override
  State<_EmberBurst> createState() => _EmberBurstState();
}

class _EmberBurstState extends State<_EmberBurst>
    with SingleTickerProviderStateMixin {
  static const int _count = 70;

  late final AnimationController _controller;
  late final List<_Ember> _embers;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _embers = List.generate(_count, (i) {
      final teal = i % 5 == 0;
      return _Ember(
        x: random.nextDouble(),
        drift: (random.nextDouble() - 0.5) * 0.18,
        rise: 0.35 + random.nextDouble() * 0.55,
        size:
            teal ? 2 + random.nextDouble() * 2 : 1.5 + random.nextDouble() * 3,
        delay: random.nextDouble() * 0.4,
        flicker: 3 + random.nextDouble() * 6,
        color:
            teal
                ? AppColors.teal
                : (i % 3 == 0 ? AppColors.magenta : AppColors.gold),
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
              painter: _EmberPainter(_embers, _controller.value),
            ),
      ),
    );
  }
}

class _Ember {
  const _Ember({
    required this.x,
    required this.drift,
    required this.rise,
    required this.size,
    required this.delay,
    required this.flicker,
    required this.color,
  });

  final double x;
  final double drift;
  final double rise;
  final double size;
  final double delay;
  final double flicker;
  final Color color;
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.embers, this.progress);

  final List<_Ember> embers;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // A brief golden flash at the bottom of the screen.
    final flash = (1 - (progress * 3).clamp(0.0, 1.0));
    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppColors.gold.withValues(alpha: 0.25 * flash),
              Colors.transparent,
            ],
          ).createShader(Offset.zero & size),
      );
    }

    for (final e in embers) {
      final t = ((progress - e.delay) / (1 - e.delay)).clamp(0.0, 1.0);
      if (t == 0) continue;
      final eased = Curves.easeOut.transform(t);
      final x =
          (e.x + e.drift * eased + 0.02 * sin(t * e.flicker)) * size.width;
      final y = size.height * (1.05 - e.rise * eased);
      final fade = t < 0.15 ? t / 0.15 : (1 - t);
      final twinkle = 0.6 + 0.4 * sin(t * e.flicker * pi);
      final alpha = (fade * twinkle).clamp(0.0, 1.0);

      paint
        ..color = e.color.withValues(alpha: alpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), e.size * 2.2, paint);
      paint
        ..color = e.color.withValues(alpha: alpha)
        ..maskFilter = null;
      canvas.drawCircle(Offset(x, y), e.size, paint);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => old.progress != progress;
}

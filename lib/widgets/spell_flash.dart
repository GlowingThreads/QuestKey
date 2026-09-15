import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/theme/app_theme.dart';

/// A brief casting flash: a runic ring expands from the centre of the
/// screen while the spell's incantation fades through. Non-blocking.
void showSpellFlash(
  BuildContext context, {
  required Color color,
  String incantation = '',
  Duration duration = const Duration(milliseconds: 1100),
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (_) => _SpellFlash(
          color: color,
          incantation: incantation,
          duration: duration,
          onFinished: () {
            if (entry.mounted) entry.remove();
          },
        ),
  );
  overlay.insert(entry);
}

class _SpellFlash extends StatefulWidget {
  const _SpellFlash({
    required this.color,
    required this.incantation,
    required this.duration,
    required this.onFinished,
  });

  final Color color;
  final String incantation;
  final Duration duration;
  final VoidCallback onFinished;

  @override
  State<_SpellFlash> createState() => _SpellFlashState();
}

class _SpellFlashState extends State<_SpellFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
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
        builder: (context, _) {
          final t = _controller.value;
          // Text fades in over the first third and out over the last.
          final textAlpha =
              t < 0.3
                  ? t / 0.3
                  : t > 0.7
                  ? (1 - t) / 0.3
                  : 1.0;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingPainter(color: widget.color, t: t),
                ),
              ),
              if (widget.incantation.isNotEmpty)
                Center(
                  child: Opacity(
                    opacity: textAlpha.clamp(0.0, 1.0),
                    child: Text(
                      widget.incantation.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppFonts.heading(
                        size: 14,
                        color: AppColors.ink,
                        letterSpacing: 3,
                      ).copyWith(
                        shadows: [Shadow(color: widget.color, blurRadius: 14)],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.55;
    final eased = Curves.easeOutCubic.transform(t);
    final r = maxR * eased;
    final fade = (1 - t).clamp(0.0, 1.0);

    // Vignette flash.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.28 * fade), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: maxR * 1.4)),
    );

    final ring =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.9 * fade);
    canvas.drawCircle(c, r, ring);
    canvas.drawCircle(
      c,
      r * 0.82,
      ring
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.6 * fade),
    );

    // Runic ticks around the outer ring.
    final tick =
        Paint()
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = AppColors.ink.withValues(alpha: 0.8 * fade);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 + eased * math.pi / 2;
      final long = i.isEven;
      canvas.drawLine(
        Offset(
          c.dx + math.cos(a) * (r - (long ? 10 : 6)),
          c.dy + math.sin(a) * (r - (long ? 10 : 6)),
        ),
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.color != color;
}

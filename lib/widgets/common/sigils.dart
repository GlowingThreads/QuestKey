/// Themed pictorial elements that sit beside the `ui_kit` components:
///
/// * [WaxSeal]: an embossed, scalloped seal for honours, coloured by rarity.
/// * [ArcaneCircle]: concentric runic rings that slowly turn behind a spell.
/// * [TorchFlame]: a living flame whose height and colour follow the torch.
/// * [RarityPips]: the small gem row that reads an honour's rarity.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';

// ---------------------------------------------------------------- wax seal

/// A wax seal: scalloped edge, embossed rim, icon pressed into the centre.
class WaxSeal extends StatelessWidget {
  const WaxSeal({
    super.key,
    required this.icon,
    this.color = AppColors.gold,
    this.size = 56,
    this.dimmed = false,
    this.glow = false,
    this.iconColor,
  });

  final IconData icon;
  final Color color;
  final double size;

  /// Grey, unpressed wax (a locked honour).
  final bool dimmed;

  /// Soft halo (the honour being worn as a title).
  final bool glow;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final wax = dimmed ? const Color(0xFF3A3346) : color;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WaxSealPainter(color: wax, glow: glow && !dimmed),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.4,
            color:
                iconColor ??
                (dimmed
                    ? AppColors.inkMuted.withValues(alpha: 0.55)
                    : Color.lerp(wax, AppColors.obsidian, 0.55)),
          ),
        ),
      ),
    );
  }
}

class _WaxSealPainter extends CustomPainter {
  _WaxSealPainter({required this.color, required this.glow});

  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    const scallops = 14;

    final outline = Path();
    for (var i = 0; i <= scallops * 2; i++) {
      final a = (i / (scallops * 2)) * math.pi * 2 - math.pi / 2;
      final rr = i.isEven ? r : r * 0.9;
      final p = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      if (i == 0) {
        outline.moveTo(p.dx, p.dy);
      } else {
        outline.lineTo(p.dx, p.dy);
      }
    }
    outline.close();

    if (glow) {
      canvas.drawPath(
        outline,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Drop shadow so the seal sits on the panel.
    canvas.drawPath(
      outline.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Wax body: lit from the top-left.
    canvas.drawPath(
      outline,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [
            Color.lerp(color, Colors.white, 0.28)!,
            color,
            Color.lerp(color, AppColors.obsidian, 0.5)!,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Embossed inner rim.
    final rim = r * 0.72;
    canvas.drawCircle(
      c,
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, r * 0.05)
        ..color = Color.lerp(color, AppColors.obsidian, 0.45)!,
    );
    canvas.drawCircle(
      c.translate(0, -0.8),
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.03)
        ..color = Color.lerp(color, Colors.white, 0.35)!.withValues(alpha: 0.7),
    );

    // Highlight speck.
    canvas.drawCircle(
      Offset(c.dx - r * 0.38, c.dy - r * 0.42),
      r * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_WaxSealPainter old) =>
      old.color != color || old.glow != glow;
}

/// One to five gems that read rarity at a glance.
class RarityPips extends StatelessWidget {
  const RarityPips({
    super.key,
    required this.rarity,
    this.color = AppColors.gold,
    this.size = 5,
  });

  final int rarity;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.25),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color:
                      i < rarity
                          ? color
                          : AppColors.bronze.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- arcane circle

/// Concentric runic rings that turn slowly behind a spell icon. When
/// [active] is false the rings hold still and dim.
class ArcaneCircle extends StatefulWidget {
  const ArcaneCircle({
    super.key,
    required this.child,
    this.color = AppColors.amethystBright,
    this.size = 52,
    this.active = true,
    this.period = const Duration(seconds: 14),
  });

  final Widget child;
  final Color color;
  final double size;
  final bool active;
  final Duration period;

  @override
  State<ArcaneCircle> createState() => _ArcaneCircleState();
}

class _ArcaneCircleState extends State<ArcaneCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(ArcaneCircle old) {
    super.didUpdateWidget(old);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder:
            (context, child) => CustomPaint(
              painter: _ArcaneCirclePainter(
                color: widget.color,
                turn: _controller.value,
                active: widget.active,
              ),
              child: child,
            ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class _ArcaneCirclePainter extends CustomPainter {
  _ArcaneCirclePainter({
    required this.color,
    required this.turn,
    required this.active,
  });

  final Color color;
  final double turn;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final alpha = active ? 1.0 : 0.35;
    final stroke =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: 0.7 * alpha);

    // Outer ring with tick marks, turning clockwise.
    canvas.drawCircle(c, r - 1, stroke);
    final outerTurn = turn * math.pi * 2;
    for (var i = 0; i < 24; i++) {
      final a = outerTurn + i * math.pi / 12;
      final long = i % 6 == 0;
      final inner = r - (long ? 5 : 3);
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * inner, c.dy + math.sin(a) * inner),
        Offset(c.dx + math.cos(a) * (r - 1), c.dy + math.sin(a) * (r - 1)),
        stroke,
      );
    }

    // Middle ring: dashed, turning the other way.
    final mid = r * 0.74;
    final innerTurn = -turn * math.pi * 2 * 1.5;
    final dash =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.55 * alpha);
    for (var i = 0; i < 8; i++) {
      final start = innerTurn + i * math.pi / 4;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: mid),
        start,
        math.pi / 8,
        false,
        dash,
      );
    }

    // Inner hexagram.
    final hex = r * 0.56;
    final tri =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = color.withValues(alpha: 0.45 * alpha);
    for (final offset in [0.0, math.pi / 3]) {
      final path = Path();
      for (var i = 0; i < 3; i++) {
        final a = outerTurn * 0.5 + offset + i * math.pi * 2 / 3 - math.pi / 2;
        final p = Offset(c.dx + math.cos(a) * hex, c.dy + math.sin(a) * hex);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, tri);
    }

    // Soft core so the icon sits on colour.
    canvas.drawCircle(
      c,
      r * 0.42,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.35 * alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.42)),
    );
  }

  @override
  bool shouldRepaint(_ArcaneCirclePainter old) =>
      old.turn != turn || old.color != color || old.active != active;
}

// ---------------------------------------------------------------- torch flame

/// A living flame. [fraction] (0–1) sets its height and colour: a full
/// torch burns tall and gold, a dying one low and red. It flickers while
/// [animate] is true.
class TorchFlame extends StatefulWidget {
  const TorchFlame({
    super.key,
    required this.fraction,
    this.width = 26,
    this.height = 44,
    this.animate = true,
  });

  final double fraction;
  final double width;
  final double height;
  final bool animate;

  @override
  State<TorchFlame> createState() => _TorchFlameState();
}

class _TorchFlameState extends State<TorchFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(TorchFlame old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder:
            (context, _) => CustomPaint(
              painter: _FlamePainter(
                fraction: widget.fraction.clamp(0.0, 1.0),
                t: _controller.value,
              ),
            ),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.fraction, required this.t});

  final double fraction;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final phase = t * math.pi * 2;
    final flicker = 1 + 0.06 * math.sin(phase * 3) + 0.04 * math.sin(phase * 7);
    final sway = 0.08 * w * math.sin(phase * 2);

    // Flame height: never fully gone so the torch always reads as a torch.
    final flameH = h * (0.3 + 0.7 * fraction) * flicker;
    final baseY = h;
    final tipY = baseY - flameH;
    final halfW = w * (0.32 + 0.18 * fraction);

    final outer = Color.lerp(AppColors.ruby, AppColors.gold, fraction)!;
    final inner =
        Color.lerp(const Color(0xFFFF8A3D), const Color(0xFFFFF1B8), fraction)!;

    Path flame(double scale, double dx) {
      final hw = halfW * scale;
      final fh = flameH * scale;
      final ty = baseY - fh;
      final p = Path()..moveTo(w / 2 - hw, baseY);
      p.cubicTo(
        w / 2 - hw * 1.1,
        baseY - fh * 0.45,
        w / 2 - hw * 0.15 + dx,
        ty + fh * 0.35,
        w / 2 + dx,
        ty,
      );
      p.cubicTo(
        w / 2 + hw * 0.15 + dx,
        ty + fh * 0.35,
        w / 2 + hw * 1.1,
        baseY - fh * 0.45,
        w / 2 + hw,
        baseY,
      );
      p.close();
      return p;
    }

    // Glow.
    canvas.drawCircle(
      Offset(w / 2, baseY - flameH * 0.35),
      halfW * 2.2,
      Paint()
        ..color = outer.withValues(alpha: 0.18 + 0.22 * fraction)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(
      flame(1, sway),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [outer, outer.withValues(alpha: 0.85)],
        ).createShader(Rect.fromLTWH(0, tipY, w, flameH)),
    );
    canvas.drawPath(
      flame(0.62, sway * 0.6),
      Paint()..color = inner.withValues(alpha: 0.95),
    );
    canvas.drawPath(
      flame(0.3, sway * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_FlamePainter old) =>
      old.t != t || old.fraction != fraction;
}

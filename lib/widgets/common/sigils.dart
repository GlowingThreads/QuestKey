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
/// torch burns tall and gold-white, a dying one low and red. It flickers
/// while [animate] is true.
///
/// Drawn from layered tongues whose outlines are displaced by summed sine
/// turbulence, blended additively from a deep red rim to a white core, with
/// embers rising off the tip.
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
  // One full cycle; every frequency below is an integer multiple so the
  // loop is seamless.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
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
                phase: _controller.value * math.pi * 2,
              ),
            ),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.fraction, required this.phase});

  final double fraction;

  /// 0–2π over one seamless loop.
  final double phase;

  /// Summed-sine turbulence in roughly [-1, 1]. [t] runs up the flame,
  /// [seed] separates layers and sides.
  double _noise(double t, double seed) =>
      0.50 * math.sin(3 * phase + 5.0 * t + seed) +
      0.30 * math.sin(7 * phase - 9.0 * t + 2.1 * seed) +
      0.20 * math.sin(13 * phase + 3.0 * t + 3.7 * seed);

  /// Outline of one tongue. [scale] shrinks it towards the core, [lift]
  /// raises its base off the floor, [seed] gives it its own motion.
  Path _tongue({
    required Size size,
    required double scale,
    required double lift,
    required double seed,
    required double turbulence,
    required double dx,
  }) {
    final w = size.width;
    final h = size.height;
    final baseY = h - lift;
    final breathe = 1 + 0.07 * _noise(0.2, seed + 0.5);
    final flameH = h * (0.30 + 0.62 * fraction) * scale * breathe;
    final halfW = w * (0.34 + 0.16 * fraction) * scale;
    final cx = w / 2 + dx;

    // Tip wanders with slow noise and the whole tongue leans; more when
    // the torch is low (guttering).
    final tipSway = halfW * (0.55 + 0.45 * (1 - fraction)) * _noise(1, seed);
    final lean = halfW * 0.3 * _noise(0.7, seed + 2.2);

    const steps = 18;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps; // 0 at the base, 1 at the tip
      // Teardrop envelope: narrow at the wick, fullest a third of the way
      // up, pinching to a point.
      final envelope =
          math.pow(math.sin(math.pi * (0.12 + 0.88 * t)), 0.75) *
          math.pow(1 - t, 0.35);
      // Turbulence grows towards the tip, where fire tears apart.
      final tear = math.pow(t, 1.4).toDouble();
      final wobbleL = 1 + turbulence * (0.25 + tear) * _noise(t, seed);
      final wobbleR = 1 + turbulence * (0.25 + tear) * _noise(t, seed + 9);
      final y = baseY - flameH * t;
      final sway = tipSway * tear + lean * t;
      left.add(Offset(cx + sway - halfW * envelope * wobbleL, y));
      right.add(Offset(cx + sway + halfW * envelope * wobbleR, y));
    }

    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (var i = 1; i < left.length; i++) {
      final prev = left[i - 1];
      final cur = left[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(left.last.dx, left.last.dy);
    for (var i = right.length - 2; i >= 0; i--) {
      final prev = right[i + 1];
      final cur = right[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final flameH = h * (0.30 + 0.62 * fraction);
    final tipY = h - flameH;

    // Colour temperature: a dying torch is red and smoky, a full one is
    // gold with a white heart.
    final rim =
        Color.lerp(const Color(0xFF7A1212), const Color(0xFFD9461C), fraction)!;
    final body =
        Color.lerp(const Color(0xFFE0512A), const Color(0xFFFF9A2E), fraction)!;
    final heart =
        Color.lerp(const Color(0xFFFFB347), const Color(0xFFFFE9A6), fraction)!;
    final core = Color.lerp(const Color(0xFFFFE0B0), Colors.white, fraction)!;

    // Ambient glow on the surface behind the flame.
    canvas.drawCircle(
      Offset(w / 2, h - flameH * 0.4),
      w * (0.55 + 0.35 * fraction),
      Paint()
        ..color = body.withValues(alpha: 0.16 + 0.24 * fraction)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Layers are drawn additively so overlaps brighten like real fire.
    canvas.saveLayer(null, Paint());

    // Outer envelope: soft, red-orange, most turbulent.
    canvas.drawPath(
      _tongue(
        size: size,
        scale: 1,
        lift: 0,
        seed: 0.3,
        turbulence: 0.55,
        dx: 0,
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            rim.withValues(alpha: 0.9),
            body.withValues(alpha: 0.8),
            rim.withValues(alpha: 0.0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromLTWH(0, tipY, w, flameH))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );

    // Two side tongues that lick up and away from the body.
    for (final side in [-1.0, 1.0]) {
      final seed = side < 0 ? 4.2 : 7.9;
      final lick = (_noise(0.5, seed) + 1) / 2; // 0–1
      canvas.drawPath(
        _tongue(
          size: size,
          scale: 0.5 + 0.25 * lick,
          lift: flameH * (0.2 + 0.5 * lick),
          seed: seed,
          turbulence: 0.7,
          dx: side * w * (0.14 + 0.16 * lick),
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              body.withValues(alpha: 0.75),
              rim.withValues(alpha: 0.2 + 0.4 * lick),
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, h))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.9),
      );
    }

    // Body: orange to yellow.
    canvas.drawPath(
      _tongue(
        size: size,
        scale: 0.8,
        lift: 0,
        seed: 1.7,
        turbulence: 0.4,
        dx: 0,
      ),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            body.withValues(alpha: 0.55),
            heart.withValues(alpha: 0.55),
            body.withValues(alpha: 0.0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromLTWH(0, tipY, w, flameH)),
    );

    // Heart: bright yellow, quicker flicker.
    canvas.drawPath(
      _tongue(
        size: size,
        scale: 0.55,
        lift: 0,
        seed: 2.9,
        turbulence: 0.3,
        dx: 0,
      ),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = heart.withValues(alpha: 0.75),
    );

    // Core: near white, hugging the base.
    canvas.drawPath(
      _tongue(
        size: size,
        scale: 0.3,
        lift: 0,
        seed: 5.1,
        turbulence: 0.15,
        dx: 0,
      ),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = core.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
    );

    canvas.restore();

    // Blue root where the flame meets the wick.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h - 1.5),
        width: w * 0.36,
        height: 4,
      ),
      Paint()
        ..color = const Color(
          0xFF5FA8FF,
        ).withValues(alpha: 0.35 + 0.3 * fraction)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    // Embers rising off the tip, more of them when the torch is strong.
    final emberCount = 2 + (4 * fraction).round();
    final ember = Paint();
    for (var i = 0; i < emberCount; i++) {
      final offset = i / emberCount;
      final life = (phase / (2 * math.pi) * (1 + i % 3) + offset) % 1.0;
      final drift = math.sin(phase * 2 + i * 1.3) * w * 0.18;
      final x = w / 2 + drift * life + (i.isEven ? 1 : -1) * w * 0.08;
      final y = tipY + flameH * 0.25 - life * h * 0.55;
      if (y < 0) continue;
      final alpha = (1 - life) * (life < 0.1 ? life / 0.1 : 1);
      ember.color = heart.withValues(alpha: alpha * 0.9);
      canvas.drawCircle(Offset(x, y), 0.9 + (1 - life) * 0.8, ember);
    }
  }

  @override
  bool shouldRepaint(_FlamePainter old) =>
      old.phase != phase || old.fraction != fraction;
}

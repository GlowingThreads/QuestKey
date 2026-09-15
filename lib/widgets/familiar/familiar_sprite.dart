/// The familiar, drawn as a shadow creature with glowing eyes.
///
/// Three species are painted procedurally so the app needs no extra art.
/// If a sprite strip exists at `assets/images/familiars/<species>.png`
/// (square frames side by side) it is shown instead, so hand-drawn
/// animation can replace the painter without code changes.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/familiar.dart';

class FamiliarSprite extends StatefulWidget {
  const FamiliarSprite({
    super.key,
    required this.species,
    this.mood = FamiliarMood.content,
    this.size = 96,
    this.animate = true,
    this.dimmed = false,
    this.hopTrigger = 0,
    this.onTap,
  });

  final FamiliarSpecies species;
  final FamiliarMood mood;
  final double size;
  final bool animate;

  /// Grey, unlit (the stray before adoption).
  final bool dimmed;

  /// Increment to make the familiar hop.
  final int hopTrigger;
  final VoidCallback? onTap;

  /// Asset path of the optional sprite strip for [species].
  static String stripAsset(FamiliarSpecies species) =>
      'assets/images/familiars/${species.name}.png';

  @override
  State<FamiliarSprite> createState() => _FamiliarSpriteState();
}

class _FamiliarSpriteState extends State<FamiliarSprite>
    with TickerProviderStateMixin {
  // One idle cycle; frequencies inside are integers so the loop is seamless.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  Future<bool>? _hasStrip;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _idle.repeat();
    _hasStrip = _checkStrip();
  }

  Future<bool> _checkStrip() async {
    try {
      await rootBundle.load(FamiliarSprite.stripAsset(widget.species));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void didUpdateWidget(FamiliarSprite old) {
    super.didUpdateWidget(old);
    if (widget.species != old.species) _hasStrip = _checkStrip();
    if (widget.animate && !_idle.isAnimating) {
      _idle.repeat();
    } else if (!widget.animate && _idle.isAnimating) {
      _idle.stop();
    }
    if (widget.hopTrigger != old.hopTrigger) _hop.forward(from: 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _hop.dispose();
    super.dispose();
  }

  void _tapped() {
    _hop.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null ? null : _tapped,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<bool>(
          future: _hasStrip,
          initialData: false,
          builder: (context, snapshot) {
            final strip = snapshot.data == true;
            return AnimatedBuilder(
              animation: Listenable.merge([_idle, _hop]),
              builder: (context, _) {
                final hopT = _hop.value;
                final hop = math.sin(math.pi * hopT) * widget.size * 0.14;
                return Transform.translate(
                  offset: Offset(0, -hop),
                  child:
                      strip
                          ? _SpriteStrip(
                            asset: FamiliarSprite.stripAsset(widget.species),
                            t: _idle.value,
                            dimmed: widget.dimmed,
                          )
                          : CustomPaint(
                            painter: _FamiliarPainter(
                              species: widget.species,
                              mood: widget.mood,
                              phase: _idle.value * math.pi * 2,
                              hop: hopT,
                              dimmed: widget.dimmed,
                            ),
                          ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// A horizontal strip of square frames, played at eight frames a second.
class _SpriteStrip extends StatelessWidget {
  const _SpriteStrip({
    required this.asset,
    required this.t,
    required this.dimmed,
  });

  final String asset;
  final double t;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        return Opacity(
          opacity: dimmed ? 0.45 : 1,
          child: ClipRect(
            child: Image.asset(
              asset,
              height: side,
              fit: BoxFit.fitHeight,
              alignment: Alignment.centerLeft,
              frameBuilder: (context, child, frame, sync) {
                // Frame count = strip width / height; we learn it once the
                // image resolves by measuring through an ImageStream is
                // overkill, so the strip is assumed to hold 8 frames.
                const frames = 8;
                final index = (t * 6 * 8).floor() % frames;
                return Transform.translate(
                  offset: Offset(-index * side, 0),
                  child: child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FamiliarPainter extends CustomPainter {
  _FamiliarPainter({
    required this.species,
    required this.mood,
    required this.phase,
    required this.hop,
    required this.dimmed,
  });

  final FamiliarSpecies species;
  final FamiliarMood mood;

  /// 0–2π over one idle loop.
  final double phase;

  /// 0–1 while hopping, else 0.
  final double hop;
  final bool dimmed;

  // Palette.
  Color get _body => dimmed ? const Color(0xFF2A2536) : const Color(0xFF1B1030);
  Color get _bodyLight => dimmed ? const Color(0xFF3A3346) : AppColors.amethyst;
  Color get _edge =>
      dimmed ? const Color(0xFF4A4358) : AppColors.amethystBright;
  Color get _eye => switch (species) {
    FamiliarSpecies.cat => AppColors.teal,
    FamiliarSpecies.hound => AppColors.gold,
    FamiliarSpecies.owl => AppColors.gold,
  };

  /// 0 = open, 1 = shut. One slow blink per loop, a second quick one on
  /// the owl and cat, plus the sleepy half-lid.
  double get _lid {
    final t = phase / (2 * math.pi);
    double blinkAt(double centre, double width) {
      final d = (t - centre).abs();
      if (d > width) return 0;
      return math.sin(math.pi * (1 - d / width) / 2);
    }

    var lid = blinkAt(0.35, 0.03);
    if (species != FamiliarSpecies.hound) {
      lid = math.max(lid, blinkAt(0.72, 0.02) * 0.9);
    }
    final base = switch (mood) {
      FamiliarMood.sleepy => 0.55,
      FamiliarMood.watchful => 0.0,
      _ => 0.08,
    };
    return math.max(lid, base).clamp(0.0, 1.0);
  }

  double get _speed => mood == FamiliarMood.joyful ? 2.5 : 1;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Work in a 100×100 box.
    final s = size.shortestSide / 100;
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    // Squash on landing, breathe at rest, bounce when joyful.
    final breathe = 1 + 0.012 * math.sin(phase * 2);
    final squash =
        hop > 0.8 ? 1 - 0.08 * math.sin(math.pi * (hop - 0.8) / 0.2) : 1;
    final bounce =
        mood == FamiliarMood.joyful ? -2.5 * math.sin(phase * 4).abs() : 0.0;
    final slump = mood == FamiliarMood.sleepy ? 2.0 : 0.0;
    canvas.translate(50, 100 + bounce + slump);
    canvas.scale(1 / squash, breathe * squash);
    canvas.translate(-50, -100);

    switch (species) {
      case FamiliarSpecies.cat:
        _paintCat(canvas);
      case FamiliarSpecies.hound:
        _paintHound(canvas);
      case FamiliarSpecies.owl:
        _paintOwl(canvas);
    }
    canvas.restore();
  }

  Paint _fill(Color c) => Paint()..color = c;

  /// Body gradient: lit from above with an amethyst rim.
  Paint _bodyPaint(Rect bounds) =>
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.5),
          radius: 1.1,
          colors: [Color.lerp(_bodyLight, _body, 0.4)!, _body, _body],
          stops: const [0, 0.7, 1],
        ).createShader(bounds);

  void _glow(Canvas canvas, Path silhouette) {
    if (dimmed) return;
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = _edge.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5),
    );
  }

  void _eyes(
    Canvas canvas, {
    required Offset left,
    required Offset right,
    required double w,
    required double h,
    required bool slit,
  }) {
    final open = (1 - _lid).clamp(0.05, 1.0);
    final wide = mood == FamiliarMood.watchful ? 1.15 : 1.0;
    for (final c in [left, right]) {
      final rect = Rect.fromCenter(
        center: c,
        width: w * wide,
        height: h * wide * open,
      );
      if (!dimmed) {
        canvas.drawOval(
          rect.inflate(2.5),
          Paint()
            ..color = _eye.withValues(alpha: 0.45 * open)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      canvas.drawOval(rect, _fill(dimmed ? const Color(0xFF6C6480) : _eye));
      // Pupil.
      if (open > 0.3) {
        final pupil =
            slit
                ? Rect.fromCenter(
                  center: c,
                  width: w * 0.18,
                  height: h * open * 0.8,
                )
                : Rect.fromCenter(
                  center: c.translate(0, h * 0.05),
                  width: w * 0.45,
                  height: h * open * 0.6,
                );
        canvas.drawOval(pupil, _fill(_body));
        canvas.drawCircle(
          c.translate(-w * 0.18, -h * 0.2),
          w * 0.08,
          _fill(Colors.white.withValues(alpha: 0.8 * open)),
        );
      }
    }
  }

  // ---------------------------------------------------------------- cat

  void _paintCat(Canvas canvas) {
    final wag = math.sin(phase * 2 * _speed) * 9;
    final earTwitch =
        phase > 4.0 && phase < 4.6
            ? math.sin((phase - 4.0) / 0.6 * math.pi)
            : 0.0;

    // Tail: from the haunch, curling up on the right.
    final tail =
        Path()
          ..moveTo(68, 90)
          ..cubicTo(90, 88, 92 + wag, 60, 78 + wag * 0.6, 48);
    final tailPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = _body;
    canvas.drawPath(tail, tailPaint);
    canvas.drawPath(
      tail,
      tailPaint
        ..strokeWidth = 3
        ..color = _bodyLight.withValues(alpha: 0.5),
    );

    // Body and head silhouette.
    final body = Rect.fromCenter(
      center: const Offset(50, 72),
      width: 46,
      height: 54,
    );
    final head = Rect.fromCircle(center: const Offset(50, 42), radius: 19);
    final silhouette =
        Path()
          ..addOval(body)
          ..addOval(head)
          ..addPolygon(const [
            Offset(34, 34),
            Offset(29, 10),
            Offset(47, 26),
          ], true)
          ..addPolygon([
            const Offset(66, 34),
            Offset(71 + earTwitch * 3, 10 + earTwitch * 3),
            const Offset(53, 26),
          ], true);
    _glow(canvas, silhouette);
    canvas.drawPath(silhouette, _bodyPaint(body.expandToInclude(head)));

    // Inner ears, chest and paws.
    canvas.drawPath(
      Path()..addPolygon(const [
        Offset(36, 31),
        Offset(33, 16),
        Offset(45, 27),
      ], true),
      _fill(_edge.withValues(alpha: 0.45)),
    );
    canvas.drawPath(
      Path()..addPolygon([
        const Offset(64, 31),
        Offset(67 + earTwitch * 2, 16 + earTwitch * 2),
        const Offset(55, 27),
      ], true),
      _fill(_edge.withValues(alpha: 0.45)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 80), width: 24, height: 30),
      _fill(_bodyLight.withValues(alpha: 0.35)),
    );
    for (final x in [40.0, 60.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 96), width: 15, height: 8),
        _fill(_body),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 95), width: 11, height: 4),
        _fill(_bodyLight.withValues(alpha: 0.5)),
      );
    }

    _eyes(
      canvas,
      left: const Offset(42, 42),
      right: const Offset(58, 42),
      w: 9,
      h: 6,
      slit: true,
    );
    // Nose and whiskers.
    canvas.drawPath(
      Path()..addPolygon(const [
        Offset(47.5, 49),
        Offset(52.5, 49),
        Offset(50, 52),
      ], true),
      _fill(_edge),
    );
    final whisker =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = AppColors.inkMuted.withValues(alpha: 0.5);
    for (final dy in [-2.0, 1.0, 4.0]) {
      canvas.drawLine(Offset(44, 50 + dy), Offset(30, 48 + dy * 1.6), whisker);
      canvas.drawLine(Offset(56, 50 + dy), Offset(70, 48 + dy * 1.6), whisker);
    }
  }

  // ---------------------------------------------------------------- hound

  void _paintHound(Canvas canvas) {
    final wag =
        math.sin(phase * 3 * _speed) *
        (mood == FamiliarMood.sleepy ? 0.1 : 0.4);
    final earSwing = math.sin(phase * 2) * 0.05;

    // Tail: a tapered stroke rotating about its base.
    canvas.save();
    canvas.translate(70, 88);
    canvas.rotate(-0.9 + wag);
    final tail =
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(14, -6, 26, -2);
    canvas.drawPath(
      tail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = _body,
    );
    canvas.restore();

    final body = Rect.fromCenter(
      center: const Offset(50, 74),
      width: 50,
      height: 52,
    );
    final head = Rect.fromCircle(center: const Offset(50, 40), radius: 20);
    final muzzle = Rect.fromCenter(
      center: const Offset(50, 50),
      width: 24,
      height: 17,
    );
    final silhouette =
        Path()
          ..addOval(body)
          ..addOval(head)
          ..addOval(muzzle);
    _glow(canvas, silhouette);
    canvas.drawPath(silhouette, _bodyPaint(body.expandToInclude(head)));

    // Floppy ears hanging from the crown, swinging a little.
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(50 + side * 17, 26);
      canvas.rotate(side * (0.25 + earSwing));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, 0, 14, 30),
          const Radius.circular(7),
        ),
        _fill(Color.lerp(_body, Colors.black, 0.25)!),
      );
      canvas.restore();
    }

    // Chest and paws.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 82), width: 26, height: 28),
      _fill(_bodyLight.withValues(alpha: 0.35)),
    );
    for (final x in [39.0, 61.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 96), width: 16, height: 8),
        _fill(_body),
      );
    }

    // Muzzle highlight, nose, mouth.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 51), width: 20, height: 13),
      _fill(_bodyLight.withValues(alpha: 0.45)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 46.5), width: 8, height: 6),
      _fill(const Color(0xFF0A0612)),
    );
    canvas.drawCircle(
      const Offset(48.5, 45.5),
      1.1,
      _fill(Colors.white.withValues(alpha: 0.6)),
    );
    if (mood == FamiliarMood.joyful || mood == FamiliarMood.content) {
      // Tongue.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(52, 58 + math.sin(phase * 6).abs()),
            width: 7,
            height: 9,
          ),
          const Radius.circular(3.5),
        ),
        _fill(const Color(0xFFE07A9A)),
      );
    }

    _eyes(
      canvas,
      left: const Offset(42, 38),
      right: const Offset(58, 38),
      w: 8,
      h: 8,
      slit: false,
    );
  }

  // ---------------------------------------------------------------- owl

  void _paintOwl(Canvas canvas) {
    // Perch.
    canvas.drawLine(
      const Offset(18, 93),
      const Offset(82, 93),
      Paint()
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.bronze,
    );

    final body = Rect.fromCenter(
      center: const Offset(50, 60),
      width: 50,
      height: 64,
    );
    final silhouette =
        Path()
          ..addOval(body)
          ..addPolygon(const [
            Offset(33, 32),
            Offset(28, 14),
            Offset(43, 26),
          ], true)
          ..addPolygon(const [
            Offset(67, 32),
            Offset(72, 14),
            Offset(57, 26),
          ], true);
    _glow(canvas, silhouette);
    canvas.drawPath(silhouette, _bodyPaint(body));

    // Wings: folded arcs, lifting slightly when joyful.
    final lift =
        mood == FamiliarMood.joyful ? math.sin(phase * 4).abs() * 3 : 0.0;
    for (final side in [-1.0, 1.0]) {
      final wing =
          Path()
            ..moveTo(50 + side * 22, 46 - lift)
            ..quadraticBezierTo(50 + side * (30 + lift), 66, 50 + side * 18, 86)
            ..quadraticBezierTo(50 + side * 12, 70, 50 + side * 22, 46 - lift)
            ..close();
      canvas.drawPath(wing, _fill(Color.lerp(_body, Colors.black, 0.3)!));
    }

    // Chest chevrons.
    final chevron =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _bodyLight.withValues(alpha: 0.55);
    for (var row = 0; row < 3; row++) {
      final y = 66 + row * 7.0;
      for (final x in [43.0, 50.0, 57.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 3, y)
            ..lineTo(x, y + 3)
            ..lineTo(x + 3, y),
          chevron,
        );
      }
    }

    // Face: tilts now and then.
    final tiltWindow = phase > 1.5 && phase < 3.0;
    final tilt =
        tiltWindow ? 0.16 * math.sin((phase - 1.5) / 1.5 * math.pi) : 0.0;
    canvas.save();
    canvas.translate(50, 44);
    canvas.rotate(tilt);
    canvas.translate(-50, -44);
    for (final x in [40.0, 60.0]) {
      canvas.drawCircle(
        Offset(x, 44),
        12.5,
        _fill(_bodyLight.withValues(alpha: 0.5)),
      );
    }
    _eyes(
      canvas,
      left: const Offset(40, 44),
      right: const Offset(60, 44),
      w: 15,
      h: 15,
      slit: false,
    );
    // Beak.
    canvas.drawPath(
      Path()..addPolygon(const [
        Offset(46, 51),
        Offset(54, 51),
        Offset(50, 58),
      ], true),
      _fill(AppColors.bronzeLight),
    );
    canvas.restore();

    // Feet on the perch.
    final foot =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = AppColors.bronzeLight;
    for (final x in [42.0, 58.0]) {
      for (final dx in [-3.0, 0.0, 3.0]) {
        canvas.drawLine(Offset(x, 89), Offset(x + dx, 94), foot);
      }
    }
  }

  @override
  bool shouldRepaint(_FamiliarPainter old) =>
      old.phase != phase ||
      old.hop != hop ||
      old.mood != mood ||
      old.species != species ||
      old.dimmed != dimmed;
}

/// One familiar, drawn in its current pose.
///
/// Picks a renderer at start-up, in this order:
/// 1. a sprite sheet (`assets/images/familiars/<species>.png` + `.json`),
/// 2. a Rive file (`assets/images/familiars/<species>.riv`), used only when
///    the Rive runtime can actually load it,
/// 3. the built-in painter: a shadow creature with glowing eyes.
///
/// The pose comes from [FamiliarBehaviour] via the stage; this widget only
/// draws. Facing is handled by the stage, which mirrors the widget.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/familiar.dart';
import 'package:quest_key/widgets/familiar/familiar_behaviour.dart';
import 'package:quest_key/widgets/familiar/rive_familiar.dart';
import 'package:quest_key/widgets/familiar/sprite_sheet.dart';
import 'package:rive/rive.dart' show RiveFile;

enum FamiliarRenderer { painter, sheet, rive }

/// Lets the stage ask a sprite which way its art faces as drawn.
abstract class FamiliarSpriteFacing {
  bool get artFacesRight;
}

class FamiliarSprite extends StatefulWidget {
  const FamiliarSprite({
    super.key,
    required this.species,
    this.mood = FamiliarMood.content,
    this.action = FamiliarAction.idle,
    this.walkPhase = 0,
    this.hopProgress = 0,
    this.facingRight = true,
    this.size = 96,
    this.animate = true,
    this.dimmed = false,
    this.hopTrigger = 0,
  });

  final FamiliarSpecies species;
  final FamiliarMood mood;
  final FamiliarAction action;
  final double walkPhase;
  final double hopProgress;
  final bool facingRight;
  final double size;
  final bool animate;

  /// Grey, unlit (the stray before adoption).
  final bool dimmed;

  /// Changes when the familiar should hop (forwarded to Rive files).
  final int hopTrigger;

  /// Asset path of the optional Rive file for [species].
  static String riveAsset(FamiliarSpecies species) =>
      'assets/images/familiars/${species.name}.riv';

  static final Map<FamiliarSpecies, Future<RiveFile?>> _riveFiles = {};

  /// The parsed Rive file for [species], or `null` when there is none or the
  /// Rive runtime can't load it (for example when its native library is
  /// missing, as under `flutter test`). Loaded once per species.
  static Future<RiveFile?> loadRive(FamiliarSpecies species) =>
      _riveFiles.putIfAbsent(species, () => _loadRive(species));

  static Future<RiveFile?> _loadRive(FamiliarSpecies species) async {
    final path = riveAsset(species);
    final ByteData bytes;
    try {
      bytes = await rootBundle.load(path);
    } catch (_) {
      return null; // No file for this species: use the painter.
    }
    try {
      // Parse before RiveFile.initialize(): without the native runtime,
      // import throws here (catchable), whereas initialize() fails with an
      // uncaught async error and never completes. Text, if any, is shaped
      // on the first frame, after initialize() below has run.
      final file = RiveFile.import(bytes);
      await RiveFile.initialize();
      return file;
    } catch (e) {
      debugPrint('Familiar: could not load $path, using the painter ($e)');
      return null;
    }
  }

  /// Which way the built-in art faces: side-view species face right.
  static bool painterFacesRight(FamiliarSpecies species) => true;

  @override
  State<FamiliarSprite> createState() => _FamiliarSpriteState();
}

class _FamiliarSpriteState extends State<FamiliarSprite>
    with SingleTickerProviderStateMixin
    implements FamiliarSpriteFacing {
  // One idle cycle; frequencies inside are integers so the loop is seamless.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  FamiliarRenderer _renderer = FamiliarRenderer.painter;
  SpriteSheet? _sheet;
  RiveFile? _riveFile;
  double _seconds = 0;
  double _lastIdle = 0;

  @override
  void initState() {
    super.initState();
    _idle.addListener(_advanceClock);
    if (widget.animate) _idle.repeat();
    _pickRenderer();
  }

  void _advanceClock() {
    // A monotonic clock for sheet playback that survives the loop wrap.
    var delta = _idle.value - _lastIdle;
    if (delta < 0) delta += 1;
    _lastIdle = _idle.value;
    _seconds += delta * _idle.duration!.inMilliseconds / 1000;
  }

  Future<void> _pickRenderer() async {
    final species = widget.species;
    final sheet = await SpriteSheet.load(species.name);
    if (!mounted || widget.species != species) return;
    if (sheet != null) {
      setState(() {
        _sheet = sheet;
        _renderer = FamiliarRenderer.sheet;
      });
      return;
    }
    final riveFile = await FamiliarSprite.loadRive(species);
    if (!mounted || widget.species != species) return;
    setState(() {
      _riveFile = riveFile;
      _renderer =
          riveFile != null ? FamiliarRenderer.rive : FamiliarRenderer.painter;
    });
  }

  @override
  void didUpdateWidget(FamiliarSprite old) {
    super.didUpdateWidget(old);
    if (widget.species != old.species) {
      _sheet = null;
      _riveFile = null;
      _renderer = FamiliarRenderer.painter;
      _pickRenderer();
    }
    if (widget.animate && !_idle.isAnimating) {
      _idle.repeat();
    } else if (!widget.animate && _idle.isAnimating) {
      _idle.stop();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  bool get artFacesRight => switch (_renderer) {
    FamiliarRenderer.sheet => _sheet?.manifest.facesRight ?? true,
    FamiliarRenderer.rive => true,
    FamiliarRenderer.painter => true,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _idle,
        builder: (context, _) {
          switch (_renderer) {
            case FamiliarRenderer.sheet:
              return CustomPaint(
                painter: SpriteSheetPainter(
                  sheet: _sheet!,
                  action: widget.action,
                  seconds: _seconds,
                  dimmed: widget.dimmed,
                ),
              );
            case FamiliarRenderer.rive:
              return RiveFamiliar(
                file: _riveFile!,
                action: widget.action,
                mood: widget.mood,
                facingRight: widget.facingRight,
                hopTrigger: widget.hopTrigger,
                dimmed: widget.dimmed,
              );
            case FamiliarRenderer.painter:
              return CustomPaint(
                painter: FamiliarPainter(
                  species: widget.species,
                  mood: widget.mood,
                  action: widget.action,
                  walkPhase: widget.walkPhase,
                  hop: widget.hopProgress,
                  phase: _idle.value * math.pi * 2,
                  dimmed: widget.dimmed,
                ),
              );
          }
        },
      ),
    );
  }
}

/// The built-in shadow-creature painter. Public so previews can drive it.
class FamiliarPainter extends CustomPainter {
  FamiliarPainter({
    required this.species,
    required this.mood,
    required this.phase,
    this.action = FamiliarAction.idle,
    this.walkPhase = 0,
    this.hop = 0,
    this.dimmed = false,
  });

  final FamiliarSpecies species;
  final FamiliarMood mood;
  final FamiliarAction action;

  /// 0–2π over one idle loop.
  final double phase;

  /// Accumulated while walking (leg cycle).
  final double walkPhase;

  /// 0–1 while hopping, else 0.
  final double hop;
  final bool dimmed;

  // Pose, computed once per paint.
  double _bob = 0;
  double _lean = 0;
  double _pawSwing = 0;
  double _pawLift = 0;
  double _headDip = 0;
  bool _sleeping = false;

  // Palette.
  Color get _body => dimmed ? const Color(0xFF2A2536) : const Color(0xFF1B1030);
  Color get _bodyLight => dimmed ? const Color(0xFF3A3346) : AppColors.amethyst;
  Color get _edge =>
      dimmed ? const Color(0xFF4A4358) : AppColors.amethystBright;
  Color get _eye => switch (species) {
    FamiliarSpecies.cat => AppColors.teal,
    FamiliarSpecies.weasel => AppColors.teal,
    FamiliarSpecies.hound => AppColors.gold,
    FamiliarSpecies.owl => AppColors.gold,
  };

  /// 0 = open, 1 = shut. One slow blink per loop, a second quick one on
  /// some species, the sleepy half-lid, and shut while asleep.
  double get _lid {
    if (_sleeping) return 1;
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
    final walking = action == FamiliarAction.walk;
    final cycle = walkPhase * math.pi * 2;
    _bob = walking ? -math.sin(cycle).abs() * 2.5 : 0;
    // Owls hop along their perch rather than lean into a stride.
    _lean =
        walking && species != FamiliarSpecies.owl ? 0.05 * math.sin(cycle) : 0;
    _pawSwing = walking ? math.sin(cycle) * 3.5 : 0;
    _sleeping = action == FamiliarAction.sleep;
    _headDip = action == FamiliarAction.groom ? 0.35 : 0;
    _pawLift = action == FamiliarAction.groom ? 9 : 0;

    canvas.save();
    // Work in a 100×100 box.
    final s = size.shortestSide / 100;
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    // Squash on landing, breathe at rest, bounce when joyful, lie down to
    // sleep, lengthen to stretch.
    final breathe = 1 + (_sleeping ? 0.02 : 0.012) * math.sin(phase * 2);
    final squash =
        hop > 0.8 ? 1 - 0.08 * math.sin(math.pi * (hop - 0.8) / 0.2) : 1.0;
    final bounce =
        mood == FamiliarMood.joyful && !_sleeping
            ? -2.5 * math.sin(phase * 4).abs()
            : 0.0;
    final slump = mood == FamiliarMood.sleepy ? 2.0 : 0.0;
    var sx = 1.0;
    var sy = 1.0;
    if (_sleeping) {
      sx = 1.12;
      sy = 0.74;
    } else if (action == FamiliarAction.stretch) {
      sx = 1.16;
      sy = 0.9;
    }
    canvas.translate(50, 100 + bounce + slump + _bob);
    canvas.rotate(_lean);
    canvas.scale(sx / squash, sy * breathe * squash);
    canvas.translate(-50, -100);

    switch (species) {
      case FamiliarSpecies.cat:
        _paintCat(canvas);
      case FamiliarSpecies.hound:
        _paintHound(canvas);
      case FamiliarSpecies.weasel:
        _paintWeasel(canvas);
      case FamiliarSpecies.owl:
        _paintOwl(canvas);
    }
    canvas.restore();

    if (_sleeping) _paintZs(canvas, size);
  }

  void _paintZs(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    for (var i = 0; i < 2; i++) {
      final t = ((phase / (2 * math.pi)) * 2 + i * 0.5) % 1.0;
      final alpha = (1 - t) * (t < 0.15 ? t / 0.15 : 1);
      final x = (68 + i * 8 + math.sin(t * math.pi * 2) * 4) * s;
      final y = (40 - t * 26 - i * 6) * s;
      final z = 4.5 * s * (0.8 + t * 0.6);
      final path =
          Path()
            ..moveTo(x, y)
            ..lineTo(x + z, y)
            ..lineTo(x, y + z)
            ..lineTo(x + z, y + z);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3 * s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = _edge.withValues(alpha: 0.85 * alpha),
      );
    }
  }

  Paint _fill(Color c) => Paint()..color = c;

  /// Body gradient: lit softly from above.
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

  void _eyeAt(Canvas canvas, Offset c, double w, double h, bool slit) {
    final open = (1 - _lid).clamp(0.05, 1.0);
    final wide = mood == FamiliarMood.watchful ? 1.15 : 1.0;
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

  void _eyes(
    Canvas canvas, {
    required Offset left,
    required Offset right,
    required double w,
    required double h,
    required bool slit,
  }) {
    _eyeAt(canvas, left, w, h, slit);
    _eyeAt(canvas, right, w, h, slit);
  }

  /// Runs [draw] with the head dipped for grooming.
  void _head(Canvas canvas, Offset pivot, void Function() draw) {
    canvas.save();
    if (_headDip != 0) {
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(_headDip);
      canvas.translate(-pivot.dx + 2, -pivot.dy + 5);
    }
    draw();
    canvas.restore();
  }

  void _paws(Canvas canvas, List<double> xs, double y, double w, double h) {
    for (var i = 0; i < xs.length; i++) {
      final swing = i.isEven ? _pawSwing : -_pawSwing;
      final lift = i == 0 ? _pawLift : 0.0;
      final c = Offset(xs[i] + swing, y - lift);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w, height: h),
        _fill(_body),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: c.translate(0, -1),
          width: w * 0.7,
          height: h * 0.5,
        ),
        _fill(_bodyLight.withValues(alpha: 0.5)),
      );
    }
  }

  // ---------------------------------------------------------------- cat

  void _paintCat(Canvas canvas) {
    final wag = math.sin(phase * 2 * _speed) * (_sleeping ? 3 : 9);
    final earTwitch =
        phase > 4.0 && phase < 4.6
            ? math.sin((phase - 4.0) / 0.6 * math.pi)
            : 0.0;

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

    final body = Rect.fromCenter(
      center: const Offset(50, 72),
      width: 46,
      height: 54,
    );
    final bodyPath = Path()..addOval(body);
    _glow(canvas, bodyPath);
    canvas.drawPath(bodyPath, _bodyPaint(body));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 80), width: 24, height: 30),
      _fill(_bodyLight.withValues(alpha: 0.35)),
    );
    _paws(canvas, [40, 60], 96, 15, 8);

    _head(canvas, const Offset(50, 56), () {
      final head = Rect.fromCircle(center: const Offset(50, 42), radius: 19);
      final headPath =
          Path()
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
      _glow(canvas, headPath);
      canvas.drawPath(headPath, _bodyPaint(head.inflate(12)));
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
      _eyes(
        canvas,
        left: const Offset(42, 42),
        right: const Offset(58, 42),
        w: 9,
        h: 6,
        slit: true,
      );
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
        canvas.drawLine(
          Offset(44, 50 + dy),
          Offset(30, 48 + dy * 1.6),
          whisker,
        );
        canvas.drawLine(
          Offset(56, 50 + dy),
          Offset(70, 48 + dy * 1.6),
          whisker,
        );
      }
    });
  }

  // ---------------------------------------------------------------- hound

  void _paintHound(Canvas canvas) {
    final wag =
        math.sin(phase * 3 * _speed) *
        (mood == FamiliarMood.sleepy || _sleeping ? 0.1 : 0.4);
    final earSwing = math.sin(phase * 2) * 0.05;

    canvas.save();
    canvas.translate(70, 88);
    canvas.rotate(-0.9 + wag);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(14, -6, 26, -2),
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
    final bodyPath = Path()..addOval(body);
    _glow(canvas, bodyPath);
    canvas.drawPath(bodyPath, _bodyPaint(body));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 82), width: 26, height: 28),
      _fill(_bodyLight.withValues(alpha: 0.35)),
    );
    _paws(canvas, [39, 61], 96, 16, 8);

    _head(canvas, const Offset(50, 56), () {
      final head = Rect.fromCircle(center: const Offset(50, 40), radius: 20);
      final muzzle = Rect.fromCenter(
        center: const Offset(50, 50),
        width: 24,
        height: 17,
      );
      final headPath =
          Path()
            ..addOval(head)
            ..addOval(muzzle);
      _glow(canvas, headPath);
      canvas.drawPath(headPath, _bodyPaint(head));
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
      if (!_sleeping &&
          (mood == FamiliarMood.joyful || mood == FamiliarMood.content)) {
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
    });
  }

  // ---------------------------------------------------------------- weasel

  /// Drawn in profile, facing right; the stage mirrors it to face left.
  void _paintWeasel(Canvas canvas) {
    final wag = math.sin(phase * 2 * _speed) * (_sleeping ? 2 : 6);

    // Tail: long, curling up behind on the left.
    final tail =
        Path()
          ..moveTo(24, 82)
          ..cubicTo(6, 84, 2 + wag, 62, 14 + wag, 50);
    final tailPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = _body;
    canvas.drawPath(tail, tailPaint);
    canvas.drawPath(
      tail,
      tailPaint
        ..strokeWidth = 3.5
        ..color = _bodyLight.withValues(alpha: 0.5),
    );

    // Long low body with a raised hump at the shoulders.
    final body = Rect.fromCenter(
      center: const Offset(48, 80),
      width: 64,
      height: 26,
    );
    final bodyPath =
        Path()
          ..addOval(body)
          ..addOval(
            Rect.fromCenter(
              center: const Offset(62, 74),
              width: 30,
              height: 30,
            ),
          );
    _glow(canvas, bodyPath);
    canvas.drawPath(bodyPath, _bodyPaint(body.inflate(8)));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 86), width: 44, height: 12),
      _fill(_bodyLight.withValues(alpha: 0.4)),
    );
    _paws(canvas, [30, 42, 60, 70], 94, 10, 6);

    _head(canvas, const Offset(70, 72), () {
      final head = Rect.fromCircle(center: const Offset(76, 66), radius: 12);
      final snout = Rect.fromCenter(
        center: const Offset(86, 69),
        width: 14,
        height: 9,
      );
      final headPath =
          Path()
            ..addOval(head)
            ..addOval(snout)
            ..addOval(Rect.fromCircle(center: const Offset(69, 56), radius: 4))
            ..addOval(Rect.fromCircle(center: const Offset(79, 55), radius: 4));
      _glow(canvas, headPath);
      canvas.drawPath(headPath, _bodyPaint(head.inflate(10)));
      for (final ear in [const Offset(69, 56), const Offset(79, 55)]) {
        canvas.drawCircle(ear, 2, _fill(_edge.withValues(alpha: 0.45)));
      }
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(84, 71), width: 10, height: 5),
        _fill(_bodyLight.withValues(alpha: 0.5)),
      );
      canvas.drawCircle(const Offset(92, 68.5), 1.8, _fill(_edge));
      _eyeAt(canvas, const Offset(78, 64), 5, 4.5, false);
    });
  }

  // ---------------------------------------------------------------- owl

  void _paintOwl(Canvas canvas) {
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

    final lift =
        (mood == FamiliarMood.joyful && !_sleeping)
            ? math.sin(phase * 4).abs() * 3
            : (action == FamiliarAction.stretch ? 6.0 : 0.0);
    for (final side in [-1.0, 1.0]) {
      final wing =
          Path()
            ..moveTo(50 + side * 22, 46 - lift)
            ..quadraticBezierTo(50 + side * (30 + lift), 66, 50 + side * 18, 86)
            ..quadraticBezierTo(50 + side * 12, 70, 50 + side * 22, 46 - lift)
            ..close();
      canvas.drawPath(wing, _fill(Color.lerp(_body, Colors.black, 0.3)!));
    }

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

    // Face: tilts now and then, or dips to preen.
    final tiltWindow = phase > 1.5 && phase < 3.0;
    final tilt =
        tiltWindow ? 0.16 * math.sin((phase - 1.5) / 1.5 * math.pi) : 0.0;
    canvas.save();
    canvas.translate(50, 44);
    canvas.rotate(tilt + _headDip);
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
    canvas.drawPath(
      Path()..addPolygon(const [
        Offset(46, 51),
        Offset(54, 51),
        Offset(50, 58),
      ], true),
      _fill(AppColors.bronzeLight),
    );
    canvas.restore();

    final foot =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = AppColors.bronzeLight;
    for (final x in [42.0 + _pawSwing, 58.0 - _pawSwing]) {
      for (final dx in [-3.0, 0.0, 3.0]) {
        canvas.drawLine(Offset(x, 89), Offset(x + dx, 94), foot);
      }
    }
  }

  @override
  bool shouldRepaint(FamiliarPainter old) =>
      old.phase != phase ||
      old.hop != hop ||
      old.mood != mood ||
      old.action != action ||
      old.walkPhase != walkPhase ||
      old.species != species ||
      old.dimmed != dimmed;
}

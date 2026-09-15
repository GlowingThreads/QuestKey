/// The app's component kit: ornamented panels, gem rings, the mana orb,
/// the stat radar, framed portraits, porthole badges, dividers, buttons and
/// the entrance/glow animations. Everything here is drawn with the palette
/// taken from the artwork so the widgets and the illustrations read as one.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/theme/app_theme.dart';

// ---------------------------------------------------------------- panels

/// Obsidian panel with a bronze double frame and gem-set corner brackets.
class ArcanePanel extends StatelessWidget {
  const ArcanePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppPadding.lg),
    this.margin,
    this.radius = 14,
    this.ornate = true,
    this.accent,
    this.glow,
    this.fillOpacity = 0.86,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  /// Draw the corner brackets and gems.
  final bool ornate;

  /// Frame colour; defaults to bronze.
  final Color? accent;

  /// Soft outer glow colour.
  final Color? glow;
  final double fillOpacity;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      decoration:
          glow == null
              ? null
              : BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: glow!.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
      child: CustomPaint(
        painter: _ArcaneFramePainter(
          radius: radius,
          ornate: ornate,
          accent: accent ?? AppColors.bronzeLight,
          fillOpacity: fillOpacity,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _ArcaneFramePainter extends CustomPainter {
  _ArcaneFramePainter({
    required this.radius,
    required this.ornate,
    required this.accent,
    required this.fillOpacity,
  });

  final double radius;
  final bool ornate;
  final Color accent;
  final double fillOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Fill: midnight → obsidian with a faint amethyst sheen at the top.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.amethyst.withValues(alpha: fillOpacity * 0.55),
            AppColors.midnight.withValues(alpha: fillOpacity),
            AppColors.obsidian.withValues(alpha: fillOpacity),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(rect),
    );

    // Outer bronze frame.
    canvas.drawRRect(
      rrect.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          colors: [accent, AppColors.bronze, accent],
        ).createShader(rect),
    );

    // Inner gold hairline.
    canvas.drawRRect(
      rrect.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = AppColors.gold.withValues(alpha: 0.35),
    );

    if (!ornate || size.shortestSide < 60) return;

    // Corner brackets with a teal gem.
    const len = 12.0;
    const inset = 7.0;
    final bracket =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..color = accent;
    final gem = Paint()..color = AppColors.teal;
    final gemHalo = Paint()..color = AppColors.teal.withValues(alpha: 0.35);

    void corner(Offset o, double sx, double sy) {
      final p =
          Path()
            ..moveTo(o.dx + sx * len, o.dy)
            ..lineTo(o.dx, o.dy)
            ..lineTo(o.dx, o.dy + sy * len);
      canvas.drawPath(p, bracket);
      canvas.drawCircle(o, 3.2, gemHalo);
      canvas.drawCircle(o, 1.8, gem);
    }

    corner(const Offset(inset, inset), 1, 1);
    corner(Offset(size.width - inset, inset), -1, 1);
    corner(Offset(inset, size.height - inset), 1, -1);
    corner(Offset(size.width - inset, size.height - inset), -1, -1);
  }

  @override
  bool shouldRepaint(_ArcaneFramePainter old) =>
      old.radius != radius ||
      old.ornate != ornate ||
      old.accent != accent ||
      old.fillOpacity != fillOpacity;
}

/// Thin bronze rule with a gem in the middle.
class RuneDivider extends StatelessWidget {
  const RuneDivider({super.key, this.color = AppColors.bronzeLight});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget line(bool ltr) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: ltr ? Alignment.centerLeft : Alignment.centerRight,
            end: ltr ? Alignment.centerRight : Alignment.centerLeft,
            colors: [color.withValues(alpha: 0), color],
          ),
        ),
      ),
    );
    return Row(
      children: [
        line(true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.teal,
                border: Border.all(color: color, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
        line(false),
      ],
    );
  }
}

/// Section heading in the display face with a rule beneath.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    this.color = AppColors.gold,
    this.rule = true,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;
  final Color color;
  final bool rule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppPadding.sm),
            ],
            Expanded(
              child: Text(
                title,
                style: AppFonts.heading(
                  size: 15,
                  color: color,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: AppFonts.body(
                size: 13,
                color: AppColors.inkMuted,
                style: FontStyle.italic,
              ),
            ),
          ),
        if (rule) ...[
          const SizedBox(height: AppPadding.sm),
          const RuneDivider(),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- gems

/// Icon set in a bronze ring over a jewel-toned radial fill.
class GemRing extends StatelessWidget {
  const GemRing({
    super.key,
    required this.icon,
    this.color = AppColors.amethystBright,
    this.size = 44,
    this.selected = false,
    this.dimmed = false,
    this.iconColor,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool selected;
  final bool dimmed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.short,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Color.lerp(color, Colors.white, dimmed ? 0.05 : 0.35)!,
            color,
            Color.lerp(color, AppColors.obsidian, 0.55)!,
          ],
          stops: const [0, 0.45, 1],
        ),
        border: Border.all(
          color: selected ? AppColors.teal : AppColors.bronzeLight,
          width: selected ? 2 : 1.4,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.6),
              blurRadius: 12,
            )
          else
            BoxShadow(
              color: color.withValues(alpha: dimmed ? 0 : 0.35),
              blurRadius: 8,
            ),
        ],
      ),
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: Icon(icon, size: size * 0.5, color: iconColor ?? AppColors.ink),
      ),
    );
  }
}

/// Small bronze-bordered label pill ("runic tag").
class RuneTag extends StatelessWidget {
  const RuneTag({
    super.key,
    required this.text,
    this.color = AppColors.bronzeLight,
    this.icon,
    this.filled = false,
  });

  final String text;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            filled
                ? color.withValues(alpha: 0.18)
                : AppColors.obsidian.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(text, style: AppFonts.label(size: 10, color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- art

/// One of the porthole badge illustrations, with a soft glow.
class PortholeBadge extends StatelessWidget {
  const PortholeBadge({
    super.key,
    required this.asset,
    this.size = 72,
    this.glow = AppColors.teal,
    this.fallback = Icons.auto_awesome_rounded,
  });

  final String asset;
  final double size;
  final Color glow;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: size / 3),
        ],
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => GemRing(icon: fallback, size: size),
      ),
    );
  }
}

/// Hero portrait (the art already carries a gold frame) with an outer
/// bronze bezel and optional glow ring.
class FramedPortrait extends StatelessWidget {
  const FramedPortrait({
    super.key,
    required this.imageUrl,
    this.size = 96,
    this.glow,
    this.radius = 12,
    this.fallbackLabel,
  });

  final String imageUrl;
  final double size;
  final Color? glow;
  final double radius;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.bronzeLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (glow ?? AppColors.obsidian).withValues(
              alpha: glow == null ? 0.6 : 0.55,
            ),
            blurRadius: glow == null ? 10 : 18,
            spreadRadius: glow == null ? 0 : 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1.5),
        child: Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (_, _, _) => Container(
                color: AppColors.amethyst,
                alignment: Alignment.center,
                child: Text(
                  fallbackLabel ?? '?',
                  style: AppFonts.heading(size: size * 0.3),
                ),
              ),
        ),
      ),
    );
  }
}

/// Full-screen illustration with a vignette so text stays readable.
class PageBackground extends StatelessWidget {
  const PageBackground({
    super.key,
    required this.asset,
    required this.child,
    this.darken = 0.45,
  });

  final String asset;
  final Widget child;

  /// How much to darken the lower half (0–1).
  final double darken;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.amethyst, AppColors.obsidian],
            ),
          ),
        ),
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          // The illustrations are up to 7 MB PNGs; decoding them at phone
          // width keeps memory low so they stay cached between tab switches
          // instead of flashing while they re-decode.
          cacheWidth: 1080,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.obsidian.withValues(alpha: 0.35),
                AppColors.obsidian.withValues(alpha: 0.15),
                AppColors.obsidian.withValues(alpha: darken + 0.3),
                AppColors.obsidian.withValues(alpha: darken + 0.45),
              ],
              stops: const [0, 0.25, 0.7, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------- orb & radar

/// Amethyst mana orb showing the hero level, ringed by an XP progress arc.
class ManaOrb extends StatelessWidget {
  const ManaOrb({
    super.key,
    required this.level,
    required this.progress,
    this.size = 84,
    this.caption,
  });

  final int level;
  final double progress;
  final double size;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
      duration: AppDurations.long,
      curve: Curves.easeOutCubic,
      builder:
          (context, value, _) => SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _OrbPainter(progress: value),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      caption ?? 'LEVEL',
                      style: AppFonts.label(
                        size: size * 0.1,
                        color: AppColors.gold,
                      ),
                    ),
                    Text(
                      '$level',
                      style: AppFonts.heading(
                        size: size * 0.32,
                        color: AppColors.ink,
                        letterSpacing: 0,
                      ).copyWith(height: 1.05),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Halo.
    canvas.drawCircle(
      c,
      r * 0.86,
      Paint()
        ..color = AppColors.magenta.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Orb body.
    canvas.drawCircle(
      c,
      r * 0.72,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [
            Color(0xFFE9B8FF),
            AppColors.magenta,
            AppColors.amethyst,
            AppColors.obsidian,
          ],
          stops: [0, 0.25, 0.7, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.72)),
    );
    // Specular highlight.
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-r * 0.22, -r * 0.34),
        width: r * 0.34,
        height: r * 0.18,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Bronze bezel and progress track.
    final track = r * 0.86;
    canvas.drawCircle(
      c,
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = AppColors.obsidian.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      c,
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.bronzeLight,
    );
    canvas.drawCircle(
      c,
      track - 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.bronze,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: track),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: 3 * math.pi / 2,
            colors: [AppColors.gold, AppColors.teal, AppColors.gold],
          ).createShader(Rect.fromCircle(center: c, radius: track)),
      );
    }
    // Four bezel gems.
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      final p = c + Offset(math.cos(a), math.sin(a)) * track;
      canvas.drawCircle(p, 2.2, Paint()..color = AppColors.teal);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.progress != progress;
}

/// Seven-axis radar chart of the hero's attributes.
class StatRadar extends StatelessWidget {
  const StatRadar({
    super.key,
    required this.values,
    this.maxValue = 12,
    this.size = 200,
    this.color = AppColors.teal,
    this.compare,
  });

  /// Stat name → value, in display order.
  final Map<String, int> values;
  final int maxValue;
  final double size;
  final Color color;

  /// Optional second polygon (e.g. base class stats) drawn in bronze.
  final Map<String, int>? compare;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder:
          (context, t, _) => SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RadarPainter(
                values: values,
                compare: compare,
                maxValue: maxValue,
                color: color,
                t: t,
              ),
            ),
          ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.values,
    required this.compare,
    required this.maxValue,
    required this.color,
    required this.t,
  });

  final Map<String, int> values;
  final Map<String, int>? compare;
  final int maxValue;
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 22;
    final n = values.length;
    if (n < 3) return;

    Offset point(int i, double fraction) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      return c + Offset(math.cos(a), math.sin(a)) * r * fraction;
    }

    // Web rings and spokes.
    final web =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = AppColors.bronze.withValues(alpha: 0.6);
    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = point(i, ring / 4);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, web);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, point(i, 1), web);
    }

    Path polygon(Map<String, int> data) {
      final path = Path();
      var i = 0;
      for (final key in values.keys) {
        final v = (data[key] ?? 0).clamp(0, maxValue) / maxValue;
        final p = point(i, v * t);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
        i++;
      }
      return path..close();
    }

    if (compare != null) {
      final cmp = polygon(compare!);
      canvas.drawPath(
        cmp,
        Paint()..color = AppColors.bronzeLight.withValues(alpha: 0.18),
      );
      canvas.drawPath(
        cmp,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.bronzeLight.withValues(alpha: 0.8),
      );
    }

    final poly = polygon(values);
    canvas.drawPath(poly, Paint()..color = color.withValues(alpha: 0.28));
    canvas.drawPath(
      poly,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = color,
    );
    var i = 0;
    for (final key in values.keys) {
      final v = (values[key] ?? 0).clamp(0, maxValue) / maxValue;
      final p = point(i, v * t);
      canvas.drawCircle(p, 3, Paint()..color = AppColors.gold);
      i++;
    }

    // Labels.
    i = 0;
    for (final key in values.keys) {
      final p = point(i, 1.16);
      final tp = TextPainter(
        text: TextSpan(
          text: _abbrev(key),
          style: AppFonts.label(size: 10, color: AppColors.gold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      i++;
    }
  }

  static String _abbrev(String stat) => switch (stat) {
    'strength' => 'STR',
    'dexterity' => 'DEX',
    'intelligence' => 'INT',
    'wisdom' => 'WIS',
    'charisma' => 'CHA',
    'constitution' => 'CON',
    'luck' => 'LCK',
    _ => stat.substring(0, math.min(3, stat.length)).toUpperCase(),
  };

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.t != t || old.values != values || old.compare != compare;
}

// ---------------------------------------------------------------- bars

/// Bronze-capped resource bar that animates to its value.
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.fraction,
    this.height = 10,
    this.colors = AppColors.xpGradient,
    this.background = const Color(0xCC0B0718),
    this.duration = AppDurations.long,
  });

  final double fraction;
  final double height;
  final List<Color> colors;
  final Color background;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: AppColors.bronze, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: fraction.clamp(0.0, 1.0)),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder:
            (context, value, _) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------- motion

/// Fades and slides its child in once. Use `delay` to stagger children.
/// One controller covers delay + animation so no timers are involved.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.06),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  )..forward();
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds /
          (widget.delay + widget.duration).inMilliseconds,
      1.0,
      curve: widget.curve,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// A soft, breathing glow behind its child.
class PulseGlow extends StatefulWidget {
  const PulseGlow({
    super.key,
    required this.child,
    this.color = AppColors.gold,
    this.radius = 24,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.enabled = true,
  });

  final Widget child;
  final Color color;
  final double radius;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final bool enabled;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2 + 0.35 * t),
                blurRadius: widget.radius * (0.6 + 0.6 * t),
                spreadRadius: 1 + 4 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Counts from the previous value to [value] whenever it changes.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder:
          (context, v, _) => Text('$prefix${v.round()}$suffix', style: style),
    );
  }
}

// ---------------------------------------------------------------- buttons

enum QuestButtonStyle { amethyst, gold, danger, ghost }

/// Primary call-to-action: bronze double frame, jewel gradient, display
/// type, press-to-shrink.
class QuestButton extends StatefulWidget {
  const QuestButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = QuestButtonStyle.amethyst,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final QuestButtonStyle style;
  final bool expand;
  final bool compact;

  @override
  State<QuestButton> createState() => _QuestButtonState();
}

class _QuestButtonState extends State<QuestButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (colors, glow, fg) = switch (widget.style) {
      QuestButtonStyle.amethyst => (
        const [AppColors.amethyst, AppColors.amethystBright],
        AppColors.amethystBright,
        AppColors.ink,
      ),
      QuestButtonStyle.gold => (
        const [Color(0xFF9A7226), AppColors.gold],
        AppColors.gold,
        AppColors.obsidian,
      ),
      QuestButtonStyle.danger => (
        const [Color(0xFF6E1B1B), AppColors.ruby],
        AppColors.ruby,
        AppColors.ink,
      ),
      QuestButtonStyle.ghost => (
        const [Color(0x00000000), Color(0x22000000)],
        AppColors.obsidian,
        AppColors.ink,
      ),
    };

    return AnimatedScale(
      scale: _pressed ? 0.965 : 1,
      duration: AppDurations.shortest,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: AppDurations.short,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: Container(
            width: widget.expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 14 : 22,
              vertical: widget.compact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.bronzeLight, width: 1.3),
              boxShadow:
                  enabled && widget.style != QuestButtonStyle.ghost
                      ? [
                        BoxShadow(
                          color: glow.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  width: 0.7,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
              child: Row(
                mainAxisSize:
                    widget.expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: fg, size: 18),
                    const SizedBox(width: AppPadding.sm),
                  ],
                  Text(
                    widget.label,
                    style: AppFonts.heading(
                      size: widget.compact ? 12 : 14,
                      color: fg,
                      letterSpacing: 1.8,
                    ),
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

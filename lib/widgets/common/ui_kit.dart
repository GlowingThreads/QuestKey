/// Small reusable building blocks that give the app its look and motion:
/// frosted panels, entrance animations, glows, animated numbers and a
/// press-to-shrink button.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

/// Frosted, bordered panel used for every card in the app.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppPadding.lg),
    this.margin,
    this.color = AppColors.bgDark,
    this.borderColor = AppColors.borderLight,
    this.borderWidth = AppBorders.thin,
    this.radius = AppRadius.lg,
    this.glowColor,
    this.blur = 8,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final Color? glowColor;
  final double blur;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow:
            glowColor == null
                ? null
                : [
                  BoxShadow(
                    color: glowColor!.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Fades and slides its child in once when it is first built. Use `delay`
/// to stagger a list of children.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.08),
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
  // One controller covers delay + animation so no timers are involved.
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
    this.color = AppColors.accentGold,
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
    duration: const Duration(milliseconds: 1600),
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
                color: widget.color.withValues(alpha: 0.25 + 0.35 * t),
                blurRadius: widget.radius * (0.6 + 0.6 * t),
                spreadRadius: 2 + 4 * t,
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

/// Heading with an icon, used at the top of page sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    this.color = AppColors.accentGold,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: AppIconSizes.md),
          const SizedBox(width: AppPadding.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Primary call-to-action: gradient, glow and a press-to-shrink animation.
class QuestButton extends StatefulWidget {
  const QuestButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.colors = const [AppColors.accentPurple, Color(0xFF9C27B0)],
    this.glow = AppColors.shadowPurple,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final List<Color> colors;
  final Color glow;
  final bool expand;

  @override
  State<QuestButton> createState() => _QuestButtonState();
}

class _QuestButtonState extends State<QuestButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: AppDurations.shortest,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.5,
        duration: AppDurations.short,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: Container(
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.xl,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.colors),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white24),
              boxShadow:
                  enabled
                      ? [
                        BoxShadow(
                          color: widget.glow.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: AppPadding.sm),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSizes.md,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen background image with a dark gradient so text stays legible;
/// falls back to a flat gradient when the asset is missing.
class PageBackground extends StatelessWidget {
  const PageBackground({super.key, required this.asset, required this.child});

  final String asset;
  final Widget child;

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
              colors: [Color(0xFF2A1655), AppColors.primaryDarker],
            ),
          ),
        ),
        Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black26, Colors.black54],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// A horizontal stat/resource bar that animates to its value.
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.fraction,
    this.height = 10,
    this.colors = AppColors.xpGradient,
    this.background = Colors.black38,
    this.duration = AppDurations.long,
  });

  final double fraction;
  final double height;
  final List<Color> colors;
  final Color background;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: background,
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
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

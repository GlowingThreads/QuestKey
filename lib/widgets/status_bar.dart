import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

class StatBar extends StatefulWidget {
  final String label;
  final int value;
  final VoidCallback? onAdd;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.onAdd,
  });

  @override
  State<StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<StatBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: AppDurations.long, vsync: this);
    _setupAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(StatBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _setupAnimation();
      _controller.forward(from: 0.0);
    }
  }

  void _setupAnimation() {
    final fillPercent = (widget.value / 20).clamp(0.0, 1.0);
    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: fillPercent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillPercent = (widget.value / 20).clamp(0.0, 1.0);
    final availableWidth = MediaQuery.of(context).size.width - AppPadding.xxl * 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                '${widget.value}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (widget.onAdd != null) ...[
                const SizedBox(width: AppPadding.md),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onAdd,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: AppBorders.thin,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.textPrimary,
                          size: AppIconSizes.sm,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppPadding.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: AppHeights.statBar,
              decoration: BoxDecoration(
                color: AppColors.primaryDarker,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Stack(
                children: [
                  // Animated filled bar
                  AnimatedBuilder(
                    animation: _fillAnimation,
                    builder: (context, child) {
                      return Container(
                        height: AppHeights.statBar,
                        width: _fillAnimation.value * availableWidth,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.statGradient,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowGreen.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

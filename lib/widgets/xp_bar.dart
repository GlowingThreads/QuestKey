import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

class XpBar extends StatefulWidget {
  final int currentXp;
  final int maxXp;

  const XpBar({
    super.key,
    required this.currentXp,
    required this.maxXp,
  });

  @override
  State<XpBar> createState() => _XpBarState();
}

class _XpBarState extends State<XpBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: AppDurations.long, vsync: this);
    _setupAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(XpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXp != widget.currentXp) {
      _setupAnimation();
      _controller.forward(from: 0.0);
    }
  }

  void _setupAnimation() {
    final progress = (widget.currentXp / widget.maxXp).clamp(0.0, 1.0);
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.currentXp / widget.maxXp).clamp(0.0, 1.0);
    final percentage = (progress * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppPadding.xl),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight, width: AppBorders.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Experience Points',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.sm,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.sm),
          Text(
            '${widget.currentXp} / ${widget.maxXp} XP',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppPadding.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: AppHeights.xpBar,
              decoration: BoxDecoration(
                color: AppColors.primaryDarker,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Stack(
                children: [
                  // Animated progress bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Container(
                        height: AppHeights.xpBar,
                        width: _progressAnimation.value * (MediaQuery.of(context).size.width - AppPadding.xxl * 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.xpGradient,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowPurple,
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

/// The den: a wide box the familiar lives in. A ticker advances
/// [FamiliarBehaviour] and the creature is placed along the floor, mirrored
/// when it faces left, with a shadow that shrinks as it hops.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/models/familiar.dart';
import 'package:quest_key/widgets/familiar/familiar_behaviour.dart';
import 'package:quest_key/widgets/familiar/familiar_sprite.dart';

class FamiliarStage extends StatefulWidget {
  const FamiliarStage({
    super.key,
    required this.species,
    required this.mood,
    this.height = 150,
    this.creatureSize = 84,
    this.hopTrigger = 0,
    this.onTap,
    this.dimmed = false,
    this.random,
  });

  final FamiliarSpecies species;
  final FamiliarMood mood;
  final double height;
  final double creatureSize;

  /// Changes when a quest is completed; the familiar hops.
  final int hopTrigger;
  final VoidCallback? onTap;
  final bool dimmed;

  /// Injected for deterministic tests.
  final math.Random? random;

  @override
  State<FamiliarStage> createState() => _FamiliarStageState();
}

class _FamiliarStageState extends State<FamiliarStage>
    with SingleTickerProviderStateMixin {
  late final FamiliarBehaviour _behaviour = FamiliarBehaviour(
    random: widget.random,
    mood: widget.mood,
  );
  late final Ticker _ticker = createTicker(_onTick);
  final GlobalKey<State<FamiliarSprite>> _spriteKey = GlobalKey();
  Duration _last = Duration.zero;
  int _hops = 0;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // Skip huge steps (the tab was hidden) so the creature does not teleport.
    _behaviour.tick(dt.clamp(0.0, 0.1));
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(FamiliarStage old) {
    super.didUpdateWidget(old);
    _behaviour.mood = widget.mood;
    if (widget.hopTrigger != old.hopTrigger) _startle();
  }

  void _startle() {
    _behaviour.startle();
    _hops++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = _behaviour;
    final size = widget.creatureSize;
    final hop = b.action == FamiliarAction.hop ? b.hopProgress : 0.0;
    final lift = math.sin(math.pi * hop) * size * 0.28;
    final spriteState = _spriteKey.currentState;
    final artFacesRight =
        spriteState is FamiliarSpriteFacing
            ? (spriteState as FamiliarSpriteFacing).artFacesRight
            : FamiliarSprite.painterFacesRight(widget.species);
    final mirror = b.facingRight != artFacesRight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final left = b.x * (width - size);
        return SizedBox(
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The den: warm hearth glow at the left, a floor rule.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0E0820), Color(0xFF1A1132)],
                    ),
                    border: Border.all(
                      color: AppColors.bronze.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -30,
                child: IgnorePointer(
                  child: Container(
                    width: 160,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.22),
                          AppColors.gold.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 12,
                child: Container(
                  height: 1,
                  color: AppColors.bronze.withValues(alpha: 0.5),
                ),
              ),
              // Shadow.
              Positioned(
                left: left + size * 0.2,
                bottom: 8,
                child: IgnorePointer(
                  child: Container(
                    width: size * 0.6 * (1 - hop * 0.4),
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.black.withValues(
                        alpha: 0.5 * (1 - hop * 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              // The familiar.
              Positioned(
                left: left,
                bottom: 6 + lift,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:
                      widget.onTap == null
                          ? null
                          : () {
                            _startle();
                            widget.onTap!();
                          },
                  child: Transform.flip(
                    flipX: mirror,
                    child: FamiliarSprite(
                      key: _spriteKey,
                      species: widget.species,
                      mood: widget.mood,
                      action: b.action,
                      walkPhase: b.walkPhase,
                      hopProgress: hop,
                      facingRight: b.facingRight,
                      size: size,
                      dimmed: widget.dimmed,
                      hopTrigger: _hops,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

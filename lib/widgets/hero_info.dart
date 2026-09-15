import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/spells.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/widgets/common/sigils.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Character sheet card: framed portrait, name and titles, mana orb with
/// level and XP ring, resource bars.
class HeroProfileCard extends StatelessWidget {
  final HeroCharacter hero;

  const HeroProfileCard({super.key, required this.hero});

  @override
  Widget build(BuildContext context) {
    final hasPoints = hero.levelUp.statPoints > 0;
    final background = hero.background;
    final title = hero.title;
    final now = DateTime.now();
    final buffs = hero.activeBuffsAt(now);

    return ArcanePanel(
      glow: hasPoints ? AppColors.gold : null,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FramedPortrait(
                imageUrl: hero.imageUrl,
                size: 92,
                glow: hasPoints ? AppColors.gold : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hero.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.heading(size: 19, letterSpacing: 0.8),
                    ),
                    if (title != null)
                      Text(
                        'the ${title.name}',
                        style: AppFonts.body(
                          size: 12,
                          color: AppColors.gold,
                          style: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      background == null
                          ? hero.classes.className
                          : '${hero.classes.className} · ${background.name}',
                      style: AppFonts.label(size: 10, color: AppColors.teal),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${hero.motto}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(
                        size: 13,
                        color: AppColors.inkMuted,
                        style: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniStat(
                          Icons.emoji_events_rounded,
                          hero.questsCompleted,
                          'QUESTS',
                        ),
                        const SizedBox(width: 14),
                        _MiniStat(
                          Icons.local_fire_department_rounded,
                          hero.currentStreak,
                          'STREAK',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ManaOrb(
                level: hero.levelUp.level,
                progress: hero.levelUp.progress,
                size: 78,
              ),
            ],
          ),
          if (buffs.isNotEmpty || hero.shieldCharges > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final buff in buffs)
                  Tooltip(
                    message: buff.type.description,
                    child: RuneTag(
                      text:
                          buff.type == BuffType.haste
                              ? 'HASTE · ${buff.expiresAt.difference(now).inMinutes}M'
                              : buff.type.label.toUpperCase(),
                      color: _buffColor(buff.type),
                      icon: _buffIcon(buff.type),
                      filled: true,
                    ),
                  ),
                if (hero.shieldCharges > 0)
                  RuneTag(
                    text: 'SHIELD ×${hero.shieldCharges}',
                    color: AppColors.arcaneBlue,
                    icon: Icons.shield_rounded,
                    filled: true,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const RuneDivider(),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Tooltip(
                message:
                    hero.hasSkill('iron_will')
                        ? 'Iron Will: a missed day burns 15% of the torch.'
                        : 'A missed day burns 25% of the torch; at zero the streak is lost.',
                child: TorchFlame(
                  fraction:
                      hero.maxHealth == 0 ? 0 : hero.health / hero.maxHealth,
                  width: 22,
                  height: 36,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Resource(
                  label: 'TORCH',
                  value: hero.health,
                  max: hero.maxHealth,
                  colors: const [Color(0xFF7A1E1E), AppColors.ruby],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Resource(
                  label: 'MP',
                  value: hero.mana,
                  max: hero.maxMana,
                  colors: const [Color(0xFF1E3A8A), AppColors.arcaneBlue],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Resource(
                  label: 'STA',
                  value: hero.stamina,
                  max: hero.maxStamina,
                  colors: const [Color(0xFF7A4A10), AppColors.gold],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _buffColor(BuffType type) => switch (type) {
  BuffType.empowered => AppColors.magenta,
  BuffType.haste => AppColors.arcaneBlue,
  BuffType.rallied => AppColors.gold,
  BuffType.foresight => AppColors.teal,
  BuffType.berserk => AppColors.ruby,
};

IconData _buffIcon(BuffType type) => switch (type) {
  BuffType.empowered => Icons.bolt_rounded,
  BuffType.haste => Icons.air_rounded,
  BuffType.rallied => Icons.campaign_rounded,
  BuffType.foresight => Icons.remove_red_eye_rounded,
  BuffType.berserk => Icons.bloodtype_rounded,
};

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.value, this.label);

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.gold),
        const SizedBox(width: 4),
        AnimatedCount(
          value: value,
          style: AppFonts.body(size: 13, weight: FontWeight.w700),
        ),
        const SizedBox(width: 3),
        Text(label, style: AppFonts.label(size: 8, color: AppColors.inkMuted)),
      ],
    );
  }
}

class _Resource extends StatelessWidget {
  const _Resource({
    required this.label,
    required this.value,
    required this.max,
    required this.colors,
  });

  final String label;
  final int value;
  final int max;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= 0 ? 1 : (value > max ? value : max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppFonts.label(size: 9, color: colors.last)),
            Text(
              '$value/$safeMax',
              style: AppFonts.body(size: 11, color: AppColors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: 3),
        AnimatedBar(fraction: value / safeMax, height: 7, colors: colors),
      ],
    );
  }
}

/// Legacy wrapper kept for older call sites.
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({super.key, required this.imageUrl, this.fallbackLabel});

  final String imageUrl;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder:
          (_, _, _) => Container(
            color: AppColors.amethyst,
            alignment: Alignment.center,
            child: Text(
              fallbackLabel ?? '?',
              style: AppFonts.heading(size: 22),
            ),
          ),
    );
  }
}

/// Convenience for pages that only need the gap constant.
const double heroCardGap = AppPadding.lg;

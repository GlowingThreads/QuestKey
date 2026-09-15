import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/hero_info.dart';
import 'package:quest_key/widgets/quest_list.dart';
import 'package:quest_key/widgets/xp_bar.dart';

/// Home tab: greeting, hero card, today's progress, in-progress quests and
/// the XP bar. Hero and quests are loaded once in `main()`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static String greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 5) return 'Burning the midnight oil';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 22) return 'Good evening';
    return 'Still questing';
  }

  @override
  Widget build(BuildContext context) {
    final hero = context.watch<AppState>().hero;
    final quests = context.watch<QuestListProvider>();
    final inProgress = quests.inProgressQuests.length;

    return Scaffold(
      body: PageBackground(
        asset: 'assets/images/app_assets/home_bkg.png',
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.xxl,
              AppPadding.lg,
              AppPadding.xxl,
              110,
            ),
            children: [
              FadeSlideIn(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${greetingFor(DateTime.now())},',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            hero?.name ?? 'adventurer',
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      inProgress == 0
                          ? 'All clear ✨'
                          : '$inProgress open ${inProgress == 1 ? 'quest' : 'quests'}',
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppPadding.lg),
              if (hero != null) ...[
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: HeroProfileCard(hero: hero),
                ),
                const SizedBox(height: AppPadding.lg),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _DailyProgressRow(hero: hero, quests: quests),
                ),
                const SizedBox(height: AppPadding.lg),
              ],
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: SectionHeader(
                  icon: Icons.explore_outlined,
                  title: 'Active quests',
                  subtitle:
                      inProgress == 0
                          ? 'Nothing pending. Forge a new one!'
                          : 'Swipe right or tap ✓ to complete',
                  trailing: TextButton(
                    onPressed: () => context.read<AppState>().setIndex(1),
                    child: const Text('See all'),
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.sm),
              const FadeSlideIn(
                delay: Duration(milliseconds: 300),
                child: QuestList(filterStatus: QuestStatus.inProgress),
              ),
              const SizedBox(height: AppPadding.lg),
              if (hero != null)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 360),
                  child: XpBar(
                    currentXp: hero.levelUp.exp,
                    maxXp: hero.levelUp.maxExp,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Streak, quests done today, overdue count and XP to the next level.
class _DailyProgressRow extends StatelessWidget {
  const _DailyProgressRow({required this.hero, required this.quests});

  final HeroCharacter hero;
  final QuestListProvider quests;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final streakAlive = hero.isStreakAliveAt(now);
    final streak = streakAlive ? hero.currentStreak : 0;
    final doneToday = quests.completedOn(now);
    final overdue = quests.overdueQuests.length;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: '🔥',
            value: streak,
            label: 'day streak',
            highlight: streak > 0,
            tooltip:
                streak > 0
                    ? 'Complete a quest every day to keep it going. Best: ${hero.longestStreak}'
                    : 'Complete a quest today to start a streak',
          ),
        ),
        const SizedBox(width: AppPadding.sm),
        Expanded(
          child: _StatTile(
            icon: '✅',
            value: doneToday,
            label: 'done today',
            highlight: doneToday > 0,
            color: AppColors.accentGreen,
          ),
        ),
        const SizedBox(width: AppPadding.sm),
        Expanded(
          child:
              overdue > 0
                  ? _StatTile(
                    icon: '⏰',
                    value: overdue,
                    label: 'overdue',
                    highlight: true,
                    color: Colors.redAccent,
                  )
                  : _StatTile(
                    icon: '⬆️',
                    value: hero.levelUp.expToNextLevel,
                    label: 'XP to Lv. ${hero.levelUp.level + 1}',
                  ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
    this.color,
    this.tooltip,
  });

  final String icon;
  final int value;
  final String label;
  final bool highlight;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.accentGold;
    final tile = GlassPanel(
      padding: const EdgeInsets.symmetric(
        vertical: AppPadding.md,
        horizontal: AppPadding.sm,
      ),
      radius: AppRadius.md,
      borderColor:
          highlight ? accent.withValues(alpha: 0.8) : AppColors.borderLight,
      borderWidth: highlight ? AppBorders.medium : AppBorders.thin,
      glowColor: highlight ? accent : null,
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: AppPadding.xs),
          AnimatedCount(
            value: value,
            style: TextStyle(
              color: highlight ? accent : AppColors.textPrimary,
              fontSize: AppFontSizes.xl,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSizes.xs,
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? tile : Tooltip(message: tooltip!, child: tile);
  }
}

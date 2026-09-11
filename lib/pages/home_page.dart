import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/widgets/hero_info.dart';
import 'package:quest_key/widgets/quest_list.dart';
import 'package:quest_key/widgets/xp_bar.dart';

/// Home tab: hero card, today's progress, in-progress quests and XP bar.
///
/// Hero and quests are loaded once in `main()` before the app starts, so
/// this page does not reload them (the old reload-on-every-visit caused a
/// spinner flash each time the tab was opened).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final hero = context.watch<AppState>().hero;
    final quests = context.watch<QuestListProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_assets/home_bkg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hero != null)
                    HeroProfileCard(hero: hero)
                  else
                    _NoHeroCard(
                      onCreate: () => context.read<AppState>().setIndex(4),
                    ),
                  const SizedBox(height: 20),
                  if (hero != null) ...[
                    _DailyProgressRow(hero: hero, quests: quests),
                    const SizedBox(height: 20),
                  ],
                  const QuestList(filterStatus: QuestStatus.inProgress),
                  const SizedBox(height: 20),
                  if (hero != null)
                    XpBar(
                      currentXp: hero.levelUp.exp,
                      maxXp: hero.levelUp.maxExp,
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

class _NoHeroCard extends StatelessWidget {
  const _NoHeroCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.xl),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No hero yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppPadding.sm),
          const Text(
            'Create a hero to start earning XP from your quests.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppPadding.md),
          FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
            ),
            icon: const Icon(Icons.person_add),
            label: const Text('Create Hero'),
          ),
        ],
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
            value: '$streak',
            label: streak == 1 ? 'day streak' : 'day streak',
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
            value: '$doneToday',
            label: 'done today',
            highlight: doneToday > 0,
          ),
        ),
        const SizedBox(width: AppPadding.sm),
        Expanded(
          child:
              overdue > 0
                  ? _StatTile(
                    icon: '⏰',
                    value: '$overdue',
                    label: 'overdue',
                    highlight: true,
                    color: Colors.redAccent,
                  )
                  : _StatTile(
                    icon: '⬆️',
                    value: '${hero.levelUp.expToNextLevel}',
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
  final String value;
  final String label;
  final bool highlight;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.accentGold;
    final tile = Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppPadding.md,
        horizontal: AppPadding.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color:
              highlight ? accent.withValues(alpha: 0.8) : AppColors.borderLight,
          width: highlight ? AppBorders.medium : AppBorders.thin,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: AppPadding.xs),
          Text(
            value,
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

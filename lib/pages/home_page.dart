import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/encounter_provider.dart';
import 'package:quest_key/widgets/encounter_card.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/common/sigils.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/hero_info.dart';
import 'package:quest_key/widgets/quest_list.dart';

/// Home: the hero's character sheet, today's ledger and active quests.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static String greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 5) return 'The hour is late';
    if (hour < 12) return 'A new day dawns';
    if (hour < 17) return 'The sun is high';
    if (hour < 22) return 'Evening falls';
    return 'The night is young';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hero = appState.hero;
    final quests = context.watch<QuestListProvider>();
    final encounter = context.watch<EncounterProvider>().open;
    final rest = appState.lastRest;
    final inProgress = quests.inProgressQuests.length;

    return Scaffold(
      body: PageBackground(
        asset: Art.homeBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
            children: [
              FadeSlideIn(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const PortholeBadge(asset: Art.home, size: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greetingFor(DateTime.now()).toUpperCase(),
                            style: AppFonts.label(
                              size: 10,
                              color: AppColors.gold,
                            ),
                          ),
                          Text(
                            hero?.name ?? 'Adventurer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.heading(size: 22),
                          ),
                          Text(
                            inProgress == 0
                                ? 'The log is clear.'
                                : '$inProgress ${inProgress == 1 ? 'quest' : 'quests'} await.',
                            style: AppFonts.body(
                              size: 13,
                              color: AppColors.inkMuted,
                              style: FontStyle.italic,
                            ),
                          ),
                        ],
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
                const SizedBox(height: AppPadding.md),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _Ledger(hero: hero, quests: quests),
                ),
                if (rest != null && rest.missedDays > 0) ...[
                  const SizedBox(height: AppPadding.md),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _RestBanner(
                      report: rest,
                      onDismiss: appState.dismissRestReport,
                    ),
                  ),
                ],
                if (encounter != null) ...[
                  const SizedBox(height: AppPadding.md),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child: EncounterCard(encounter: encounter),
                  ),
                ],
                const SizedBox(height: AppPadding.lg),
              ],
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: Row(
                  children: [
                    Image.asset(
                      Art.progressBadge,
                      width: 54,
                      height: 54,
                      errorBuilder: (_, _, _) => const SizedBox(width: 0),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SectionHeader(
                        title: 'Active Quests',
                        subtitle: 'Swipe right or tap the seal to complete',
                        rule: false,
                        trailing: TextButton(
                          onPressed: () => context.read<AppState>().setIndex(1),
                          child: const Text('QUEST LOG'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const FadeSlideIn(
                delay: Duration(milliseconds: 300),
                child: QuestList(
                  filterStatus: QuestStatus.inProgress,
                  hideSnoozed: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What happened to the torch while the app was closed.
class _RestBanner extends StatelessWidget {
  const _RestBanner({required this.report, required this.onDismiss});

  final RestReport report;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final out = report.flameWentOut;
    final text =
        out
            ? 'The flame went out after ${report.missedDays} missed '
                '${report.missedDays == 1 ? 'day' : 'days'}. Your streak resets; the torch relights at a quarter.'
            : report.shieldsSpent > 0 && report.torchDamage == 0
            ? '${report.shieldsSpent} shield ${report.shieldsSpent == 1 ? 'charge' : 'charges'} absorbed '
                '${report.missedDays} missed ${report.missedDays == 1 ? 'day' : 'days'}. The flame held.'
            : 'The torch burned ${report.torchDamage} HP over ${report.missedDays} missed '
                '${report.missedDays == 1 ? 'day' : 'days'}'
                '${report.shieldsSpent > 0 ? ' (${report.shieldsSpent} absorbed by shields)' : ''}. '
                'Complete a quest to recover.';
    return ArcanePanel(
      ornate: false,
      radius: 10,
      accent: out ? AppColors.ruby : AppColors.gold,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          TorchFlame(
            fraction:
                report.hero.maxHealth == 0
                    ? 0
                    : report.hero.health / report.hero.maxHealth,
            width: 22,
            height: 36,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppFonts.body(size: 13))),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.inkMuted,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Streak, quests done today, overdue count or XP to next level.
class _Ledger extends StatelessWidget {
  const _Ledger({required this.hero, required this.quests});

  final HeroCharacter hero;
  final QuestListProvider quests;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final streak = hero.isStreakAliveAt(now) ? hero.currentStreak : 0;
    final doneToday = quests.completedOn(now);
    final overdue = quests.overdueQuests.length;

    return Row(
      children: [
        Expanded(
          child: _LedgerTile(
            icon: Icons.local_fire_department_rounded,
            value: streak,
            label: streak == 1 ? 'DAY STREAK' : 'DAY STREAK',
            color: AppColors.gold,
            lit: streak > 0,
            tooltip:
                streak > 0
                    ? 'Complete a quest every day to keep it. Best: ${hero.longestStreak}'
                    : 'Complete a quest today to start a streak',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LedgerTile(
            icon: Icons.check_rounded,
            value: doneToday,
            label: 'DONE TODAY',
            color: AppColors.teal,
            lit: doneToday > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:
              overdue > 0
                  ? _LedgerTile(
                    icon: Icons.hourglass_bottom_rounded,
                    value: overdue,
                    label: 'OVERDUE',
                    color: AppColors.ruby,
                    lit: true,
                  )
                  : _LedgerTile(
                    icon: Icons.arrow_upward_rounded,
                    value: hero.levelUp.expToNextLevel,
                    label: 'XP TO LV ${hero.levelUp.level + 1}',
                    color: AppColors.arcaneBlue,
                  ),
        ),
      ],
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.lit = false,
    this.tooltip,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final bool lit;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tile = ArcanePanel(
      ornate: false,
      radius: 10,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      accent: lit ? color : null,
      glow: lit ? color : null,
      child: Column(
        children: [
          Icon(icon, color: lit ? color : AppColors.inkMuted, size: 18),
          const SizedBox(height: 4),
          AnimatedCount(
            value: value,
            style: AppFonts.heading(
              size: 20,
              color: lit ? color : AppColors.ink,
              letterSpacing: 0,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.label(size: 8, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
    return tooltip == null ? tile : Tooltip(message: tooltip!, child: tile);
  }
}

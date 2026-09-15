import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/achievement_unlocked_dialog.dart';
import 'package:quest_key/widgets/celebration_overlay.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';
import 'package:quest_key/widgets/lvl_notifcation.dart';

class QuestList extends StatefulWidget {
  /// Show only quests with this status; `null` shows every quest.
  final QuestStatus? filterStatus;

  /// When true the list fills its parent instead of capping its height.
  final bool expand;

  const QuestList({super.key, this.filterStatus, this.expand = false});

  @override
  State<QuestList> createState() => _QuestListState();
}

class _QuestListState extends State<QuestList> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestListProvider>();
    final quests = provider.getFilteredQuests(widget.filterStatus);

    final list =
        quests.isEmpty
            ? _EmptyState(filterStatus: widget.filterStatus)
            : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: quests.length,
              itemBuilder: (context, index) {
                final quest = quests[index];
                return FadeSlideIn(
                  key: ValueKey('fade_${quest.id}'),
                  delay: Duration(milliseconds: 40 * (index < 8 ? index : 8)),
                  offset: const Offset(-0.05, 0),
                  child: Dismissible(
                    key: Key(quest.id.toString()),
                    direction:
                        quest.isCompleted
                            ? DismissDirection.endToStart
                            : DismissDirection.horizontal,
                    background: _swipeBackground(
                      color: AppColors.teal,
                      icon: Icons.check_rounded,
                      label: 'COMPLETE',
                      alignment: Alignment.centerLeft,
                    ),
                    secondaryBackground: _swipeBackground(
                      color: AppColors.ruby,
                      icon: Icons.delete_outline_rounded,
                      label: 'DELETE',
                      alignment: Alignment.centerRight,
                    ),
                    confirmDismiss:
                        (direction) => _confirmDismiss(direction, quest),
                    onDismissed: (direction) => _onDismissed(direction, quest),
                    child: _QuestTile(
                      quest: quest,
                      onEdit: quest.isCompleted ? null : () => _edit(quest),
                      onComplete:
                          quest.isCompleted ? null : () => _complete(quest),
                    ),
                  ),
                );
              },
            );

    if (widget.expand) return list;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: AppHeights.questContainer),
      child: list,
    );
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: alignment,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:
              alignment == Alignment.centerLeft
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
          end:
              alignment == Alignment.centerLeft
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          colors: [color.withValues(alpha: 0.75), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.ink, size: 22),
          const SizedBox(width: 8),
          Text(label, style: AppFonts.label(size: 11, color: AppColors.ink)),
        ],
      ),
    );
  }

  void _edit(Quest quest) {
    context.read<QuestListProvider>().setSelectedQuest(quest);
    context.read<AppState>().setIndex(2);
  }

  /// Swipe right: complete. On the "All" view the quest stays in the list
  /// (it just turns green), so we complete it here and let the tile snap
  /// back; on filtered views it leaves the list, so we let the dismiss
  /// animation play and complete in [_onDismissed].
  /// Swipe left: ask before deleting.
  Future<bool> _confirmDismiss(DismissDirection direction, Quest quest) async {
    if (direction == DismissDirection.startToEnd) {
      if (widget.filterStatus == null) {
        await _complete(quest);
        return false;
      }
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete quest?'),
            content: Text(
              '"${quest.title}" will be struck from the log for good.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.ruby),
                ),
              ),
            ],
          ),
    );
    return confirmed ?? false;
  }

  Future<void> _onDismissed(DismissDirection direction, Quest quest) async {
    if (direction == DismissDirection.startToEnd) {
      await _complete(quest);
    } else if (direction == DismissDirection.endToStart) {
      await _delete(quest);
    }
  }

  Future<void> _delete(Quest quest) async {
    final provider = context.read<QuestListProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.removeQuest(quest);
    messenger.showSnackBar(SnackBar(content: Text('Deleted "${quest.title}"')));
  }

  Future<void> _complete(Quest quest) async {
    if (quest.isCompleted) return;
    final provider = context.read<QuestListProvider>();
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    await provider.markQuestCompleted(quest);
    final result = await appState.completeQuestForHero(
      quest.xpReward,
      completedToday: provider.completedTodayCount,
      quest: quest,
    );
    if (!mounted) return;

    showCelebration(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.gold,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Completed "${quest.title}"  ·  +${quest.xpReward} XP',
              ),
            ),
          ],
        ),
      ),
    );

    final hero = appState.hero;
    if (result.leveledUp && hero != null) {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        barrierLabel: 'Dismiss',
        transitionDuration: AppDurations.medium,
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                Center(child: LevelUpWidget(levelUp: hero.levelUp)),
      );
      if (!mounted) return;
    }

    await showAchievementsUnlocked(context, result.unlockedAchievements);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filterStatus});

  final QuestStatus? filterStatus;

  @override
  Widget build(BuildContext context) {
    final (asset, message) = switch (filterStatus) {
      QuestStatus.completed => (
        Art.finished,
        'No quests completed yet.\nSwipe one right to finish it.',
      ),
      QuestStatus.inProgress => (
        Art.todo,
        'The log is clear.\nYour hero awaits a new challenge.',
      ),
      null => (
        Art.all,
        'No quests yet.\nForge your first to start earning XP.',
      ),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: 0.85,
            child: PortholeBadge(
              asset: asset,
              size: 84,
              glow: AppColors.amethystBright,
            ),
          ),
          const SizedBox(height: AppPadding.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.body(
              size: 15,
              color: AppColors.inkMuted,
              style: FontStyle.italic,
            ),
          ),
          if (filterStatus != QuestStatus.completed) ...[
            const SizedBox(height: AppPadding.lg),
            QuestButton(
              label: 'Forge a quest',
              icon: Icons.auto_fix_high_rounded,
              expand: false,
              compact: true,
              onPressed: () => context.read<AppState>().setIndex(2),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.quest,
    required this.onEdit,
    required this.onComplete,
  });

  final Quest quest;
  final VoidCallback? onEdit;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.isCompleted;
    final color = categoryColor(quest.category);
    final now = DateTime.now();
    final overdue = quest.isOverdueAt(now);
    final dueToday = !overdue && !isCompleted && quest.isDueOn(now);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(10),
          child: ArcanePanel(
            radius: 10,
            ornate: false,
            fillOpacity: isCompleted ? 0.55 : 0.82,
            accent:
                overdue
                    ? AppColors.ruby
                    : isCompleted
                    ? AppColors.bronze
                    : AppColors.bronzeLight,
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                if (isCompleted)
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Image.asset(
                      Art.finished,
                      errorBuilder:
                          (_, _, _) => const GemRing(
                            icon: Icons.check_rounded,
                            color: AppColors.teal,
                            size: 46,
                          ),
                    ),
                  )
                else
                  GemRing(
                    icon: categoryIcon(quest.category),
                    color: color,
                    size: 46,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(
                          size: 16,
                          weight: FontWeight.w600,
                          color:
                              isCompleted ? AppColors.inkMuted : AppColors.ink,
                        ).copyWith(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.bronzeLight,
                        ),
                      ),
                      Text(
                        quest.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(
                          size: 13,
                          color: AppColors.inkMuted,
                          style: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (isCompleted)
                            const RuneTag(
                              text: 'DONE',
                              color: AppColors.teal,
                              icon: Icons.check_rounded,
                            )
                          else
                            RuneTag(
                              text:
                                  overdue
                                      ? 'OVERDUE'
                                      : dueToday
                                      ? 'TODAY · ${quest.timeRemainingLabelAt(now)}'
                                      : quest
                                          .timeRemainingLabelAt(now)
                                          .toUpperCase(),
                              color:
                                  overdue
                                      ? AppColors.ruby
                                      : dueToday
                                      ? AppColors.gold
                                      : AppColors.bronzeLight,
                              icon: Icons.hourglass_bottom_rounded,
                              filled: overdue || dueToday,
                            ),
                          RuneTag(
                            text:
                                '${difficultyLabel(quest.difficulty).toUpperCase()} · ${quest.xpReward} XP',
                            color: AppColors.gold,
                          ),
                          RuneTag(
                            text: quest.category.label.toUpperCase(),
                            color: color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isCompleted)
                  IconButton(
                    tooltip: 'Complete quest',
                    onPressed: onComplete,
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.bronzeLight,
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

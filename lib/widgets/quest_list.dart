import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/widgets/achievement_unlocked_dialog.dart';
import 'package:quest_key/widgets/celebration_overlay.dart';
import 'package:quest_key/widgets/lvl_notifcation.dart';

class QuestList extends StatefulWidget {
  /// Show only quests with this status; `null` shows every quest.
  final QuestStatus? filterStatus;

  const QuestList({super.key, this.filterStatus});

  @override
  State<QuestList> createState() => _QuestListState();
}

class _QuestListState extends State<QuestList> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestListProvider>();
    final quests = provider.getFilteredQuests(widget.filterStatus);

    return Container(
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: AppColors.bgDarkTransparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.borderMedium,
          width: AppBorders.thick,
        ),
      ),
      constraints: const BoxConstraints(maxHeight: AppHeights.questContainer),
      child:
          quests.isEmpty
              ? _EmptyState(filterStatus: widget.filterStatus)
              : ListView.builder(
                itemCount: quests.length,
                itemBuilder: (context, index) {
                  final quest = quests[index];

                  return Dismissible(
                    key: Key(quest.id.toString()),
                    direction:
                        quest.isCompleted
                            ? DismissDirection.endToStart
                            : DismissDirection.horizontal,
                    background: _swipeBackground(
                      color: AppColors.completeGreen,
                      icon: Icons.check_circle_rounded,
                      alignment: Alignment.centerLeft,
                    ),
                    secondaryBackground: _swipeBackground(
                      color: AppColors.deleteRed,
                      icon: Icons.delete_sweep,
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
                  );
                },
              ),
    );
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: AppIconSizes.lg),
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
            content: Text('"${quest.title}" will be removed for good.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
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

    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${quest.title}"'),
        backgroundColor: const Color.fromARGB(180, 238, 67, 55),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppPadding.lg),
      ),
    );
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
        content: Text('Completed "${quest.title}" (+${quest.xpReward} XP)'),
        backgroundColor: const Color.fromARGB(199, 45, 241, 255),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppPadding.lg),
      ),
    );

    final hero = appState.hero;
    if (result.leveledUp && hero != null) {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black54,
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
    final message = switch (filterStatus) {
      QuestStatus.completed =>
        'No completed quests yet.\nSwipe a quest right to finish it!',
      QuestStatus.inProgress =>
        'No quests in progress.\nYour hero awaits a new challenge!',
      null => 'No quests yet.\nCreate your first quest to start earning XP!',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          if (filterStatus != QuestStatus.completed) ...[
            const SizedBox(height: AppPadding.lg),
            FilledButton.icon(
              onPressed: () => context.read<AppState>().setIndex(2),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create a quest'),
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
    final categoryColor = Color(quest.category.colorValue);
    final now = DateTime.now();
    final overdue = quest.isOverdueAt(now);
    final dueSoon = !overdue && !isCompleted && quest.isDueOn(now);

    return Container(
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.completedGreen : AppColors.bgPurple,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: overdue ? Colors.redAccent : AppColors.borderTeal,
          width: overdue ? AppBorders.medium : AppBorders.thin,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppPadding.xs),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppPadding.lg,
          vertical: AppPadding.sm,
        ),
        leading:
            isCompleted
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.asset(
                    'assets/images/app_assets/finished.png',
                    width: AppImageSizes.questIcon,
                    height: AppImageSizes.questIcon,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, _, _) => _CategoryBadge(
                          quest: quest,
                          color: categoryColor,
                          dimmed: true,
                        ),
                  ),
                )
                : _CategoryBadge(quest: quest, color: categoryColor),
        title: Text(
          quest.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quest.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppPadding.xs),
            Wrap(
              spacing: AppPadding.sm,
              runSpacing: AppPadding.xs,
              children: [
                if (isCompleted)
                  const _Chip(text: 'Done', color: AppColors.accentGreen)
                else
                  _Chip(
                    text:
                        overdue
                            ? 'Overdue'
                            : dueSoon
                            ? 'Due today · ${quest.timeRemainingLabelAt(now)}'
                            : quest.timeRemainingLabelAt(now),
                    color:
                        overdue
                            ? Colors.redAccent
                            : dueSoon
                            ? AppColors.accentGold
                            : AppColors.textSecondary,
                    icon: Icons.schedule,
                  ),
                _Chip(
                  text: '${'★' * quest.difficulty} +${quest.xpReward} XP',
                  color: AppColors.accentGold,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing:
            isCompleted
                ? const Icon(
                  Icons.check_circle,
                  color: AppColors.accentGreen,
                  size: AppIconSizes.md,
                )
                : IconButton(
                  tooltip: 'Complete quest',
                  onPressed: onComplete,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.textTertiary,
                    size: AppIconSizes.md,
                  ),
                ),
        onTap: onEdit,
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.quest,
    required this.color,
    this.dimmed = false,
  });

  final Quest quest;
  final Color color;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppImageSizes.questIcon,
      height: AppImageSizes.questIcon,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dimmed ? 0.3 : 0.85),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(quest.category.icon, style: const TextStyle(fontSize: 24)),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: AppFontSizes.xs - 1,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

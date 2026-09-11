import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
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
              ? Center(
                child: Text(
                  'No quests available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              )
              : ListView.builder(
                itemCount: quests.length,
                itemBuilder: (context, index) {
                  final quest = quests[index];

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent:
                            ModalRoute.of(context)?.animation ??
                            const AlwaysStoppedAnimation(1.0),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: Dismissible(
                      key: Key(quest.id.toString()),
                      direction: _dismissDirectionFor(quest),
                      background: Container(
                        padding: const EdgeInsets.only(left: AppPadding.xl),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: AppColors.completeGreen,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.textPrimary,
                          size: AppIconSizes.lg,
                        ),
                      ),
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: AppColors.deleteRed,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppPadding.xl),
                        child: const Icon(
                          Icons.delete_sweep,
                          color: AppColors.textPrimary,
                          size: AppIconSizes.lg,
                        ),
                      ),
                      onDismissed: (direction) {
                        _handleQuestDismiss(direction, quest, provider, context);
                      },
                      child: _buildQuestTile(quest, provider, context),
                    ),
                  );
                },
              ),
    );
  }

  /// On the "All" list and for completed quests only deletion (swipe left)
  /// is allowed; in-progress quests on a filtered list can also be completed
  /// by swiping right.
  DismissDirection _dismissDirectionFor(Quest quest) {
    if (widget.filterStatus == null || quest.isCompleted) {
      return DismissDirection.endToStart;
    }
    return DismissDirection.horizontal;
  }

  Widget _buildQuestTile(
    Quest quest,
    QuestListProvider provider,
    BuildContext context,
  ) {
    final isCompleted = quest.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.completedGreen : AppColors.bgPurple,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.borderTeal,
          width: AppBorders.thin,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppPadding.xs),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppPadding.lg,
          vertical: AppPadding.sm,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.asset(
            isCompleted
                ? 'assets/images/app_assets/finished.png'
                : quest.questImageUrl,
            width: AppImageSizes.questIcon,
            height: AppImageSizes.questIcon,
            fit: BoxFit.cover,
          ),
        ),
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
        subtitle: Text(
          quest.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          isCompleted ? Icons.check_circle : Icons.edit,
          color: AppColors.textTertiary,
          size: AppIconSizes.md,
        ),
        onTap: () {
          if (!isCompleted) {
            provider.setSelectedQuest(quest);
            context.read<AppState>().setIndex(2);
          }
        },
      ),
    );
  }

  Future<void> _handleQuestDismiss(
    DismissDirection direction,
    Quest quest,
    QuestListProvider provider,
    BuildContext context,
  ) async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    if (direction == DismissDirection.startToEnd && !quest.isCompleted) {
      await provider.markQuestCompleted(quest);
      final leveledUp = await appState.completeQuestForHero(quest.xpReward);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Completed "${quest.title}" (+${quest.xpReward} XP)'),
          backgroundColor: const Color.fromARGB(199, 45, 241, 255),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppPadding.lg),
        ),
      );

      final hero = appState.hero;
      if (leveledUp && hero != null && context.mounted) {
        await showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          barrierLabel: 'Dismiss',
          transitionDuration: AppDurations.medium,
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  Center(child: LevelUpWidget(levelUp: hero.levelUp)),
        );
      }
    } else if (direction == DismissDirection.endToStart) {
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
  }
}

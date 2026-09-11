import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/services/storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/lvl_notifcation.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

class QuestList extends StatefulWidget {
  final String? filterStatus;

  const QuestList({super.key, this.filterStatus});

  @override
  State<QuestList> createState() => _QuestListState();
}

class _QuestListState extends State<QuestList> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestListProvider>();
    final allQuests = provider.quests;
    final rawQuests =
        widget.filterStatus != null
            ? allQuests
                .where((quest) => quest.status == widget.filterStatus)
                .toList()
            : allQuests;

    final quests = [...rawQuests];

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
                        parent: ModalRoute.of(context)?.animation ??
                            AlwaysStoppedAnimation(1.0),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: Dismissible(
                      key: Key(quest.id.toString()),
                      direction:
                          widget.filterStatus == null ||
                                  widget.filterStatus == 'All'
                              ? DismissDirection.endToStart
                              : quest.status == 'Completed'
                              ? DismissDirection.endToStart
                              : DismissDirection.horizontal,
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
                        _handleQuestDismiss(
                          direction,
                          quest,
                          provider,
                          context,
                        );
                      },
                      child: _buildQuestTile(quest, provider, context),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildQuestTile(
    dynamic quest,
    QuestListProvider provider,
    BuildContext context,
  ) {
    final isCompleted = quest.status == 'Completed';

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

  void _handleQuestDismiss(
    DismissDirection direction,
    dynamic quest,
    QuestListProvider provider,
    BuildContext context,
  ) {
    final hero = context.read<AppState>().hero;

    if (direction == DismissDirection.startToEnd &&
        quest.status != 'Completed') {
      provider.markQuestCompleted(quest);

      if (hero != null) {
        final leveledUp = hero.gainExperience(quest.xpReward);
        context.read<AppState>().saveHero(hero);

        if (leveledUp) {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierColor: Colors.black54,
            barrierLabel: 'Dismiss',
            transitionDuration: AppDurations.medium,
            pageBuilder: (context, animation, secondaryAnimation) =>
                Center(
                  child: LevelUpWidget(
                    levelUp: hero.levelUp,
                  ),
                ),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completed "${quest.title}"'),
          backgroundColor: const Color.fromARGB(199, 45, 241, 255),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppPadding.lg),
        ),
      );
    } else if (direction == DismissDirection.endToStart) {
      provider.removeQuest(quest);

      ScaffoldMessenger.of(context).showSnackBar(
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

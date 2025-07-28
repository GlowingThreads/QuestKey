import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/services/storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/lvl_notifcation.dart';

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
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(100, 29, 17, 62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      constraints: const BoxConstraints(maxHeight: 450),
      child:
          quests.isEmpty
              ? const Center(
                child: Text(
                  'No quests available',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              )
              : ListView.builder(
                itemCount: quests.length,
                itemBuilder: (context, index) {
                  final quest = quests[index];

                  return Dismissible(
                    key: Key(quest.id.toString()),
                    direction:
                        widget.filterStatus == null ||
                                widget.filterStatus == 'All'
                            ? DismissDirection
                                .endToStart // delete on all
                            : quest.status == 'Completed'
                            ? DismissDirection
                                .endToStart // delete on comp
                            : DismissDirection
                                .horizontal, // both for in progress

                    background: Container(
                      padding: const EdgeInsets.only(left: 20),
                      alignment: Alignment.centerLeft,
                      color: const Color.fromARGB(128, 86, 183, 118),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    secondaryBackground: Container(
                      color: const Color.fromARGB(128, 139, 21, 12),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Icons.delete_sweep,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
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
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
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
                            backgroundColor: const Color.fromARGB(
                              199,
                              45,
                              241,
                              255,
                            ),
                          ),
                        );
                      } else if (direction == DismissDirection.endToStart) {
                        provider.removeQuest(quest);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deleted "${quest.title}"'),
                            backgroundColor: const Color.fromARGB(
                              180,
                              238,
                              67,
                              55,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            quest.status == 'Completed'
                                ? const Color.fromARGB(128, 23, 135, 81)
                                : const Color.fromARGB(128, 128, 0, 128),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color.fromARGB(60, 22, 255, 174),
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Image.asset(
                          quest.status == 'Completed'
                              ? 'assets/images/app_assets/finished.png'
                              : quest.questImageUrl,
                          width: 50,
                          height: 50,
                        ),
                        title: Text(
                          quest.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          quest.description,
                          style: const TextStyle(
                            color: Color.fromARGB(199, 255, 255, 255),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.edit,
                          color: Color.fromARGB(199, 255, 255, 255),
                        ),
                        onTap: () {
                          provider.setSelectedQuest(quest);
                          context.read<AppState>().setIndex(2);
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

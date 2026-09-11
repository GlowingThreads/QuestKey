import 'package:flutter/material.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/widgets/quest_list.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  /// `null` means "All".
  QuestStatus? _filter = QuestStatus.inProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_assets/quests_bkg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(200, 0, 0, 0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color.fromARGB(100, 255, 255, 255),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Filter bar
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 35, 9, 80).withAlpha(200),
                      border: Border.all(
                        color: const Color.fromARGB(99, 255, 255, 255),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _filterIcon('todo.png', QuestStatus.inProgress),
                          const SizedBox(width: 12),
                          _filterIcon('all.png', null),
                          const SizedBox(width: 12),
                          _filterIcon('finished.png', QuestStatus.completed),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quest Log',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Quest list
                  Expanded(
                    child: QuestList(filterStatus: _filter),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterIcon(String assetName, QuestStatus? status) {
    final label = status?.label ?? 'All';
    final isSelected = _filter == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border:
              isSelected
                  ? Border.all(
                    color: const Color.fromARGB(180, 59, 251, 148),
                    width: 2,
                  )
                  : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/app_assets/$assetName',
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color:
                    isSelected
                        ? const Color.fromARGB(255, 59, 251, 148)
                        : const Color.fromARGB(255, 255, 255, 255),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

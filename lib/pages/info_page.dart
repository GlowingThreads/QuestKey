import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/services/storage.dart';
import 'package:quest_key/pages/create_hero_page.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_assets/info_bkg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(128, 26, 8, 28),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.7),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 29, 17, 62),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: Colors.white, width: 2.0),
                      ),
                      child: const Text(
                        'Welcome to Quest Key!\n\nAn RPG To-Do List Application.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      _infoText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (ctx) => CreateHeroPage(
                                  onHeroCreated:
                                      (
                                        _,
                                      ) {}, // <- empty callback to satisfy the required parameter
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 13, 5, 35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(
                            color: Color.fromARGB(255, 214, 115, 241),
                            width: 2.0,
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.person_add, size: 20),
                          SizedBox(width: 8),
                          Text('Create Hero'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                backgroundColor: const Color.fromARGB(
                                  230,
                                  24,
                                  6,
                                  6,
                                ),
                                title: const Text(
                                  'Adventurer, are you certain?',
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                content: const Text(
                                  'This will permanently delete your hero and all related quests and progress.',
                                  style: TextStyle(
                                    color: Color.fromARGB(179, 210, 207, 207),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Yes, delete',
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 255, 204, 0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        );

                        if (confirm != true) return;

                        await StorageService.clearAllData();

                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        appState.hero = null;

                        context
                            .read<QuestListProvider>()
                            .loadQuestsFromStorage();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hero and quests cleared'),
                          ),
                        );

                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        backgroundColor: const Color.fromARGB(255, 240, 15, 15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(
                            color: Color.fromARGB(255, 248, 214, 21),
                            width: 2,
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Clear Hero Data'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Info instructions
const String _infoText = '''
Create your hero and embark on quests!

• Tap "Create Quest" to add new tasks.
• Complete quests to earn XP and level up.
• Leveling lets you assign stat points and improve your hero.

Track your progress on the Hero Page.

In the Quest Log you can:
✓ View ongoing and completed quests.
↔ Swipe right to complete a quest.
↔ Swipe left to delete a quest.
✎ Long press a quest to edit it.

Tap "Create Hero" to begin your adventure!
''';

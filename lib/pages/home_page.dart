import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/quest_list.dart';
import 'package:quest_key/widgets/xp_bar.dart';
import 'package:quest_key/widgets/hero_info.dart';
import 'package:quest_key/services/storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final appState = context.read<AppState>();
    final quests = context.read<QuestListProvider>();

    await appState.loadHeroFromStorage();
    await quests.loadQuestsFromStorage();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final hero = context.watch<AppState>().hero;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

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
                    const Text(
                      'Hero not found.',
                      style: TextStyle(color: Colors.white),
                    ),
                  const SizedBox(height: 20),
                  QuestList(filterStatus: 'In Progress'),
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

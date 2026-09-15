import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/pages/create_quest.dart';
import 'package:quest_key/pages/hero_creation_page.dart';
import 'package:quest_key/pages/hero_page.dart';
import 'package:quest_key/pages/home_page.dart';
import 'package:quest_key/pages/info_page.dart';
import 'package:quest_key/pages/quests_page.dart';
import 'package:quest_key/services/notification_services.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/widgets/nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  final appState = AppState();
  await appState.loadHeroFromStorage();

  final questProvider = QuestListProvider();
  await questProvider.loadQuestsFromStorage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => appState),
        ChangeNotifierProvider(create: (context) => questProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quest Key',
      theme: AppTheme.dark(),
      home: const MainScreen(),
      routes: {
        '/create_quest': (context) => const CreateQuestPage(),
        '/create_hero': (context) => const HeroCreationPage(),
        '/hero_page': (context) => const HeroPage(),
        '/quests_page': (context) => const QuestsPage(),
        '/info_page': (context) => const InfoPage(),
        '/home_page': (context) => const HomePage(),
      },
    );
  }
}

/// Root of the app: the hero-creation wizard until a hero exists, then the
/// five tabs behind the custom navigation bar.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<Widget> _pages = [
    HomePage(),
    QuestsPage(),
    CreateQuestPage(),
    HeroPage(),
    InfoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child:
          appState.hasHero
              ? _Tabs(index: appState.currentIndex)
              : const HeroCreationPage(
                key: ValueKey('onboarding'),
                isOnboarding: true,
              ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(index),
          child: MainScreen._pages[index],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: index,
        onTap: (newIndex) => context.read<AppState>().setIndex(newIndex),
      ),
    );
  }
}

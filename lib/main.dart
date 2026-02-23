import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/pages/create_quest.dart';
import 'package:quest_key/pages/quests_page.dart';
import 'package:quest_key/widgets/nav_bar.dart';
import 'package:quest_key/pages/info_page.dart';
import 'package:quest_key/pages/home_page.dart';
import 'package:quest_key/pages/hero_page.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/services/storage.dart';
import 'package:quest_key/services/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize(); // <-- Add this line

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
      theme: ThemeData.dark(),
      home: const MainScreen(),
      routes: {
        '/create_quest': (context) => const CreateQuestPage(),
        '/hero_page': (context) => const HeroPage(),
        '/quests_page': (context) => const QuestsPage(),
        '/info_page': (context) => const InfoPage(),
        '/home_page': (context) => const HomePage(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final List<Widget> _pages;
  late final int _initialIndex;

  @override
  void initState() {
    super.initState();
    final hero = context.read<AppState>().hero;

    //set based on if hero exists - direct to home or info
    _initialIndex = hero == null ? 4 : 0;

    _pages = [
      const HomePage(),
      const QuestsPage(),
      const CreateQuestPage(),
      const HeroPage(),
      const InfoPage(),
    ];

    //instance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().setIndex(_initialIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = context.watch<AppState>().currentIndex;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(index),
          child: _pages[index],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: index,
        onTap: (newIndex) {
          context.read<AppState>().setIndex(newIndex);
        },
      ),
    );
  }
}

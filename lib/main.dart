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
import 'package:quest_key/state/encounter_provider.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  final appState = AppState();
  await appState.loadHeroFromStorage();
  await appState.processNewDay();

  final questProvider = QuestListProvider();
  await questProvider.loadQuestsFromStorage();

  final encounters = EncounterProvider(
    appState: appState,
    quests: questProvider,
  );
  await encounters.refresh();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => appState),
        ChangeNotifierProvider(create: (context) => questProvider),
        ChangeNotifierProvider(create: (context) => encounters),
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
/// five tabs behind the custom navigation bar. Re-runs the daily rest and
/// rolls the day's encounter whenever the app returns to the foreground.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const List<Widget> pages = [
    HomePage(),
    QuestsPage(),
    CreateQuestPage(),
    HeroPage(),
    InfoPage(),
  ];

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const List<String> _artToPrecache = [
    Art.homeBackground,
    Art.questsBackground,
    Art.createBackground,
    Art.heroBackground,
    Art.infoBackground,
    Art.createHeroBackground,
    Art.home,
    Art.questLog,
    Art.create,
    Art.hero,
    Art.info,
    Art.todo,
    Art.all,
    Art.finished,
    Art.progressBadge,
    Art.levelUp,
    Art.appIcon,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Allow more decoded images to stay resident (default is 100 MB).
    PaintingBinding.instance.imageCache.maximumSizeBytes = 256 << 20;
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheArt());
  }

  Future<void> _precacheArt() async {
    for (final asset in _artToPrecache) {
      if (!mounted) return;
      final isBackground = asset.contains('_bkg');
      try {
        await precacheImage(
          isBackground
              ? ResizeImage(AssetImage(asset), width: 1080)
              : AssetImage(asset),
          context,
        );
      } catch (_) {
        // Missing art is tolerated; widgets have fallbacks.
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final appState = context.read<AppState>();
      final encounters = context.read<EncounterProvider>();
      appState.processNewDay().then((_) => encounters.refresh());
    }
  }

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
          child: MainScreen.pages[index],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: index,
        onTap: (newIndex) => context.read<AppState>().setIndex(newIndex),
      ),
    );
  }
}

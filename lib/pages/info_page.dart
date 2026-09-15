import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/pages/hero_creation_page.dart';
import 'package:quest_key/services/storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Adventurer's guide: how the game works, hero management and the danger
/// zone for clearing data.
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  static const List<({IconData icon, String title, String body})> _howTo = [
    (
      icon: Icons.auto_fix_high,
      title: 'Forge quests',
      body:
          'Turn any task into a quest on the Create tab. Pick a category, a '
          'difficulty (more stars = more XP) and a due time.',
    ),
    (
      icon: Icons.swipe_right_alt,
      title: 'Complete them',
      body:
          'Swipe a quest right or tap its ✓ to finish it and earn XP. Swipe '
          'left to delete (you will be asked to confirm). Tap to edit.',
    ),
    (
      icon: Icons.trending_up,
      title: 'Level up',
      body:
          'Fill the XP bar to level up. Every level grants 3 stat points to '
          'spend on the Hero tab, and unlocks new skills to learn.',
    ),
    (
      icon: Icons.local_fire_department,
      title: 'Keep the streak',
      body:
          'Complete at least one quest a day to build a streak. Streaks, '
          'quest counts and stats unlock achievements, some of them hidden.',
    ),
    (
      icon: Icons.notifications_active_outlined,
      title: 'Reminders',
      body:
          'Turn on "Remind me" for a quest and Quest Key notifies you 30 '
          'minutes before it is due, even after a reboot.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final hasHero = context.watch<AppState>().hasHero;

    return Scaffold(
      body: PageBackground(
        asset: 'assets/images/app_assets/info_bkg.png',
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.xxl,
              AppPadding.lg,
              AppPadding.xxl,
              110,
            ),
            children: [
              FadeSlideIn(
                child: GlassPanel(
                  glowColor: AppColors.accentPurple,
                  child: Column(
                    children: [
                      const Text('🗝️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: AppPadding.sm),
                      Text(
                        'Quest Key',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text(
                        'An RPG to-do list. Your tasks are quests; finishing '
                        'them makes your hero stronger.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.lg),
              const FadeSlideIn(
                delay: Duration(milliseconds: 80),
                child: SectionHeader(
                  icon: Icons.menu_book_outlined,
                  title: "Adventurer's guide",
                ),
              ),
              const SizedBox(height: AppPadding.sm),
              for (var i = 0; i < _howTo.length; i++)
                FadeSlideIn(
                  delay: Duration(milliseconds: 120 + 50 * i),
                  child: GlassPanel(
                    margin: const EdgeInsets.only(bottom: AppPadding.sm),
                    padding: const EdgeInsets.all(AppPadding.md),
                    radius: AppRadius.md,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppPadding.sm),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurple.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            _howTo[i].icon,
                            color: AppColors.accentGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppPadding.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _howTo[i].title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _howTo[i].body,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: AppFontSizes.xs,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppPadding.lg),
              FadeSlideIn(
                delay: const Duration(milliseconds: 420),
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.person_outline,
                        title: 'Your hero',
                      ),
                      const SizedBox(height: AppPadding.md),
                      QuestButton(
                        label:
                            hasHero ? 'Create a new hero' : 'Create your hero',
                        icon: Icons.person_add_alt_1,
                        onPressed: () => _openCreateHero(context),
                      ),
                      if (hasHero)
                        const Padding(
                          padding: EdgeInsets.only(top: AppPadding.sm),
                          child: Text(
                            'Replaces your current hero and level. Quests are kept.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppFontSizes.xs,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.lg),
              FadeSlideIn(
                delay: const Duration(milliseconds: 480),
                child: GlassPanel(
                  borderColor: Colors.redAccent.withValues(alpha: 0.6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.warning_amber_rounded,
                        title: 'Danger zone',
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: AppPadding.md),
                      QuestButton(
                        label: 'Clear hero and quest data',
                        icon: Icons.delete_forever_outlined,
                        colors: const [Color(0xFF7F0000), Color(0xFFD32F2F)],
                        glow: Colors.redAccent,
                        onPressed: () => _confirmClear(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.lg),
              const FadeSlideIn(
                delay: Duration(milliseconds: 540),
                child: Text(
                  'Everything is stored on this device only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppFontSizes.xs,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the hero creator; asks first if it would replace an existing hero.
  Future<void> _openCreateHero(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (context.read<AppState>().hasHero) {
      final replace = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Replace your hero?'),
              content: const Text(
                'Creating a new hero replaces your current hero, level and '
                'stats. Your quests are kept.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Replace'),
                ),
              ],
            ),
      );
      if (replace != true) return;
    }
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const HeroCreationPage()),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final appState = context.read<AppState>();
    final questProvider = context.read<QuestListProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Adventurer, are you certain?'),
            content: const Text(
              'This permanently deletes your hero and all quests and progress.',
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Yes, delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    await StorageService.clearAllData();
    appState.clearHero();
    await questProvider.loadQuestsFromStorage();
    messenger.showSnackBar(
      const SnackBar(content: Text('Hero and quests cleared')),
    );
  }
}

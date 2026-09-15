import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/pages/hero_creation_page.dart';
import 'package:quest_key/services/storage.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/encounter_provider.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// The Guide: how the game works, hero management and the danger zone.
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  static const List<({IconData icon, String title, String body})> _chapters = [
    (
      icon: Icons.auto_fix_high_rounded,
      title: 'Forge quests',
      body:
          'Any task becomes a quest on the Create tab. Choose a category, set '
          'the difficulty (harder quests pay more XP) and a due time.',
    ),
    (
      icon: Icons.swipe_right_alt_rounded,
      title: 'See them through',
      body:
          'Swipe a quest right, or tap its seal, to complete it and claim the '
          'XP. Swipe left to strike it from the log. Tap to edit.',
    ),
    (
      icon: Icons.military_tech_rounded,
      title: 'Grow in power',
      body:
          'Fill the experience ring to level up. Each level grants three '
          'attribute points and opens new pages of the grimoire.',
    ),
    (
      icon: Icons.local_fire_department_rounded,
      title: 'Keep the flame',
      body:
          'Complete at least one quest a day to build a streak. Streaks, '
          'quest counts, punctuality and attributes press honours in wax; '
          'some are hidden. Tap one to wear it as your title.',
    ),
    (
      icon: Icons.auto_fix_high_rounded,
      title: 'Cast spells',
      body:
          'Learned skills are spells. They cost mana or stamina, which refill '
          'each dawn and a little with every quest. Long-press a quest or tap '
          'its wand to mend, snooze, enchant, shift or burn it; cast buffs, '
          'shields and prayers from the grimoire. Disciplines are passive and '
          'always on.',
    ),
    (
      icon: Icons.whatshot_rounded,
      title: 'Guard the torch',
      body:
          'A day without a completed quest burns a quarter of your torch. '
          'Shield charges absorb missed days. If the flame goes out the '
          'streak resets, but the torch relights and you carry on.',
    ),
    (
      icon: Icons.explore_rounded,
      title: 'Answer encounters',
      body:
          'Most days a stranger, a rumour or a threat appears on Home. Accept '
          'it for a bonus quest, walk on, or use Stealth or Fireball to '
          'resolve it on the spot.',
    ),
    (
      icon: Icons.notifications_active_outlined,
      title: 'Reminders',
      body:
          'Enable "Remind me" and Quest Key notifies you thirty minutes '
          'before a quest is due, even after the device restarts.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final hasHero = context.watch<AppState>().hasHero;

    return Scaffold(
      body: PageBackground(
        asset: Art.infoBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
            children: [
              FadeSlideIn(
                child: ArcanePanel(
                  glow: AppColors.amethystBright,
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.magenta.withValues(alpha: 0.4),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            Art.appIcon,
                            errorBuilder:
                                (_, _, _) => const GemRing(
                                  icon: Icons.key_rounded,
                                  size: 72,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quest Key',
                              style: AppFonts.heading(size: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'A to-do list written as an adventure. Your tasks are '
                              'quests; finishing them makes your hero stronger.',
                              style: AppFonts.body(
                                size: 13,
                                color: AppColors.inkMuted,
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
              const FadeSlideIn(
                delay: Duration(milliseconds: 80),
                child: Row(
                  children: [
                    PortholeBadge(asset: Art.info, size: 52),
                    SizedBox(width: 10),
                    Expanded(
                      child: SectionHeader(
                        title: "Adventurer's Guide",
                        rule: false,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppPadding.sm),
              for (var i = 0; i < _chapters.length; i++)
                FadeSlideIn(
                  delay: Duration(milliseconds: 120 + 50 * i),
                  child: ArcanePanel(
                    ornate: false,
                    radius: 10,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GemRing(
                          icon: _chapters[i].icon,
                          color: AppColors.amethyst,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_roman(i + 1)}.  ${_chapters[i].title}',
                                style: AppFonts.heading(
                                  size: 13,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _chapters[i].body,
                                style: AppFonts.body(
                                  size: 13,
                                  color: AppColors.inkMuted,
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
                child: ArcanePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.person_outline_rounded,
                        title: 'Your Hero',
                      ),
                      const SizedBox(height: 12),
                      QuestButton(
                        label:
                            hasHero ? 'Summon a new hero' : 'Summon your hero',
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: () => _openCreateHero(context),
                      ),
                      if (hasHero)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Replaces your current hero and level. Quests are kept.',
                            style: AppFonts.body(
                              size: 12,
                              color: AppColors.inkMuted,
                              style: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 450),
                child: ArcanePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.menu_book_rounded,
                        title: 'Save Codex',
                        subtitle:
                            'Your hero and quests are saved on this device after every change and kept in Android backup. Copy them out to move devices or keep your own copy.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: QuestButton(
                              label: 'Copy save',
                              icon: Icons.copy_all_rounded,
                              compact: true,
                              onPressed: () => _exportSave(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: QuestButton(
                              label: 'Restore save',
                              icon: Icons.restore_rounded,
                              compact: true,
                              style: QuestButtonStyle.ghost,
                              onPressed: () => _importSave(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 480),
                child: ArcanePanel(
                  accent: AppColors.ruby,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.warning_amber_rounded,
                        title: 'Danger Zone',
                        color: AppColors.ruby,
                      ),
                      const SizedBox(height: 12),
                      QuestButton(
                        label: 'Erase hero and quests',
                        icon: Icons.delete_forever_outlined,
                        style: QuestButtonStyle.danger,
                        onPressed: () => _confirmClear(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.lg),
              FadeSlideIn(
                delay: const Duration(milliseconds: 540),
                child: Text(
                  'Everything is stored on this device only.',
                  textAlign: TextAlign.center,
                  style: AppFonts.body(
                    size: 12,
                    color: AppColors.inkMuted,
                    style: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _roman(int n) {
    const numerals = [(10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I')];
    var value = n;
    final buffer = StringBuffer();
    for (final (arabic, roman) in numerals) {
      while (value >= arabic) {
        buffer.write(roman);
        value -= arabic;
      }
    }
    return buffer.toString();
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
                'Summoning a new hero replaces your current hero, level and '
                'attributes. Your quests are kept.',
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

  Future<void> _exportSave(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = await SaveCodex(StorageService.instance).export();
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Save copied to the clipboard. Paste it somewhere safe, or into '
          '"Restore save" on another device.',
        ),
      ),
    );
  }

  Future<void> _importSave(BuildContext context) async {
    final appState = context.read<AppState>();
    final questProvider = context.read<QuestListProvider>();
    final encounters = context.read<EncounterProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;

    final controller = TextEditingController(text: clipboard?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restore a save'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paste a save copied from Quest Key. It replaces the hero '
                  'and quests on this device.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  style: AppFonts.body(size: 11),
                  decoration: const InputDecoration(
                    hintText: '{ "format": "questkey-save", ... }',
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Restore'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty) return;

    try {
      await SaveCodex(StorageService.instance).import(text);
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    await appState.loadHeroFromStorage();
    await appState.processNewDay();
    await questProvider.loadQuestsFromStorage();
    await encounters.reload();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          appState.hero == null
              ? 'Save restored.'
              : 'Save restored. Welcome back, ${appState.hero!.name}.',
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final appState = context.read<AppState>();
    final questProvider = context.read<QuestListProvider>();
    final encounters = context.read<EncounterProvider>();
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
                  'Yes, erase',
                  style: TextStyle(color: AppColors.ruby),
                ),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    await StorageService.clearAllData();
    appState.clearHero();
    await questProvider.loadQuestsFromStorage();
    await encounters.clear();
    messenger.showSnackBar(
      const SnackBar(content: Text('Hero and quests erased')),
    );
  }
}

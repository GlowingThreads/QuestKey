import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/character_background.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/classes.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/widgets/celebration_overlay.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Emoji shown for each class (the class images are optional assets).
String classEmoji(String className) => switch (className.toLowerCase()) {
  'fighter' => '⚔️',
  'wizard' => '🧙',
  'rogue' => '🗡️',
  'paladin' => '🛡️',
  'warlock' => '🔮',
  'monk' => '🥋',
  'cleric' => '✨',
  'ranger' => '🏹',
  'barbarian' => '🪓',
  _ => '🛡️',
};

/// Five-step hero creation wizard: identity → class → origin → avatar →
/// summon. Used as the onboarding screen when no hero exists
/// ([isOnboarding] = true, nothing to pop) and from the Guide tab to
/// replace an existing hero.
class HeroCreationPage extends StatefulWidget {
  const HeroCreationPage({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  static const int stepCount = 5;
  static const List<String> stepTitles = [
    'Identity',
    'Class',
    'Origin',
    'Avatar',
    'Summon',
  ];

  @override
  State<HeroCreationPage> createState() => _HeroCreationPageState();
}

class _HeroCreationPageState extends State<HeroCreationPage> {
  static const List<String> _randomNames = [
    'Aldric',
    'Brynn',
    'Caelum',
    'Dara',
    'Elowen',
    'Fenwick',
    'Gwyn',
    'Halvard',
    'Isolde',
    'Jorah',
    'Kestrel',
    'Lyra',
    'Maelis',
    'Nyx',
    'Orin',
    'Perrin',
    'Rhoswen',
    'Sable',
    'Thane',
    'Vesper',
  ];
  static const List<String> _randomMottos = [
    'One quest at a time.',
    'Fortune favours the prepared.',
    'Small steps, great journeys.',
    'No task too small.',
    'Forward, always.',
    'Done is better than perfect.',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mottoController = TextEditingController();
  final _random = Random();

  int _step = 0;
  int _direction = 1;
  Classes? _selectedClass;
  CharacterBackground? _selectedBackground;
  String? _selectedImage;
  bool _summoning = false;

  static final List<String> _heroImages = List.generate(
    16,
    (index) => 'assets/images/character_images/hero_${index + 1}.png',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _mottoController.dispose();
    super.dispose();
  }

  bool get _stepValid => switch (_step) {
    0 =>
      _nameController.text.trim().isNotEmpty &&
          _mottoController.text.trim().isNotEmpty,
    1 => _selectedClass != null,
    2 => true,
    3 => _selectedImage != null,
    _ => true,
  };

  void _goTo(int step) {
    setState(() {
      _direction = step > _step ? 1 : -1;
      _step = step.clamp(0, HeroCreationPage.stepCount - 1);
    });
  }

  void _next() {
    if (_step == 0 && !(_formKey.currentState?.validate() ?? false)) return;
    if (!_stepValid) return;
    FocusScope.of(context).unfocus();
    _goTo(_step + 1);
  }

  void _back() => _goTo(_step - 1);

  void _randomise() {
    setState(() {
      _nameController.text = _randomNames[_random.nextInt(_randomNames.length)];
      _mottoController.text =
          _randomMottos[_random.nextInt(_randomMottos.length)];
    });
  }

  /// The hero as it will be created from the current choices.
  HeroCharacter? get _previewHero {
    final classes = _selectedClass;
    final image = _selectedImage;
    if (classes == null || image == null) return null;
    var hero = HeroCharacter.fromClasses(classes).copyWith(
      name: _nameController.text.trim(),
      motto: _mottoController.text.trim(),
      imageUrl: image,
    );
    final background = _selectedBackground;
    if (background != null) hero = hero.withBackground(background);
    return hero;
  }

  Future<void> _summon() async {
    final hero = _previewHero;
    if (hero == null || _summoning) return;
    setState(() => _summoning = true);

    final appState = context.read<AppState>();
    final navigator = Navigator.of(context);
    await appState.saveHero(hero);
    if (!mounted) return;

    showCelebration(context);
    if (!widget.isOnboarding && navigator.canPop()) {
      navigator.pop();
    } else {
      appState.setIndex(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        asset: 'assets/images/app_assets/hero_bkg.jpg',
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                step: _step,
                isOnboarding: widget.isOnboarding,
                onStepTap: (i) => i < _step ? _goTo(i) : null,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDurations.medium,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: Offset(0.15 * _direction, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  layoutBuilder:
                      (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, if (current != null) current],
                      ),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_step),
                    child: _buildStep(),
                  ),
                ),
              ),
              _Footer(
                step: _step,
                canContinue: _stepValid && !_summoning,
                onBack: _step == 0 ? null : _back,
                onNext:
                    _step == HeroCreationPage.stepCount - 1 ? _summon : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    final padding = const EdgeInsets.fromLTRB(
      AppPadding.xl,
      AppPadding.sm,
      AppPadding.xl,
      AppPadding.xl,
    );
    return switch (_step) {
      0 => SingleChildScrollView(padding: padding, child: _identityStep()),
      1 => SingleChildScrollView(padding: padding, child: _classStep()),
      2 => SingleChildScrollView(padding: padding, child: _originStep()),
      3 => SingleChildScrollView(padding: padding, child: _avatarStep()),
      _ => SingleChildScrollView(padding: padding, child: _summonStep()),
    };
  }

  // ---------------------------------------------------------------- step 0
  Widget _identityStep() {
    return FadeSlideIn(
      child: GlassPanel(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                icon: Icons.badge_outlined,
                title: 'Who are you?',
                subtitle: 'Every legend starts with a name.',
              ),
              const SizedBox(height: AppPadding.lg),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: 'Hero name',
                  prefixIcon: Icon(Icons.person_outline),
                  counterText: '',
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Please enter a name'
                            : null,
              ),
              const SizedBox(height: AppPadding.md),
              TextFormField(
                controller: _mottoController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Motto or tagline',
                  prefixIcon: Icon(Icons.format_quote),
                  counterText: '',
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Please enter a motto'
                            : null,
              ),
              const SizedBox(height: AppPadding.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _randomise,
                  icon: const Icon(Icons.casino_outlined),
                  label: const Text('Roll a random name'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- step 1
  Widget _classStep() {
    final selected = _selectedClass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideIn(
          child: SectionHeader(
            icon: Icons.shield_outlined,
            title: 'Choose your class',
            subtitle: 'Your class sets your starting stats.',
          ),
        ),
        const SizedBox(height: AppPadding.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppPadding.sm,
            crossAxisSpacing: AppPadding.sm,
            childAspectRatio: 0.95,
          ),
          itemCount: classesList.length,
          itemBuilder: (context, index) {
            final classes = classesList[index];
            final isSelected = selected == classes;
            return FadeSlideIn(
              delay: Duration(milliseconds: 40 * index),
              child: _ClassCard(
                classes: classes,
                selected: isSelected,
                onTap: () => setState(() => _selectedClass = classes),
              ),
            );
          },
        ),
        const SizedBox(height: AppPadding.lg),
        AnimatedSize(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          child:
              selected == null
                  ? const SizedBox.shrink()
                  : GlassPanel(
                    key: ValueKey(selected.className),
                    glowColor: AppColors.accentPurple,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              classEmoji(selected.className),
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: AppPadding.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selected.className,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    selected.description,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppPadding.md),
                        _StatBars(values: _statsOf(selected)),
                        const SizedBox(height: AppPadding.sm),
                        Text(
                          'HP ${selected.health} · MP ${selected.mana} · '
                          'Stamina ${selected.stamina}',
                          style: const TextStyle(
                            color: AppColors.accentGreen,
                            fontSize: AppFontSizes.xs,
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }

  static Map<String, int> _statsOf(Classes c) => {
    'strength': c.strength,
    'dexterity': c.dexterity,
    'intelligence': c.intelligence,
    'wisdom': c.wisdom,
    'charisma': c.charisma,
    'constitution': c.constitution,
    'luck': c.luck,
  };

  // ---------------------------------------------------------------- step 2
  Widget _originStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideIn(
          child: SectionHeader(
            icon: Icons.auto_stories_outlined,
            title: 'Where do you come from?',
            subtitle: 'Your origin grants bonus stats. Optional.',
          ),
        ),
        const SizedBox(height: AppPadding.md),
        FadeSlideIn(
          child: _OriginCard(
            icon: '🧭',
            name: 'Wanderer',
            description: 'No origin, no bonus. A blank page.',
            bonuses: const {},
            selected: _selectedBackground == null,
            onTap: () => setState(() => _selectedBackground = null),
          ),
        ),
        for (var i = 0; i < backgroundsList.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: 40 * (i + 1)),
            child: _OriginCard(
              icon: backgroundsList[i].icon,
              name: backgroundsList[i].name,
              description: backgroundsList[i].description,
              flavor: backgroundsList[i].flavorText,
              bonuses: backgroundsList[i].statBonus,
              selected: _selectedBackground?.id == backgroundsList[i].id,
              onTap:
                  () =>
                      setState(() => _selectedBackground = backgroundsList[i]),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- step 3
  Widget _avatarStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideIn(
          child: SectionHeader(
            icon: Icons.face_retouching_natural,
            title: 'Pick your portrait',
            subtitle: 'How the world will see you.',
          ),
        ),
        const SizedBox(height: AppPadding.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: AppPadding.sm,
            crossAxisSpacing: AppPadding.sm,
          ),
          itemCount: _heroImages.length,
          itemBuilder: (context, index) {
            final image = _heroImages[index];
            final isSelected = _selectedImage == image;
            return FadeSlideIn(
              delay: Duration(milliseconds: 25 * index),
              child: GestureDetector(
                onTap: () => setState(() => _selectedImage = image),
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 1,
                  duration: AppDurations.short,
                  child: AnimatedContainer(
                    duration: AppDurations.short,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.accentGold
                                : AppColors.borderLight,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: AppColors.accentGold.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 14,
                                ),
                              ]
                              : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md - 2),
                      child: HeroAvatar(
                        imageUrl: image,
                        fallbackLabel: '${index + 1}',
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- step 4
  Widget _summonStep() {
    final hero = _previewHero;
    if (hero == null) {
      return const GlassPanel(
        child: Text('Go back and finish the earlier steps first.'),
      );
    }
    final background = hero.background;

    return Column(
      children: [
        FadeSlideIn(
          child: GlassPanel(
            glowColor: AppColors.accentGold,
            borderColor: AppColors.accentGold,
            child: Column(
              children: [
                PulseGlow(
                  child: ClipOval(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: HeroAvatar(imageUrl: hero.imageUrl),
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.lg),
                Text(
                  hero.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '"${hero.motto}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppPadding.md),
                Wrap(
                  spacing: AppPadding.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        '${classEmoji(hero.classes.className)} '
                        '${hero.classes.className}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        background == null
                            ? '🧭 Wanderer'
                            : '${background.icon} ${background.name}',
                      ),
                    ),
                    const Chip(label: Text('Lv. 1')),
                  ],
                ),
                const SizedBox(height: AppPadding.lg),
                _StatBars(
                  values: {
                    for (final stat in heroStatNames)
                      stat: hero.statValue(stat),
                  },
                  bonuses: background?.statBonus ?? const {},
                ),
                const SizedBox(height: AppPadding.md),
                Text(
                  'HP ${hero.health} · MP ${hero.mana} · Stamina ${hero.stamina}',
                  style: const TextStyle(color: AppColors.accentGreen),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppPadding.lg),
        const FadeSlideIn(
          delay: Duration(milliseconds: 200),
          child: Text(
            'Ready? Your quests await.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Step indicator + title. Completed steps can be tapped to go back.
class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.isOnboarding,
    required this.onStepTap,
  });

  final int step;
  final bool isOnboarding;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.xl,
        AppPadding.md,
        AppPadding.xl,
        AppPadding.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isOnboarding)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Cancel',
                ),
              Expanded(
                child: Text(
                  isOnboarding ? 'Welcome, adventurer' : 'Create a new hero',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(
                'Step ${step + 1} of ${HeroCreationPage.stepCount}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.md),
          Row(
            children: [
              for (var i = 0; i < HeroCreationPage.stepCount; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onStepTap(i),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: AppDurations.medium,
                          height: 6,
                          decoration: BoxDecoration(
                            color:
                                i <= step
                                    ? AppColors.accentGold
                                    : Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow:
                                i == step
                                    ? [
                                      BoxShadow(
                                        color: AppColors.accentGold.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ]
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          HeroCreationPage.stepTitles[i],
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                i == step
                                    ? AppColors.accentGold
                                    : AppColors.textSecondary,
                            fontWeight:
                                i == step ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < HeroCreationPage.stepCount - 1)
                  const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.canContinue,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool canContinue;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = step == HeroCreationPage.stepCount - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.xl,
        AppPadding.md,
        AppPadding.xl,
        AppPadding.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            const SizedBox(width: AppPadding.md),
          ],
          Expanded(
            child: QuestButton(
              label: isLast ? 'Begin Adventure' : 'Next',
              icon: isLast ? Icons.auto_awesome : Icons.arrow_forward,
              colors:
                  isLast
                      ? const [Color(0xFFB8860B), AppColors.accentGold]
                      : const [AppColors.accentPurple, Color(0xFF9C27B0)],
              glow: isLast ? AppColors.accentGold : AppColors.shadowPurple,
              onPressed: canContinue ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classes,
    required this.selected,
    required this.onTap,
  });

  final Classes classes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1,
        duration: AppDurations.short,
        child: AnimatedContainer(
          duration: AppDurations.short,
          padding: const EdgeInsets.all(AppPadding.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentPurple : AppColors.bgDark,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.accentGold : AppColors.borderLight,
              width: selected ? 2 : 1,
            ),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: AppColors.shadowPurple.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                classEmoji(classes.className),
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(height: AppPadding.xs),
              Text(
                classes.className,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppFontSizes.sm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OriginCard extends StatelessWidget {
  const _OriginCard({
    required this.icon,
    required this.name,
    required this.description,
    required this.bonuses,
    required this.selected,
    required this.onTap,
    this.flavor,
  });

  final String icon;
  final String name;
  final String description;
  final String? flavor;
  final Map<String, int> bonuses;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.short,
        margin: const EdgeInsets.only(bottom: AppPadding.sm),
        padding: const EdgeInsets.all(AppPadding.md),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.accentPurple.withValues(alpha: 0.6)
                  : AppColors.bgDark,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.accentGold : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppPadding.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.xs,
                    ),
                  ),
                  if (selected && flavor != null) ...[
                    const SizedBox(height: AppPadding.xs),
                    Text(
                      flavor!,
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: AppFontSizes.xs,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppPadding.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in bonuses.entries)
                  Text(
                    '+${entry.value} ${entry.key}',
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: AppFontSizes.xs,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Seven animated stat bars; [bonuses] are shown as "+n" next to the value.
class _StatBars extends StatelessWidget {
  const _StatBars({required this.values, this.bonuses = const {}});

  final Map<String, int> values;
  final Map<String, int> bonuses;

  static const int _maxStat = 12;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in values.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    _capitalise(entry.key),
                    style: const TextStyle(
                      fontSize: AppFontSizes.xs,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedBar(
                    fraction: entry.value / _maxStat,
                    height: 8,
                    colors: AppColors.statGradient,
                  ),
                ),
                const SizedBox(width: AppPadding.sm),
                SizedBox(
                  width: 40,
                  child: Text(
                    bonuses.containsKey(entry.key)
                        ? '${entry.value} (+${bonuses[entry.key]})'
                        : '${entry.value}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFontSizes.xs,
                      fontWeight: FontWeight.bold,
                      color:
                          bonuses.containsKey(entry.key)
                              ? AppColors.accentGreen
                              : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Hero portrait with a graceful fallback when the image asset is missing.
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({super.key, required this.imageUrl, this.fallbackLabel});

  final String imageUrl;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder:
          (_, _, _) => Container(
            color: AppColors.primaryDark,
            alignment: Alignment.center,
            child: Text(
              fallbackLabel ?? '🧝',
              style: const TextStyle(fontSize: 28, color: Colors.white70),
            ),
          ),
    );
  }
}

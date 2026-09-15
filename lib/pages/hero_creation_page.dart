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
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/celebration_overlay.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Five-step summoning rite: identity → class → origin → portrait → summon.
/// Shown as onboarding when no hero exists ([isOnboarding] = true, nothing
/// to pop) and from the Guide tab to replace an existing hero.
class HeroCreationPage extends StatefulWidget {
  const HeroCreationPage({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  static const int stepCount = 5;
  static const List<String> stepTitles = [
    'Identity',
    'Class',
    'Origin',
    'Portrait',
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
        asset: Art.createHeroBackground,
        darken: 0.55,
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
    const padding = EdgeInsets.fromLTRB(18, 6, 18, 20);
    final body = switch (_step) {
      0 => _identityStep(),
      1 => _classStep(),
      2 => _originStep(),
      3 => _portraitStep(),
      _ => _summonStep(),
    };
    return SingleChildScrollView(padding: padding, child: body);
  }

  // ---------------------------------------------------------------- step 0
  Widget _identityStep() {
    return Column(
      children: [
        FadeSlideIn(child: _identityPanel()),
        const SizedBox(height: 28),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Column(
            children: [
              Opacity(
                opacity: 0.9,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.magenta.withValues(alpha: 0.35),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      Art.appIcon,
                      errorBuilder:
                          (_, _, _) =>
                              const GemRing(icon: Icons.key_rounded, size: 110),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The key opens a door only for those who know their own name.',
                textAlign: TextAlign.center,
                style: AppFonts.body(
                  size: 13,
                  color: AppColors.inkMuted,
                  style: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _identityPanel() {
    return ArcanePanel(
      child: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.badge_outlined,
              title: 'Who are you?',
              subtitle: 'Every legend begins with a name.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 24,
              style: AppFonts.body(size: 16, weight: FontWeight.w600),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _mottoController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              style: AppFonts.body(size: 15, style: FontStyle.italic),
              decoration: const InputDecoration(
                labelText: 'Motto or tagline',
                prefixIcon: Icon(Icons.format_quote_rounded),
                counterText: '',
              ),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Please enter a motto'
                          : null,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _randomise,
                icon: const Icon(Icons.casino_outlined, size: 18),
                label: const Text('ROLL A RANDOM NAME'),
              ),
            ),
          ],
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
            subtitle: 'Your class sets your starting attributes.',
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: classesList.length,
          itemBuilder: (context, index) {
            final classes = classesList[index];
            return FadeSlideIn(
              delay: Duration(milliseconds: 40 * index),
              child: _ClassGlyph(
                classes: classes,
                selected: selected == classes,
                onTap: () => setState(() => _selectedClass = classes),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          child:
              selected == null
                  ? const SizedBox.shrink()
                  : ArcanePanel(
                    key: ValueKey(selected.className),
                    glow: AppColors.amethystBright,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.className,
                          style: AppFonts.heading(size: 18),
                        ),
                        Text(
                          selected.description,
                          style: AppFonts.body(
                            size: 13,
                            color: AppColors.inkMuted,
                            style: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: StatRadar(
                            values: _statsOf(selected),
                            size: 190,
                          ),
                        ),
                        Center(
                          child: Text(
                            'HP ${selected.health} · MP ${selected.mana} · STA ${selected.stamina}',
                            style: AppFonts.label(
                              size: 10,
                              color: AppColors.teal,
                            ),
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
            subtitle: 'Your origin grants bonus attributes. Optional.',
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          child: _OriginCard(
            id: null,
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
              id: backgroundsList[i].id,
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
  Widget _portraitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideIn(
          child: SectionHeader(
            icon: Icons.portrait_rounded,
            title: 'Choose your portrait',
            subtitle: 'How the world will remember you.',
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
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
                  scale: isSelected ? 1.06 : 1,
                  duration: AppDurations.short,
                  child: AnimatedOpacity(
                    opacity: _selectedImage == null || isSelected ? 1 : 0.55,
                    duration: AppDurations.short,
                    child: FramedPortrait(
                      imageUrl: image,
                      size: 100,
                      glow: isSelected ? AppColors.teal : null,
                      fallbackLabel: '${index + 1}',
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
      return ArcanePanel(
        child: Text(
          'Go back and finish the earlier steps first.',
          style: AppFonts.body(),
        ),
      );
    }
    final background = hero.background;

    return Column(
      children: [
        FadeSlideIn(
          child: ArcanePanel(
            glow: AppColors.gold,
            accent: AppColors.gold,
            child: Column(
              children: [
                PulseGlow(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                  child: FramedPortrait(
                    imageUrl: hero.imageUrl,
                    size: 140,
                    glow: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  hero.name,
                  style: AppFonts.heading(size: 24),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '"${hero.motto}"',
                  textAlign: TextAlign.center,
                  style: AppFonts.body(
                    size: 14,
                    color: AppColors.inkMuted,
                    style: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    RuneTag(
                      text: hero.classes.className.toUpperCase(),
                      color: AppColors.teal,
                      filled: true,
                    ),
                    RuneTag(
                      text: (background?.name ?? 'Wanderer').toUpperCase(),
                      color: AppColors.amethystBright,
                      icon: originIcon(background?.id),
                      filled: true,
                    ),
                    const RuneTag(
                      text: 'LEVEL 1',
                      color: AppColors.gold,
                      filled: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StatRadar(
                  values: {
                    for (final stat in heroStatNames)
                      stat: hero.statValue(stat),
                  },
                  compare: _statsOf(hero.classes),
                  size: 220,
                ),
                Text(
                  'HP ${hero.health} · MP ${hero.mana} · STA ${hero.stamina}',
                  style: AppFonts.label(size: 10, color: AppColors.teal),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Text(
            'The circle is drawn. Speak the word and begin.',
            style: AppFonts.body(
              size: 13,
              color: AppColors.inkMuted,
              style: FontStyle.italic,
            ),
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
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isOnboarding)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.bronzeLight,
                  ),
                  tooltip: 'Cancel',
                ),
              Expanded(
                child: Text(
                  isOnboarding ? 'Welcome, adventurer' : 'Create a new hero',
                  style: AppFonts.heading(size: 20),
                ),
              ),
              Text(
                'STEP ${step + 1} OF ${HeroCreationPage.stepCount}',
                style: AppFonts.label(size: 9, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                          height: 4,
                          decoration: BoxDecoration(
                            gradient:
                                i <= step
                                    ? const LinearGradient(
                                      colors: [
                                        AppColors.bronzeLight,
                                        AppColors.gold,
                                      ],
                                    )
                                    : null,
                            color:
                                i <= step
                                    ? null
                                    : AppColors.bronze.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow:
                                i == step
                                    ? [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(
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
                          HeroCreationPage.stepTitles[i].toUpperCase(),
                          style: AppFonts.label(
                            size: 7.5,
                            color:
                                i == step ? AppColors.gold : AppColors.inkMuted,
                            weight:
                                i == step ? FontWeight.w700 : FontWeight.w500,
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
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.obsidian],
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('BACK'),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: QuestButton(
              label: isLast ? 'Begin Adventure' : 'Next',
              icon:
                  isLast
                      ? Icons.auto_awesome_rounded
                      : Icons.arrow_forward_rounded,
              style: isLast ? QuestButtonStyle.gold : QuestButtonStyle.amethyst,
              onPressed: canContinue ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Class glyph tile from the class artwork with the name beneath.
class _ClassGlyph extends StatelessWidget {
  const _ClassGlyph({
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1,
        duration: AppDurations.short,
        child: Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: AppDurations.short,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      selected
                          ? [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.6),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                          : null,
                  border: Border.all(
                    color: selected ? AppColors.teal : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    classes.classImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, _, _) =>
                            const GemRing(icon: Icons.shield_rounded, size: 60),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              classes.className,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.heading(
                size: 11,
                color: selected ? AppColors.gold : AppColors.ink,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OriginCard extends StatelessWidget {
  const _OriginCard({
    required this.id,
    required this.name,
    required this.description,
    required this.bonuses,
    required this.selected,
    required this.onTap,
    this.flavor,
  });

  final String? id;
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
      behavior: HitTestBehavior.opaque,
      child: ArcanePanel(
        ornate: false,
        radius: 10,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        accent: selected ? AppColors.teal : null,
        glow: selected ? AppColors.teal : null,
        fillOpacity: selected ? 0.92 : 0.7,
        child: Row(
          children: [
            GemRing(
              icon: originIcon(id),
              color: AppColors.amethyst,
              size: 44,
              selected: selected,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppFonts.heading(size: 13, letterSpacing: 0.8),
                  ),
                  Text(
                    description,
                    style: AppFonts.body(size: 12, color: AppColors.inkMuted),
                  ),
                  if (selected && flavor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      flavor!,
                      style: AppFonts.body(
                        size: 12,
                        color: AppColors.gold,
                        style: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in bonuses.entries)
                  Text(
                    '+${entry.value} ${statAbbreviation(entry.key)}',
                    style: AppFonts.label(size: 9, color: AppColors.teal),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

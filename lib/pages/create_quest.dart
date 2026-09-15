import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/theme/app_theme.dart';
import 'package:quest_key/theme/iconography.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// Forge a quest: create or edit a quest with a live preview of its tile.
class CreateQuestPage extends StatefulWidget {
  const CreateQuestPage({super.key});

  @override
  State<CreateQuestPage> createState() => _CreateQuestPageState();
}

class _QuestTemplate {
  const _QuestTemplate(this.title, this.description, this.category);

  final String title;
  final String description;
  final QuestCategory category;
}

class _CreateQuestPageState extends State<CreateQuestPage> {
  static const List<_QuestTemplate> _templates = [
    _QuestTemplate(
      'Drink water',
      'Drink 8 glasses of water today',
      QuestCategory.health,
    ),
    _QuestTemplate(
      'Exercise',
      'Move your body for at least 20 minutes',
      QuestCategory.health,
    ),
    _QuestTemplate('Read', 'Read 10 pages of a book', QuestCategory.study),
    _QuestTemplate(
      'Tidy up',
      'Clean one room or your workspace',
      QuestCategory.home,
    ),
    _QuestTemplate(
      'Reach out',
      'Check in with a friend or family member',
      QuestCategory.social,
    ),
    _QuestTemplate(
      'Unwind',
      'Ten minutes of stretching or meditation',
      QuestCategory.health,
    ),
    _QuestTemplate(
      'Create',
      'Spend 30 minutes on a creative project',
      QuestCategory.creative,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _dueDateTime;
  Quest? _editingQuest;
  int _difficulty = minDifficulty;
  bool _remindMe = false;
  bool _initialized = false;
  bool _submitting = false;
  QuestCategory _category = QuestCategory.other;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refresh);
    _descriptionController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => _editingQuest != null;

  @override
  Widget build(BuildContext context) {
    final selectedQuest = context.watch<QuestListProvider>().selectedQuest;

    if (selectedQuest != null && !_initialized) {
      _editingQuest = selectedQuest;
      _titleController.text = selectedQuest.title;
      _descriptionController.text = selectedQuest.description;
      _dueDateTime = selectedQuest.dueDate;
      _difficulty = selectedQuest.difficulty;
      _remindMe = selectedQuest.remindMe;
      _category = selectedQuest.category;
      _initialized = true;
    }

    return Scaffold(
      body: PageBackground(
        asset: Art.createBackground,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
              children: [
                FadeSlideIn(child: _header()),
                const SizedBox(height: AppPadding.md),
                if (!_isEditing) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: _quickStart(),
                  ),
                  const SizedBox(height: AppPadding.md),
                ],
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _detailsPanel(),
                ),
                const SizedBox(height: AppPadding.md),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: _categoryPanel(),
                ),
                const SizedBox(height: AppPadding.md),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: _difficultyPanel(),
                ),
                const SizedBox(height: AppPadding.md),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: _schedulePanel(),
                ),
                const SizedBox(height: AppPadding.md),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 360),
                  child: _previewPanel(),
                ),
                const SizedBox(height: AppPadding.xl),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 400),
                  child: QuestButton(
                    label: _isEditing ? 'Save Changes' : 'Forge Quest',
                    icon:
                        _isEditing
                            ? Icons.save_outlined
                            : Icons.auto_fix_high_rounded,
                    style: QuestButtonStyle.gold,
                    onPressed: _submitting ? null : _submitForm,
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: AppPadding.sm),
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('Cancel editing'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const PortholeBadge(asset: Art.create, size: 64),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Quest' : 'Forge a Quest',
                style: AppFonts.heading(size: 22),
              ),
              Text(
                _isEditing
                    ? 'Adjust the details, then save.'
                    : 'Turn a task into an adventure.',
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

  Widget _quickStart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text('QUICK START', style: AppFonts.label(size: 10)),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final template = _templates[index];
              return _TemplateChip(
                template: template,
                onTap: () => _applyTemplate(template),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _detailsPanel() {
    return ArcanePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.history_edu_rounded,
            title: 'The Quest',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            style: AppFonts.body(size: 16, weight: FontWeight.w600),
            decoration: const InputDecoration(
              labelText: 'Quest Name',
              hintText: 'e.g. Finish the report',
              prefixIcon: Icon(Icons.flag_outlined),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Every good quest needs a name!';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            minLines: 2,
            style: AppFonts.body(size: 15),
            decoration: const InputDecoration(
              labelText: 'Quest Description',
              hintText: 'What does "done" look like?',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Write an objective to complete the quest!';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _categoryPanel() {
    return ArcanePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.category_outlined,
            title: 'Category',
            trailing: RuneTag(
              text: _category.label.toUpperCase(),
              color: categoryColor(_category),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 10,
            children: [
              for (final category in QuestCategory.values)
                _CategoryPick(
                  category: category,
                  selected: _category == category,
                  onTap: () => setState(() => _category = category),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _difficultyPanel() {
    return ArcanePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.local_fire_department_outlined,
            title: 'Difficulty',
            trailing: AnimatedSwitcher(
              duration: AppDurations.short,
              child: Text(
                '${difficultyLabel(_difficulty)} · +${xpForDifficulty(_difficulty)} XP',
                key: ValueKey<int>(_difficulty),
                style: AppFonts.label(size: 11, color: AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var rune = minDifficulty; rune <= maxDifficulty; rune++)
                _DifficultyRune(
                  key: ValueKey('difficulty_star_$rune'),
                  lit: rune <= _difficulty,
                  label: difficultyLabel(rune),
                  onTap: () => setState(() => _difficulty = rune),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Harder quests reward more experience.',
            style: AppFonts.body(
              size: 12,
              color: AppColors.inkMuted,
              style: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _schedulePanel() {
    final due = _dueDateTime;
    return ArcanePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(icon: Icons.event_outlined, title: 'Due'),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: AppDurations.short,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.obsidian.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: due == null ? AppColors.bronze : AppColors.gold,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: due == null ? AppColors.bronzeLight : AppColors.gold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      due == null
                          ? 'Pick date & time'
                          : DateFormat('EEE, MMM d · h:mm a').format(due),
                      style: AppFonts.body(
                        size: 15,
                        weight: due == null ? FontWeight.w400 : FontWeight.w600,
                        color: due == null ? AppColors.inkMuted : AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.bronzeLight,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ShortcutChip(
                label: 'Today 6 pm',
                onTap: () => _setDue(_todayAt(18)),
              ),
              _ShortcutChip(
                label: 'Tomorrow 9 am',
                onTap: () => _setDue(_todayAt(9).add(const Duration(days: 1))),
              ),
              _ShortcutChip(
                label: 'In a week',
                onTap: () => _setDue(_todayAt(18).add(const Duration(days: 7))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _remindMe,
            onChanged: _onRemindMeChanged,
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.bronzeLight,
            ),
            title: Text('Remind me when due', style: AppFonts.body(size: 15)),
            subtitle: Text(
              'Thirty minutes before the due time',
              style: AppFonts.body(
                size: 12,
                color: AppColors.inkMuted,
                style: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewPanel() {
    final title =
        _titleController.text.trim().isEmpty
            ? 'Your quest title'
            : _titleController.text.trim();
    final description =
        _descriptionController.text.trim().isEmpty
            ? 'Your objective appears here'
            : _descriptionController.text.trim();
    final due = _dueDateTime;
    final color = categoryColor(_category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text('PREVIEW', style: AppFonts.label(size: 10)),
        ),
        ArcanePanel(
          ornate: false,
          radius: 10,
          accent: color,
          glow: color,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              GemRing(icon: categoryIcon(_category), color: color, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(size: 16, weight: FontWeight.w600),
                    ),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(
                        size: 13,
                        color: AppColors.inkMuted,
                        style: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        RuneTag(
                          text:
                              due == null
                                  ? 'NO DUE DATE'
                                  : Quest.formatTimeRemaining(
                                    due.difference(DateTime.now()),
                                  ).toUpperCase(),
                          color: AppColors.bronzeLight,
                          icon: Icons.hourglass_bottom_rounded,
                        ),
                        RuneTag(
                          text:
                              '${difficultyLabel(_difficulty).toUpperCase()} · ${xpForDifficulty(_difficulty)} XP',
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- actions

  void _applyTemplate(_QuestTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _category = template.category;
    });
  }

  static DateTime _todayAt(int hour) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour);
  }

  void _setDue(DateTime when) => setState(() => _dueDateTime = when);

  void _cancelEdit() {
    context.read<QuestListProvider>().setSelectedQuest(null);
    _resetForm();
    context.read<AppState>().setIndex(1);
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _editingQuest = null;
      _initialized = false;
      _dueDateTime = null;
      _difficulty = minDifficulty;
      _remindMe = false;
      _category = QuestCategory.other;
      _submitting = false;
    });
  }

  Future<void> _submitForm() async {
    final messenger = ScaffoldMessenger.of(context);
    final dueDateTime = _dueDateTime;
    final valid = _formKey.currentState!.validate();
    if (dueDateTime == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pick a due date and time first.')),
      );
    }
    if (!valid || dueDateTime == null) return;

    setState(() => _submitting = true);
    final questProvider = context.read<QuestListProvider>();
    final appState = context.read<AppState>();

    final quest = Quest(
      id: _editingQuest?.id ?? questProvider.nextQuestId(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _editingQuest?.status ?? QuestStatus.inProgress,
      difficulty: _difficulty,
      dueDate: dueDateTime,
      questImageUrl: _editingQuest?.questImageUrl ?? defaultQuestImage,
      remindMe: _remindMe,
      category: _category,
      completedAt: _editingQuest?.completedAt,
    );

    final wasEditing = _isEditing;
    final outcome = await questProvider.saveQuest(quest);
    questProvider.setSelectedQuest(null);

    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (outcome) {
          QuestSaveOutcome.reminderInPast =>
            'Quest saved. The due time is less than 30 minutes away, so no reminder was scheduled.',
          QuestSaveOutcome.reminderScheduled =>
            wasEditing
                ? 'Quest updated. Reminder set.'
                : '"${quest.title}" forged. Reminder set.',
          QuestSaveOutcome.saved =>
            wasEditing ? 'Quest updated.' : '"${quest.title}" forged.',
        }),
      ),
    );

    if (!mounted) return;
    _resetForm();
    appState.setIndex(1);
  }

  /// Asks for notification permission the first time the switch is turned
  /// on. If the user denies it, the switch stays off and we explain why.
  Future<void> _onRemindMeChanged(bool value) async {
    if (!value) {
      setState(() => _remindMe = false);
      return;
    }

    final scheduler = context.read<QuestListProvider>().scheduler;
    final messenger = ScaffoldMessenger.of(context);
    final granted = await scheduler.requestPermission();
    if (!mounted) return;

    setState(() => _remindMe = granted);
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are turned off for Quest Key, so reminders can\'t be '
            'scheduled. Enable them in system settings to use reminders.',
          ),
        ),
      );
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _dueDateTime ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDateTime ?? now),
    );
    if (pickedTime == null) return;

    _setDue(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.template, required this.onTap});

  final _QuestTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(template.category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
          decoration: BoxDecoration(
            color: AppColors.obsidian.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.bronze),
          ),
          child: Row(
            children: [
              GemRing(
                icon: categoryIcon(template.category),
                color: color,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                template.title,
                style: AppFonts.body(size: 14, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.obsidian.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.bronze),
          ),
          child: Text(
            label,
            style: AppFonts.body(size: 13, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

class _CategoryPick extends StatelessWidget {
  const _CategoryPick({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final QuestCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1,
              duration: AppDurations.short,
              child: GemRing(
                icon: categoryIcon(category),
                color: categoryColor(category),
                size: 44,
                selected: selected,
                dimmed: !selected,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.label,
              style: AppFonts.label(
                size: 8,
                color: selected ? AppColors.gold : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of five diamond runes that light up with difficulty.
class _DifficultyRune extends StatelessWidget {
  const _DifficultyRune({
    super.key,
    required this.lit,
    required this.label,
    required this.onTap,
  });

  final bool lit;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedScale(
              scale: lit ? 1.15 : 1,
              duration: AppDurations.short,
              child: Transform.rotate(
                angle: 0.785398,
                child: AnimatedContainer(
                  duration: AppDurations.short,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient:
                        lit
                            ? const LinearGradient(
                              colors: [
                                Color(0xFFFFF0B8),
                                AppColors.gold,
                                Color(0xFF9A7226),
                              ],
                            )
                            : null,
                    color:
                        lit ? null : AppColors.obsidian.withValues(alpha: 0.6),
                    border: Border.all(
                      color: lit ? AppColors.gold : AppColors.bronze,
                      width: 1.4,
                    ),
                    boxShadow:
                        lit
                            ? [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ]
                            : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:quest_key/widgets/common/ui_kit.dart';

/// "Forge a quest": create or edit a quest with a live preview.
class CreateQuestPage extends StatefulWidget {
  const CreateQuestPage({super.key});

  @override
  State<CreateQuestPage> createState() => _CreateQuestPageState();
}

class _QuestTemplate {
  const _QuestTemplate(this.emoji, this.title, this.description, this.category);

  final String emoji;
  final String title;
  final String description;
  final QuestCategory category;

  String get chipLabel => '$emoji $title';
}

class _CreateQuestPageState extends State<CreateQuestPage> {
  /// One-tap starting points for common everyday quests.
  static const List<_QuestTemplate> _templates = [
    _QuestTemplate(
      '💧',
      'Drink water',
      'Drink 8 glasses of water today',
      QuestCategory.health,
    ),
    _QuestTemplate(
      '🏃',
      'Exercise',
      'Move your body for at least 20 minutes',
      QuestCategory.health,
    ),
    _QuestTemplate(
      '📖',
      'Read',
      'Read 10 pages of a book',
      QuestCategory.study,
    ),
    _QuestTemplate(
      '🧹',
      'Tidy up',
      'Clean one room or your workspace',
      QuestCategory.home,
    ),
    _QuestTemplate(
      '📞',
      'Reach out',
      'Check in with a friend or family member',
      QuestCategory.social,
    ),
    _QuestTemplate(
      '🧘',
      'Unwind',
      'Ten minutes of stretching or meditation',
      QuestCategory.health,
    ),
    _QuestTemplate(
      '✍️',
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
        asset: 'assets/images/app_assets/create_bkg.png',
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppPadding.xl,
                AppPadding.lg,
                AppPadding.xl,
                120,
              ),
              children: [
                FadeSlideIn(child: _header()),
                const SizedBox(height: AppPadding.lg),
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
                        _isEditing ? Icons.save_outlined : Icons.auto_fix_high,
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
        Container(
          padding: const EdgeInsets.all(AppPadding.md),
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Icon(
            _isEditing ? Icons.edit_note : Icons.auto_fix_high,
            color: AppColors.accentGold,
            size: AppIconSizes.lg,
          ),
        ),
        const SizedBox(width: AppPadding.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Quest' : 'Forge a Quest',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                _isEditing
                    ? 'Adjust the details, then save.'
                    : 'Turn a task into an adventure.',
                style: const TextStyle(color: AppColors.textSecondary),
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
        const Padding(
          padding: EdgeInsets.only(left: AppPadding.xs, bottom: AppPadding.xs),
          child: Text(
            'QUICK START',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSizes.xs,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppPadding.sm),
            itemBuilder: (context, index) {
              final template = _templates[index];
              return ActionChip(
                label: Text(template.chipLabel),
                onPressed: () => _applyTemplate(template),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _detailsPanel() {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(icon: Icons.edit_outlined, title: 'The quest'),
          const SizedBox(height: AppPadding.md),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
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
          const SizedBox(height: AppPadding.md),
          TextFormField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            minLines: 2,
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
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(icon: Icons.category_outlined, title: 'Category'),
          const SizedBox(height: AppPadding.md),
          Wrap(
            spacing: AppPadding.sm,
            runSpacing: AppPadding.sm,
            children: [
              for (final category in QuestCategory.values)
                ChoiceChip(
                  label: Text('${category.icon} ${category.label}'),
                  selected: _category == category,
                  selectedColor: Color(
                    category.colorValue,
                  ).withValues(alpha: 0.85),
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _difficultyPanel() {
    return GlassPanel(
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
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppPadding.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var star = minDifficulty; star <= maxDifficulty; star++)
                IconButton(
                  key: ValueKey('difficulty_star_$star'),
                  tooltip: difficultyLabel(star),
                  onPressed: () => setState(() => _difficulty = star),
                  iconSize: 36,
                  icon: AnimatedScale(
                    scale: star <= _difficulty ? 1.15 : 1,
                    duration: AppDurations.short,
                    child: Icon(
                      star <= _difficulty
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color:
                          star <= _difficulty
                              ? AppColors.accentGold
                              : Colors.white38,
                    ),
                  ),
                ),
            ],
          ),
          const Text(
            'Harder quests earn more XP.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSizes.xs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _schedulePanel() {
    final due = _dueDateTime;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(icon: Icons.event_outlined, title: 'Due'),
          const SizedBox(height: AppPadding.md),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AnimatedContainer(
              duration: AppDurations.short,
              padding: const EdgeInsets.all(AppPadding.md),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: due == null ? Colors.white24 : AppColors.accentGold,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: due == null ? Colors.white54 : AppColors.accentGold,
                  ),
                  const SizedBox(width: AppPadding.md),
                  Expanded(
                    child: Text(
                      due == null
                          ? 'Pick date & time'
                          : DateFormat('EEE, MMM d · h:mm a').format(due),
                      style: TextStyle(
                        color: due == null ? Colors.white70 : Colors.white,
                        fontWeight:
                            due == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPadding.sm),
          Wrap(
            spacing: AppPadding.sm,
            runSpacing: AppPadding.xs,
            children: [
              ActionChip(
                label: const Text('Today 6 pm'),
                onPressed: () => _setDue(_todayAt(18)),
              ),
              ActionChip(
                label: const Text('Tomorrow 9 am'),
                onPressed:
                    () => _setDue(_todayAt(9).add(const Duration(days: 1))),
              ),
              ActionChip(
                label: const Text('In a week'),
                onPressed:
                    () => _setDue(_todayAt(18).add(const Duration(days: 7))),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.sm),
          SwitchListTile(
            value: _remindMe,
            onChanged: _onRemindMeChanged,
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Remind me when due'),
            subtitle: const Text(
              'Notifies you 30 minutes before the due time',
              style: TextStyle(color: AppColors.textSecondary),
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
    final now = DateTime.now();
    final color = Color(_category.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: AppPadding.xs, bottom: AppPadding.xs),
          child: Text(
            'PREVIEW',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSizes.xs,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AnimatedContainer(
          duration: AppDurations.medium,
          padding: const EdgeInsets.all(AppPadding.md),
          decoration: BoxDecoration(
            color: AppColors.bgPurple,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: color.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: AppImageSizes.questIcon,
                height: AppImageSizes.questIcon,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  _category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: AppPadding.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: AppFontSizes.xs,
                      ),
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Text(
                      '${'★' * _difficulty} +${xpForDifficulty(_difficulty)} XP'
                      '${due == null ? '' : ' · ${Quest.formatTimeRemaining(due.difference(now))}'}',
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: AppFontSizes.xs,
                        fontWeight: FontWeight.w600,
                      ),
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
            'Quest saved. The due time is less than 30 minutes away, so no '
                'reminder was scheduled.',
          QuestSaveOutcome.reminderScheduled =>
            wasEditing
                ? 'Quest updated. Reminder set.'
                : '"${quest.title}" forged! Reminder set.',
          QuestSaveOutcome.saved =>
            wasEditing ? 'Quest updated.' : '"${quest.title}" forged!',
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
            'Notifications are turned off for Quest Key, so reminders can\'t '
            'be scheduled. Enable them in system settings to use reminders.',
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

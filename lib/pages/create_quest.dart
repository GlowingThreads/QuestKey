import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/notification_services.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/state/quest_list_provider.dart';
import 'package:timezone/timezone.dart' as tz;

class CreateQuestPage extends StatefulWidget {
  const CreateQuestPage({super.key});

  @override
  State<CreateQuestPage> createState() => _CreateQuestPageState();
}

class _CreateQuestPageState extends State<CreateQuestPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Quest? _editingQuest;
  double _difficulty = minDifficulty.toDouble();
  bool _remindMe = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedQuest = context.watch<QuestListProvider>().selectedQuest;

    if (selectedQuest != null && !_initialized) {
      _editingQuest = selectedQuest;
      _titleController.text = selectedQuest.title;
      _descriptionController.text = selectedQuest.description;
      _selectedDate = selectedQuest.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(selectedQuest.dueDate);
      _difficulty = selectedQuest.difficulty.toDouble();
      _initialized = true;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_assets/create_bkg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(225, 0, 0, 0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingQuest == null
                              ? 'Create a New Quest'
                              : 'Edit Quest',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _titleController,
                          decoration: _inputDecoration('Quest Name'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Every good quest needs a name!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _inputDecoration(
                            'Quest Description',
                          ).copyWith(errorMaxLines: 3),
                          maxLines: 6,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Write an objective to complete the quest!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _pickDateTime,
                          style: _buttonStyle(),
                          child: const Text('Pick Due Date & Time'),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedDate != null && _selectedTime != null)
                          Text(
                            'Due: ${DateFormat('yyyy-MM-dd – HH:mm').format(_dueDateTime!)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: _buttonStyle(primary: Colors.deepPurple),
                          child: Text(
                            _editingQuest == null
                                ? 'Create Quest'
                                : 'Update Quest',
                          ),
                        ),
                        Slider(
                          value: _difficulty,
                          min: minDifficulty.toDouble(),
                          max: maxDifficulty.toDouble(),
                          divisions: maxDifficulty - minDifficulty,
                          label:
                              'Difficulty: ${_difficulty.round()} '
                              '(${xpForDifficulty(_difficulty.round())} XP)',
                          activeColor: Colors.deepPurple,
                          onChanged: (value) {
                            setState(() {
                              _difficulty = value;
                            });
                          },
                        ),
                        CheckboxListTile(
                          value: _remindMe,
                          onChanged:
                              (value) =>
                                  setState(() => _remindMe = value ?? false),
                          title: const Text(
                            'Remind me when due',
                            style: TextStyle(color: Colors.white),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The chosen due date and time combined, or `null` until both are picked.
  DateTime? get _dueDateTime {
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submitForm() async {
    final dueDateTime = _dueDateTime;
    if (!_formKey.currentState!.validate() || dueDateTime == null) {
      return;
    }

    final questProvider = context.read<QuestListProvider>();
    final appState = context.read<AppState>();

    final quest = Quest(
      id: _editingQuest?.id ?? questProvider.nextQuestId(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _editingQuest?.status ?? QuestStatus.inProgress,
      difficulty: _difficulty.round(),
      dueDate: dueDateTime,
      questImageUrl: _editingQuest?.questImageUrl ?? defaultQuestImage,
    );

    if (_editingQuest != null) {
      await questProvider.updateQuest(quest);
    } else {
      await questProvider.addQuest(quest);
    }
    questProvider.setSelectedQuest(null);

    if (_remindMe) {
      // Convert DateTime to TZDateTime for reminder
      final tzDateTime = tz.TZDateTime.from(
        dueDateTime.subtract(const Duration(minutes: 30)),
        tz.local,
      );

      await NotificationService.scheduleInexactNotification(
        id: quest.id,
        title: 'Quest Reminder',
        body: '“${quest.title}” is due soon. Don’t forget to complete it!',
        scheduledDate: tzDateTime, // Schedule reminder 30 mins before due date
      );
    }

    if (!mounted) return;

    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _editingQuest = null;
      _initialized = false;
      _selectedDate = null;
      _selectedTime = null;
      _difficulty = minDifficulty.toDouble();
      _remindMe = false;
    });

    // Navigate to the quest log tab.
    appState.setIndex(1);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.black45,
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle _buttonStyle({Color primary = Colors.purple}) {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;

    // Pick a date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return; // User canceled the date picker

    // Pick a time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime == null) return; // User canceled the time picker

    // Update the selected date and time
    setState(() {
      _selectedDate = pickedDate;
      _selectedTime = pickedTime;
    });
  }
}

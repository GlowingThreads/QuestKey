import 'package:flutter/material.dart';
import 'package:quest_key/models/quest.dart';
import 'package:quest_key/services/storage.dart';
import 'package:provider/provider.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/services/notification_services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart'; // Import for date formatting

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
  double _difficulty = 1.0;
  bool _remindMe = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final selectedQuest = context.watch<QuestListProvider>().selectedQuest;

    if (selectedQuest != null && !_initialized) {
      _editingQuest = selectedQuest;
      _titleController.text = selectedQuest.title;
      _descriptionController.text = selectedQuest.description;

      if (selectedQuest.startDate.isNotEmpty) {
        _selectedDate = DateTime.tryParse(selectedQuest.startDate);
        if (_selectedDate != null) {
          _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
        }
      }

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
                        const Text(
                          'Create a New Quest',
                          style: TextStyle(
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
                            'Due: ${DateFormat('yyyy-MM-dd – HH:mm').format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute))}',
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
                            _editingQuest == null ? 'Create Quest' : 'Update Quest',
                          ),
                        ),
                        Slider(
                          value: _difficulty,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: 'Difficulty: ${_difficulty.round()}',
                          activeColor: Colors.deepPurple,
                          onChanged: (value) {
                            setState(() {
                              _difficulty = value;
                            });
                          },
                        ),
                        CheckboxListTile(
                          value: _remindMe,
                          onChanged: (value) => setState(() => _remindMe = value!),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }

    final questProvider = context.read<QuestListProvider>();

    String calculateTimeRemaining(DateTime dueDateTime) {
      final now = DateTime.now();
      final diff = dueDateTime.difference(now);
      if (diff.isNegative) return "Overdue";
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      return "$days days, $hours hrs, $minutes mins";
    }

    final dueDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final quest = Quest(
      id:
          _editingQuest?.id ??
          (DateTime.now().millisecondsSinceEpoch % (2 ^ 31)),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      questImageUrl: 'assets/images/app_assets/todo.png',
      status: _editingQuest?.status ?? 'In Progress',
      xpReward: (_editingQuest?.xpReward ?? (50 * _difficulty)).round(),
      startDate: dueDateTime.toString(),
      endDate: dueDateTime.toString(),
      timeRemaining: calculateTimeRemaining(dueDateTime),
    );

    if (_editingQuest != null) {
      questProvider.updateQuest(quest);
    } else {
      questProvider.addQuest(quest);
    }

    await questProvider.saveQuestsToStorage();
    await StorageService.saveQuests(questProvider.quests);
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

    _titleController.clear();
    _descriptionController.clear();
    _editingQuest = null;
    _initialized = false;

    // Navigate to quest log using setIndex method
    context.read<AppState>().setIndex(
      1,
    ); // Index 1 for quest log page (adjust as necessary)
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
    // Pick a date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return; // User canceled the date picker

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

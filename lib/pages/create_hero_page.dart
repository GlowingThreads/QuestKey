import 'package:flutter/material.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/models/classes.dart';
import 'package:quest_key/widgets/image_picker.dart';
import 'package:quest_key/widgets/class_select.dart';
import 'package:quest_key/state/app_state.dart';
import 'package:quest_key/services/storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateHeroPage extends StatefulWidget {
  final void Function(HeroCharacter) onHeroCreated;

  const CreateHeroPage({super.key, required this.onHeroCreated});

  @override
  State<CreateHeroPage> createState() => _CreateHeroPageState();
}

class _CreateHeroPageState extends State<CreateHeroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mottoController = TextEditingController();

  int _stepIndex = 0;

  Classes? _selectedClass;
  String? _selectedImage;

  final List<Classes> _classes = classesList;

  final List<String> _heroImages = List.generate(
    16,
    (index) => 'assets/images/character_images/hero_${index + 1}.png',
  );

  void _nextStep() {
    if (_stepIndex == 0 && !_formKey.currentState!.validate()) return;
    if (_stepIndex == 1 && _selectedClass == null) return;
    if (_stepIndex == 2 && _selectedImage == null) return;

    if (_stepIndex < 3) {
      setState(() => _stepIndex++);
    } else {
      _confirmCreateHero();
    }
  }

  void _backStep() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  Future<void> _confirmCreateHero() async {
    final hero = HeroCharacter.fromClasses(_selectedClass!).copyWith(
      name: _nameController.text,
      motto: _mottoController.text,
      imageUrl: _selectedImage!,
      classes: _selectedClass!,
    );

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Hero'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(_selectedImage!, height: 100),
                Text(
                  hero.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(hero.classes.className),
                const SizedBox(height: 8),
                Text('Motto: ${hero.motto}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Save hero to local storage
                  await StorageService.saveHero(hero);

                  // Set heroExists to true
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('heroExists', true);

                  // Call app state if needed
                  final appState = context.read<AppState>();
                  appState.saveHero(hero);

                  // Continue with original callback
                  widget.onHeroCreated(hero);
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 20, 12, 46),
      appBar: AppBar(
        title: const Text('Create Your Hero'),
        backgroundColor: const Color.fromARGB(255, 29, 17, 62),
      ),
      body: Stepper(
        currentStep: _stepIndex,
        onStepContinue: _nextStep,
        onStepCancel: _backStep,
        type: StepperType.vertical,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: Text(_stepIndex == 3 ? 'Finish' : 'Next'),
                ),
                const SizedBox(width: 12),
                if (_stepIndex > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Hero Info'),
            isActive: _stepIndex >= 0,
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Hero Name'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Please enter a name'
                                : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mottoController,
                    decoration: const InputDecoration(
                      labelText: 'Motto or tagline',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Please enter a motto'
                                : null,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Select Class'),
            isActive: _stepIndex >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        _classes.map((classItem) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: ClassSelect(
                              classData: classItem,
                              selected: _selectedClass == classItem,
                              onTap: () {
                                setState(() {
                                  _selectedClass = classItem;
                                });
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedClass != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _selectedClass!.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Select Avatar'),
            isActive: _stepIndex >= 2,
            content: ImagePicker(
              imagePaths: _heroImages,
              selectedImage: _selectedImage,
              onSelect: (img) => setState(() => _selectedImage = img),
            ),
          ),
          Step(
            title: const Text('Preview'),
            isActive: _stepIndex >= 3,
            content:
                _selectedImage == null || _selectedClass == null
                    ? const Text('Incomplete data')
                    : Column(
                      children: [
                        Image.asset(_selectedImage!, height: 100),
                        const SizedBox(height: 8),
                        Text(
                          _nameController.text,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(_selectedClass!.className),
                        const SizedBox(height: 8),
                        Text(_mottoController.text),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _getStatList().length,
                          itemBuilder: (context, index) {
                            final stat = _getStatList()[index];
                            return _statCard(stat['name'], stat['value']);
                          },
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getStatList() {
    return [
      {'name': 'Strength', 'value': _selectedClass?.strength ?? 0},
      {'name': 'Dexterity', 'value': _selectedClass?.dexterity ?? 0},
      {'name': 'Intelligence', 'value': _selectedClass?.intelligence ?? 0},
      {'name': 'Wisdom', 'value': _selectedClass?.wisdom ?? 0},
      {'name': 'Charisma', 'value': _selectedClass?.charisma ?? 0},
      {'name': 'Constitution', 'value': _selectedClass?.constitution ?? 0},
      {'name': 'Luck', 'value': _selectedClass?.luck ?? 0},
    ];
  }

  Widget _statCard(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.deepPurple,
          child: Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

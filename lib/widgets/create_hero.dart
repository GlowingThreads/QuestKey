// create hero
import 'package:flutter/material.dart';
import 'package:quest_key/models/character.dart';
import 'package:quest_key/models/class_values.dart';
import 'package:quest_key/widgets/image_picker.dart';
import 'package:quest_key/widgets/class_select.dart';
import 'package:quest_key/models/classes.dart';

class CreateHeroWidget extends StatefulWidget {
  final Function(HeroCharacter) onCreate;

  const CreateHeroWidget({super.key, required this.onCreate});

  @override
  State<CreateHeroWidget> createState() => _CreateHeroWidgetState();
}

class _CreateHeroWidgetState extends State<CreateHeroWidget> {
  final _nameController = TextEditingController();
  final _mottoController = TextEditingController();

  Classes? _selectedClass;
  String? _selectedImage;

  final List<Classes> _classes = classesList;

  // list for hero images
  final List<String> _heroImages = List.generate(
    16,
    (index) => 'assets/images/character_images/hero_${index + 1}.png',
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 29, 17, 62),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Your Hero',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // name input
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Hero Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // motto input
              TextField(
                controller: _mottoController,
                decoration: const InputDecoration(
                  labelText: 'Motto or tagline',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Select Class',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text('Swipe and tap to select a class'),
              const SizedBox(height: 12),

              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      _classes.map((classses) {
                        return ClassSelect(
                          classData: classses,
                          selected: _selectedClass == classses,
                          onTap:
                              () => setState(() => _selectedClass = classses),
                        );
                      }).toList(),
                ),
              ),

              if (_selectedClass != null) ...[
                const SizedBox(height: 12),
                Text(
                  _selectedClass!.description,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],

              const SizedBox(height: 24),
              const Text(
                'Choose your Avatar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text('Swipe to select an image'),
              const SizedBox(height: 12),

              ImagePicker(
                imagePaths: _heroImages,
                selectedImage: _selectedImage,
                onSelect: (img) => setState(() => _selectedImage = img),
              ),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _canCreateHero() ? _handleCreateHero : null,
                  child: const Text(
                    'Create Hero',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //validation
  bool _canCreateHero() {
    return _nameController.text.isNotEmpty &&
        _mottoController.text.isNotEmpty &&
        _selectedClass != null &&
        _selectedImage != null;
  }

  //creation of hero
  void _handleCreateHero() {
    final hero = HeroCharacter.fromClasses(_selectedClass!).copyWith(
      name: _nameController.text,
      motto: _mottoController.text,
      imageUrl: _selectedImage!,
      classes: _selectedClass!,
    );
    widget.onCreate(hero);
  }
}

// class selction widget
import 'package:flutter/material.dart';
import 'package:quest_key/models/classes.dart';

// widget to select a class
class ClassSelect extends StatelessWidget {
  final Classes classData;
  final bool selected;
  final VoidCallback onTap;

  const ClassSelect({
    super.key,
    required this.classData,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? Colors.purple[300] : Colors.grey[800],
          border: Border.all(color: selected ? Colors.white : Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(classData.classImageUrl, fit: BoxFit.contain),
            ),
            Text(
              classData.className,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// widget for displaying images for user to pick from
import 'package:flutter/material.dart';

class ImagePicker extends StatelessWidget {
  final List<String> imagePaths;
  final String? selectedImage;
  final void Function(String) onSelect;

  const ImagePicker({
    super.key,
    required this.imagePaths,
    required this.selectedImage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            imagePaths.map((img) {
              final isSelected = selectedImage == img;
              return GestureDetector(
                onTap: () => onSelect(img),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(img, width: 80, height: 80),
                ),
              );
            }).toList(),
      ),
    );
  }
}

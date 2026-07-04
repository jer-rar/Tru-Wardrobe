import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Matches a free-form color string (from AI or a saved item) against the
/// known dropdown options case-insensitively. Returns 'Other' if no match,
/// so the UI can fall back to showing the raw value in a manual field.
String matchColorOption(String? raw) {
  if (raw == null || raw.trim().isEmpty) return kNoneOption;
  final n = raw.trim().toLowerCase();
  for (final option in kColorOptions) {
    if (option == 'Other') continue;
    if (n == option.toLowerCase() || n.contains(option.toLowerCase())) return option;
  }
  return 'Other';
}

/// Best-effort mapping from a plain-English color name (as returned by the
/// AI tagger or typed by the user) to a swatch Color for quick visual scanning.
Color colorNameToSwatch(String? name) {
  if (name == null || name.trim().isEmpty) return Colors.white24;
  final n = name.toLowerCase();
  const map = <String, Color>{
    'black': Colors.black,
    'white': Colors.white,
    'gray': Colors.grey,
    'grey': Colors.grey,
    'red': Colors.red,
    'maroon': Color(0xFF800000),
    'pink': Colors.pink,
    'orange': Colors.orange,
    'brown': Colors.brown,
    'tan': Color(0xFFD2B48C),
    'beige': Color(0xFFF5F5DC),
    'yellow': Colors.yellow,
    'gold': Color(0xFFFFD700),
    'green': Colors.green,
    'olive': Color(0xFF808000),
    'teal': Colors.teal,
    'blue': Colors.blue,
    'navy': Color(0xFF000080),
    'purple': Colors.purple,
    'lavender': Color(0xFFE6E6FA),
    'plum': Color(0xFF8E4585),
    'cream': Color(0xFFFFFDD0),
    'ivory': Color(0xFFFFFFF0),
    'silver': Color(0xFFC0C0C0),
    'denim': Color(0xFF1560BD),
    'khaki': Color(0xFFC3B091),
  };
  for (final entry in map.entries) {
    if (n.contains(entry.key)) return entry.value;
  }
  return Colors.white24;
}

class ColorSwatchDot extends StatelessWidget {
  const ColorSwatchDot({super.key, required this.colorName, this.size = 14});
  final String? colorName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorNameToSwatch(colorName),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }
}

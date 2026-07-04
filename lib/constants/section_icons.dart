import 'package:flutter/material.dart';

/// Curated set of section icons — same single-color accent style throughout,
/// each visually distinct so different closets/dressers/shoe racks/etc. are
/// easy to tell apart at a glance. Trimmed 2026-07-04 after feedback that
/// inventory_2/hiking/local_laundry_service/watch/diamond "don't make sense"
/// at a glance in this context.
const Map<String, IconData> kSectionIconSet = {
  'checkroom': Icons.checkroom,
  'door_sliding': Icons.door_sliding,
  'shelves': Icons.shelves,
  'dry_cleaning': Icons.dry_cleaning,
  'backpack': Icons.backpack,
  'storefront': Icons.storefront,
  'garage': Icons.garage,
};

const String kDefaultSectionIconKey = 'checkroom';

// dry_cleaning's glyph faces one direction by default; mirrored per request
// so it visually distinguishes itself from the main checkroom hanger icon.
const Set<String> kMirroredIconKeys = {'dry_cleaning'};

IconData sectionIconFromKey(String? key) {
  return kSectionIconSet[key] ?? kSectionIconSet[kDefaultSectionIconKey]!;
}

/// Renders a section's icon, applying a horizontal flip for icons whose
/// default orientation should face the other way (see kMirroredIconKeys).
/// Use this everywhere a section icon is shown instead of a raw Icon().
class SectionIcon extends StatelessWidget {
  const SectionIcon({super.key, required this.iconKey, this.size, this.color});
  final String? iconKey;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(sectionIconFromKey(iconKey), size: size, color: color);
    if (kMirroredIconKeys.contains(iconKey)) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(3.14159),
        child: icon,
      );
    }
    return icon;
  }
}

/// Best-effort default suggestion based on the section name, so the picker
/// starts on a sensible icon before the user picks their own.
String suggestSectionIconKey(String name) {
  final n = name.toLowerCase();
  if (n.contains('shoe') || n.contains('rack') || n.contains('shelf') || n.contains('shelves')) {
    return 'shelves';
  }
  if (n.contains('dresser') || n.contains('drawer') || n.contains('storage') || n.contains('garage') || n.contains('bin')) {
    return 'garage';
  }
  if (n.contains('laundry') || n.contains('dry clean') || n.contains('suit')) return 'dry_cleaning';
  if (n.contains('bag') || n.contains('backpack') || n.contains('purse')) return 'backpack';
  if (n.contains('closet') || n.contains('wardrobe') || n.contains('door')) return 'door_sliding';
  return kDefaultSectionIconKey;
}

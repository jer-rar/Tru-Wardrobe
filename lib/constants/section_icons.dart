import 'package:flutter/material.dart';

/// Curated set of section icons — same single-color accent style throughout,
/// each visually distinct so different closets/dressers/shoe racks/etc. are
/// easy to tell apart at a glance.
const Map<String, IconData> kSectionIconSet = {
  'checkroom': Icons.checkroom,
  'door_sliding': Icons.door_sliding,
  'inventory_2': Icons.inventory_2,
  'shelves': Icons.shelves,
  'hiking': Icons.hiking,
  'dry_cleaning': Icons.dry_cleaning,
  'local_laundry_service': Icons.local_laundry_service,
  'backpack': Icons.backpack,
  'watch': Icons.watch,
  'diamond': Icons.diamond,
  'storefront': Icons.storefront,
  'garage': Icons.garage,
};

const String kDefaultSectionIconKey = 'checkroom';

IconData sectionIconFromKey(String? key) {
  return kSectionIconSet[key] ?? kSectionIconSet[kDefaultSectionIconKey]!;
}

/// Best-effort default suggestion based on the section name, so the picker
/// starts on a sensible icon before the user picks their own.
String suggestSectionIconKey(String name) {
  final n = name.toLowerCase();
  if (n.contains('dresser') || n.contains('drawer')) return 'inventory_2';
  if (n.contains('shoe') || n.contains('rack') || n.contains('shelf') || n.contains('shelves')) {
    return 'shelves';
  }
  if (n.contains('boot') || n.contains('hik')) return 'hiking';
  if (n.contains('storage') || n.contains('garage') || n.contains('bin')) return 'garage';
  if (n.contains('laundry')) return 'local_laundry_service';
  if (n.contains('dry clean') || n.contains('suit')) return 'dry_cleaning';
  if (n.contains('bag') || n.contains('backpack') || n.contains('purse')) return 'backpack';
  if (n.contains('watch') || n.contains('accessor')) return 'watch';
  if (n.contains('jewel') || n.contains('ring') || n.contains('necklace')) return 'diamond';
  if (n.contains('closet') || n.contains('wardrobe') || n.contains('door')) return 'door_sliding';
  return kDefaultSectionIconKey;
}

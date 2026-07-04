import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/section_icons.dart';
import '../services/supabase_service.dart';
import '../services/update_service.dart';
import 'section_detail_screen.dart';
import 'search_screen.dart';
import 'outfit_builder_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class ClosetHomeScreen extends StatefulWidget {
  const ClosetHomeScreen({super.key});

  @override
  State<ClosetHomeScreen> createState() => _ClosetHomeScreenState();
}

class _ClosetHomeScreenState extends State<ClosetHomeScreen> {
  List<Map<String, dynamic>> _sections = [];
  Map<String, List<Map<String, dynamic>>> _itemsBySection = {};
  int _favoriteCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sections = await SupabaseService.fetchSections();
    final items = await SupabaseService.fetchItems();
    final grouped = <String, List<Map<String, dynamic>>>{};
    var favoriteCount = 0;
    for (final item in items) {
      final sid = item['section_id']?.toString() ?? '';
      grouped.putIfAbsent(sid, () => []).add(item);
      if (item['favorite'] == true) favoriteCount++;
    }
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _itemsBySection = grouped;
      _favoriteCount = favoriteCount;
      _loading = false;
    });
  }

  Future<void> _createSection() async {
    final ctrl = TextEditingController();
    String selectedIcon = kDefaultSectionIconKey;
    bool autoSuggest = true;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(kCardColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Section', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Closet, Shoe Rack, Dresser',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                  onChanged: (v) {
                    if (autoSuggest) {
                      setStateDialog(() => selectedIcon = suggestSectionIconKey(v));
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Icon', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kSectionIconSet.entries.map((entry) {
                    final selected = entry.key == selectedIcon;
                    return GestureDetector(
                      onTap: () => setStateDialog(() {
                        selectedIcon = entry.key;
                        autoSuggest = false;
                      }),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected ? const Color(kAccentColor).withValues(alpha: 0.2) : const Color(kBgColor),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? const Color(kAccentColor) : Colors.white12,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Icon(entry.value, color: const Color(kAccentColor), size: 22),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, {'name': ctrl.text.trim(), 'icon': selectedIcon}),
              child: const Text('Create', style: TextStyle(color: Color(kAccentColor))),
            ),
          ],
        ),
      ),
    );
    if (result == null || (result['name'] ?? '').isEmpty) return;
    await SupabaseService.createSection(name: result['name']!, icon: result['icon'], sortOrder: _sections.length);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(kBgColor),
      appBar: AppBar(
        title: const Text('Tru Wardrobe', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Outfit Builder',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const OutfitBuilderScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile & Settings',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(kAccentColor)))
          : RefreshIndicator(
              color: const Color(kAccentColor),
              onRefresh: _load,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _sections.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _SectionCard(
                      name: 'Favorites',
                      icon: Icons.favorite,
                      itemCount: _favoriteCount,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        );
                        _load();
                      },
                    );
                  }
                  final section = _sections[index - 1];
                  final items = _itemsBySection[section['id']] ?? [];
                  return _SectionCard(
                    name: section['name']?.toString() ?? '',
                    icon: sectionIconFromKey(section['icon']?.toString()),
                    itemCount: items.length,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SectionDetailScreen(section: section),
                        ),
                      );
                      _load();
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSection,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.name, required this.icon, required this.itemCount, required this.onTap});
  final String name;
  final IconData icon;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(kCardColor),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: const Color(kAccentColor), size: 32),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '$itemCount item${itemCount == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/supabase_service.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Map<String, List<Map<String, dynamic>>> _byCategory = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await SupabaseService.fetchFavorites();
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final cat = item['category']?.toString() ?? 'other';
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    if (!mounted) return;
    setState(() {
      _byCategory = grouped;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = kItemCategories.where((c) => _byCategory.containsKey(c)).toList();

    return Scaffold(
      backgroundColor: const Color(kBgColor),
      appBar: AppBar(title: const Text('Favorites')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(kAccentColor)))
          : categories.isEmpty
              ? const Center(
                  child: Text(
                    'No favorites yet.\nTap the heart on any item to add it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(kAccentColor),
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final items = _byCategory[cat]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, top: 6),
                            child: Text(
                              cat[0].toUpperCase() + cat.substring(1),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final item = items[i];
                              return ItemCard(
                                item: item,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                                  );
                                  _load();
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}

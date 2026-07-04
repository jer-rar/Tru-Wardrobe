import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];
  bool _searched = false;

  Future<void> _search() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final res = await AiService.ask(mode: 'search', prompt: query);
      final ids = List<String>.from(res['item_ids'] ?? []);
      if (ids.isEmpty) {
        setState(() { _results = []; _loading = false; });
        return;
      }
      final data = await SupabaseService.fetchItemsByIds(ids);
      if (!mounted) return;
      setState(() {
        _results = List<Map<String, dynamic>>.from(data['items']);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Search failed: $e'; });
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(kBgColor),
      appBar: AppBar(title: const Text('Search Your Closet')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _queryCtrl,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'e.g. "blue jackets" or "something for a rainy day"',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(kCardColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Color(kAccentColor)),
                    onPressed: _search,
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(kAccentColor)))
                  : !_searched
                      ? const Center(
                          child: Text('Ask about anything in your wardrobe.', style: TextStyle(color: Colors.white38)),
                        )
                      : _results.isEmpty
                          ? const Center(child: Text('No matching items found.', style: TextStyle(color: Colors.white38)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final item = _results[index];
                                return ItemCard(
                                  item: item,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

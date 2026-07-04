import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class OutfitBuilderScreen extends StatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _reasoning;
  List<Map<String, dynamic>> _suggested = [];

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _reasoning = null;
      _suggested = [];
    });
    try {
      final res = await AiService.ask(mode: 'outfit', prompt: prompt);
      final ids = List<String>.from(res['item_ids'] ?? []);
      final reasoning = res['reasoning']?.toString();
      if (ids.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _reasoning = reasoning ?? "Couldn't find a matching outfit — try adding more items first.";
          });
        }
        return;
      }
      final data = await SupabaseService.fetchItemsByIds(ids);
      if (!mounted) return;
      setState(() {
        _suggested = List<Map<String, dynamic>>.from(data['items']);
        _reasoning = reasoning;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Outfit suggestion failed: $e'; });
    }
  }

  Future<void> _saveOutfit() async {
    if (_suggested.isEmpty) return;
    await SupabaseService.saveOutfit(
      itemIds: _suggested.map((e) => e['id'].toString()).toList(),
      aiGenerated: true,
      reasoning: _reasoning,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Outfit saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(kBgColor),
      appBar: AppBar(title: const Text('Outfit Suggestions')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _promptCtrl,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _ask(),
                decoration: InputDecoration(
                  hintText: 'e.g. "casual outfit for a coffee date"',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(kCardColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Color(kAccentColor)),
                    onPressed: _ask,
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            if (_reasoning != null && _reasoning!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_reasoning!, style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(kAccentColor)))
                  : _suggested.isEmpty
                      ? const Center(
                          child: Text('Ask the AI to put together an outfit for you.', style: TextStyle(color: Colors.white38)),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _suggested.length,
                          itemBuilder: (context, index) {
                            final item = _suggested[index];
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
            if (_suggested.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveOutfit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(kAccentColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save This Outfit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

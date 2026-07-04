import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Analyzes a just-uploaded item photo and returns suggested tags:
  /// {name, category, color_primary, color_secondary, pattern, season, formality}
  static Future<Map<String, dynamic>> tagItem(String imageUrl) async {
    final res = await _client.functions.invoke(
      'tag-item',
      body: {'image_url': imageUrl},
    );
    if (res.data == null || res.data['error'] != null) {
      throw Exception(res.data?['error'] ?? 'Tagging failed');
    }
    return Map<String, dynamic>.from(res.data['tags']);
  }

  /// mode: 'search' -> {item_ids: [...]}
  /// mode: 'outfit' -> {item_ids: [...], reasoning: '...'}
  static Future<Map<String, dynamic>> ask({
    required String mode,
    required String prompt,
  }) async {
    final res = await _client.functions.invoke(
      'wardrobe-assistant',
      body: {'mode': mode, 'prompt': prompt},
    );
    if (res.data == null || res.data['error'] != null) {
      throw Exception(res.data?['error'] ?? 'Assistant request failed');
    }
    return Map<String, dynamic>.from(res.data);
  }
}

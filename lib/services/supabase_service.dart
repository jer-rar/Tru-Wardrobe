import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static String? get userId => client.auth.currentUser?.id;

  static Future<List<Map<String, dynamic>>> fetchSections() async {
    final rows = await client
        .from('tw_sections')
        .select()
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<Map<String, dynamic>> createSection({
    required String name,
    String? icon,
    String? color,
    int sortOrder = 0,
  }) async {
    final row = await client
        .from('tw_sections')
        .insert({
          'user_id': userId,
          'name': name,
          'icon': icon,
          'color': color,
          'sort_order': sortOrder,
        })
        .select()
        .single();
    return row;
  }

  static Future<void> deleteSection(String id) async {
    await client.from('tw_sections').delete().eq('id', id);
  }

  static Future<List<Map<String, dynamic>>> fetchItems({String? sectionId}) async {
    var query = client.from('tw_items').select();
    if (sectionId != null) query = query.eq('section_id', sectionId);
    final rows = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final rows = await client
        .from('tw_items')
        .select()
        .eq('favorite', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<Map<String, dynamic>> fetchItemsByIds(List<String> ids) async {
    final rows = await client.from('tw_items').select().inFilter('id', ids);
    return {'items': List<Map<String, dynamic>>.from(rows)};
  }

  // 10 years — the bucket is private, so images are only reachable via a
  // signed URL. Generating one long-lived URL at upload time (rather than a
  // short-lived one refreshed on every screen) keeps every other screen that
  // just reads item['image_url'] unchanged.
  static const _signedUrlExpirySeconds = 60 * 60 * 24 * 365 * 10;

  static Future<String> uploadItemImage(File file) async {
    final ext = file.path.split('.').last;
    final path = '$userId/${const Uuid().v4()}.$ext';
    await client.storage.from(kWardrobeImagesBucket).upload(path, file);
    return client.storage.from(kWardrobeImagesBucket).createSignedUrl(path, _signedUrlExpirySeconds);
  }

  static Future<Map<String, dynamic>> createItem(Map<String, dynamic> fields) async {
    final row = await client
        .from('tw_items')
        .insert({'user_id': userId, ...fields})
        .select()
        .single();
    return row;
  }

  static Future<void> updateItem(String id, Map<String, dynamic> fields) async {
    await client.from('tw_items').update(fields).eq('id', id);
  }

  static Future<void> deleteItem(String id) async {
    await client.from('tw_items').delete().eq('id', id);
  }

  /// Logs a single wear event (with an optional occasion) and bumps the
  /// item's aggregate wear_count/last_worn_at fields to match.
  static Future<void> logWear(
    String itemId,
    int currentWearCount, {
    required DateTime wornAt,
    String? occasion,
    DateTime? currentLastWornAt,
  }) async {
    await client.from('tw_wear_log').insert({
      'user_id': userId,
      'item_id': itemId,
      'worn_at': wornAt.toIso8601String().split('T').first,
      'occasion': (occasion == null || occasion.trim().isEmpty) ? null : occasion.trim(),
    });

    final newLastWorn = (currentLastWornAt == null || wornAt.isAfter(currentLastWornAt))
        ? wornAt
        : currentLastWornAt;

    await client.from('tw_items').update({
      'wear_count': currentWearCount + 1,
      'last_worn_at': newLastWorn.toIso8601String(),
    }).eq('id', itemId);
  }

  static Future<List<Map<String, dynamic>>> fetchWearLog(String itemId) async {
    final rows = await client
        .from('tw_wear_log')
        .select()
        .eq('item_id', itemId)
        .order('worn_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<Map<String, dynamic>> saveOutfit({
    required List<String> itemIds,
    String? name,
    bool aiGenerated = false,
    String? reasoning,
  }) async {
    final row = await client
        .from('tw_outfits')
        .insert({
          'user_id': userId,
          'name': name,
          'item_ids': itemIds,
          'ai_generated': aiGenerated,
          'reasoning': reasoning,
        })
        .select()
        .single();
    return row;
  }

  static Future<List<Map<String, dynamic>>> fetchOutfits() async {
    final rows = await client
        .from('tw_outfits')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}

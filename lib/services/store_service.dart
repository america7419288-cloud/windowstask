import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/server_sticker.dart';
import '../models/server_sticker_pack.dart';
import '../models/store_item.dart';
import '../data/store_catalog.dart';
import '../data/app_stickers.dart';

class StoreService extends ChangeNotifier {
  StoreService._();
  static final instance = StoreService._();

  StoreData? _data;
  bool _isLoading = false;
  String? _error;

  StoreData? get data => _data;
  bool get isLoading => _isLoading;
  bool get hasData => _data != null;
  String? get error => _error;

  // Cache file path
  Future<File> get _cacheFile async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/store_cache.json');
  }

  // ── FETCH STORE ──────────────────────

  Future<void> fetchStore() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      _error = 'Supabase keys not configured';
      await _loadFromCache();
      if (_data == null) _data = _buildFallbackData();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      print('[StoreService] Fetching from: $url/functions/v1/get-store');
      final response = await http.get(
        Uri.parse('$url/functions/v1/get-store'),
        headers: {
          'Authorization': 'Bearer $anonKey',
        },
      ).timeout(const Duration(seconds: 10));

      print('[StoreService] Response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        // The Edge Function returns packs/stickers directly without a 'success' wrapper
        if (json.containsKey('packs') && json.containsKey('stickers')) {
          _data = _parseStoreData(json);
          // Cache to disk for offline
          await _saveCache(response.body);
          print('[StoreService] Successfully loaded ${_data?.packs.length} packs');
        } else {
          print('[StoreService] Server error: invalid response format');
          throw Exception('Invalid store response format');
        }
      } else {
        print('[StoreService] HTTP Error: ${response.body}');
        // Try loading from cache
        await _loadFromCache();
        _error = 'Store update failed. Port: ${response.statusCode}';
      }
    } catch (e) {
      print('[StoreService] Error: $e');
      // Offline — load from cache
      await _loadFromCache();
      if (_data == null) {
        // No cache either — use fallback
        _data = _buildFallbackData();
      }
      _error = 'Offline: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  StoreData _parseStoreData(Map<String, dynamic> json) {
    final packs = (json['packs'] as List)
        .map((j) => ServerStickerPack.fromJson(j as Map<String, dynamic>))
        .toList();
    final stickers = (json['stickers'] as List)
        .map((j) => ServerSticker.fromJson(j as Map<String, dynamic>))
        .toList();
    final config = <String, dynamic>{};
    for (final row in json['config'] as List? ?? []) {
      config[(row as Map)['key'] as String] = row['value'];
    }

    return StoreData(
      packs: packs,
      stickers: stickers,
      config: config,
      fetchedAt: DateTime.now(),
    );
  }

  Future<void> _saveCache(String jsonStr) async {
    try {
      final file = await _cacheFile;
      await file.writeAsString(jsonStr);
    } catch (_) {}
  }

  Future<void> _loadFromCache() async {
    try {
      final file = await _cacheFile;
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      if (json.containsKey('packs')) {
        _data = _parseStoreData(json);
      }
    } catch (_) {}
  }

  // Fallback when offline + no cache
  // Uses whatever is bundled in app
  StoreData _buildFallbackData() {
    // Convert existing StoreCatalog
    // to server format
    final packs = StoreCatalog.items
        .where((i) => i.type == StoreItemType.pack)
        .map((i) => ServerStickerPack(
              id: i.id,
              name: i.name,
              description: i.description,
              xpCost: i.xpCost,
              isActive: true,
              isFeatured: i.isFeatured,
              displayOrder: 0,
              emoji: i.emoji,
              previewUrls: i.previewUrls,
              stickerIds: i.stickerIds,
              tags: [],
            ))
        .toList();

    // Add stickers from AppStickers for the fallback
    final stickers = AppStickers.allStickers.map((s) => ServerSticker(
      id: s.id,
      name: s.name,
      emoji: s.emoji,
      xpCost: 800,
      isActive: true,
      isPremium: false,
      displayOrder: 0,
      packId: s.packId,
    )).toList();

    return StoreData(
      packs: packs,
      stickers: stickers,
      config: {},
      fetchedAt: DateTime(2000), // old date signals fallback
    );
  }

  // ── TGS DOWNLOAD + CACHE ─────────────

  // Map of stickerId → cached bytes
  // Limit to 100 items in memory to prevent bloat
  final Map<String, Uint8List> _tgsCache = {};
  static const int _maxCacheSize = 100;

  Future<Uint8List?> getStickerBytes(String stickerId) async {
    // 1. Memory cache
    if (_tgsCache.containsKey(stickerId)) {
      return _tgsCache[stickerId];
    }

    // 2. Disk cache
    final diskBytes = await _loadTgsFromDisk(stickerId);
    if (diskBytes != null) {
      _tgsCache[stickerId] = diskBytes;
      return diskBytes;
    }

    // 3. Try bundled assets first
    try {
      final data = await rootBundle.load('assets/stickers/individual/$stickerId.tgs');
      final bytes = data.buffer.asUint8List();
      _tgsCache[stickerId] = bytes;
      return bytes;
    } catch (_) {}

    // 4. Download from server
    final sticker = _data?.stickerById(stickerId);
    if (sticker?.animationUrl == null) {
      print('[StoreService] No animation URL for $stickerId');
      return null;
    }

    try {
      print('[StoreService] Downloading sticker $stickerId from ${sticker!.animationUrl}');
      final response = await http.get(Uri.parse(sticker.animationUrl!)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // Simple cache eviction: clear if full
        if (_tgsCache.length >= _maxCacheSize) {
          _tgsCache.clear();
        }

        // Cache to memory + disk
        _tgsCache[stickerId] = bytes;
        await _saveTgsToDisk(stickerId, bytes);
        print('[StoreService] Successfully downloaded $stickerId (${bytes.length} bytes)');
        return bytes;
      } else {
        print('[StoreService] Download failed for $stickerId: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('[StoreService] Download error for $stickerId: $e');
    }

    return null;
  }

  Future<void> prefetchStickers(List<String> stickerIds) async {
    for (final id in stickerIds) {
      if (!_tgsCache.containsKey(id)) {
        // This will trigger download and disk save if not already cached
        await getStickerBytes(id);
      }
    }
  }

  Future<Uint8List?> _loadTgsFromDisk(String id) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/tgs_cache/$id.tgs');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveTgsToDisk(String id, Uint8List bytes) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final cacheDir = Directory('${dir.path}/tgs_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      final file = File('${cacheDir.path}/$id.tgs');
      await file.writeAsBytes(bytes);
    } catch (_) {}
  }

  // Clear TGS disk cache
  Future<void> clearTgsCache() async {
    try {
      _tgsCache.clear();
      final dir = await getApplicationSupportDirectory();
      final cacheDir = Directory('${dir.path}/tgs_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  // ── USER STATS PING ──────────────────

  Future<void> pingUserStats({
    required String userId,
    required int xpTotal,
    required int tasksCompleted,
    required List<String> packsOwned,
  }) async {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) return;

    try {
      await http
          .post(
            Uri.parse('$url/functions/v1/update-stats'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $anonKey',
            },
            body: jsonEncode({
              'userId': userId,
              'xpTotal': xpTotal,
              'tasksCompleted': tasksCompleted,
              'packsOwned': packsOwned,
              'appVersion': '1.0.0',
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    // Fire and forget — ignore errors
  }

  // ── CONNECTIVITY CHECK ───────────────

  Future<bool> checkConnectivity() async {
    try {
      // Use a "Generator 204" endpoint — industry standard for connectivity checks.
      // It returns an empty body with 204 No Content.
      final response = await http.get(Uri.parse('https://www.google.com/generate_204'))
          .timeout(const Duration(seconds: 8));
      
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('[StoreService] Public connectivity check failed: $e');
      
      // Fallback: Try a small request to Supabase directly
      try {
        final url = dotenv.env['SUPABASE_URL'] ?? '';
        if (url.isEmpty) return false;
        final res = await http.get(Uri.parse('$url/rest/v1/')).timeout(const Duration(seconds: 5));
        return res.statusCode < 500; // Almost any response from Supabase means we are online
      } catch (_) {
        return false;
      }
    }
  }
}

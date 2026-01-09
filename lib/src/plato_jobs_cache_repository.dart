import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'plato_jobs_cache_info.dart';

/// Repository for managing cache metadata
class PlatoJobsCacheRepository {
  final String databaseName;
  final Directory cacheDir;
  File? _metadataFile;
  final Map<String, PlatoJobsCacheInfo> _cache = {};

  PlatoJobsCacheRepository({
    required this.databaseName,
    required this.cacheDir,
  }) {
    _metadataFile = File(path.join(cacheDir.path, databaseName));
  }

  /// Load cache metadata from disk
  Future<void> load() async {
    try {
      if (_metadataFile != null && await _metadataFile!.exists()) {
        final content = await _metadataFile!.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _cache.clear();

        for (final entry in json.entries) {
          try {
            final filePath = entry.value['filePath'] as String?;
            if (filePath != null) {
              final file = File(filePath);
              if (await file.exists()) {
                _cache[entry.key] = PlatoJobsCacheInfo.fromJson(
                  entry.value as Map<String, dynamic>,
                  file,
                );
              }
            }
          } catch (e) {
            // Skip invalid entries
          }
        }
      }
    } catch (e) {
      // If loading fails, start with empty cache
      _cache.clear();
    }
  }

  /// Save cache metadata to disk
  Future<void> save() async {
    try {
      if (_metadataFile != null) {
        final json = <String, dynamic>{};
        for (final entry in _cache.entries) {
          json[entry.key] = entry.value.toJson();
        }
        await _metadataFile!.writeAsString(jsonEncode(json));
      }
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Get cache info for a key
  PlatoJobsCacheInfo? get(String key) {
    return _cache[key];
  }

  /// Put cache info
  Future<void> put(PlatoJobsCacheInfo info) async {
    _cache[info.key] = info;
    await save();
  }

  /// Remove cache info
  Future<void> remove(String key) async {
    _cache.remove(key);
    await save();
  }

  /// Get all cache keys
  List<String> getAllKeys() {
    return _cache.keys.toList();
  }

  /// Get all cache info
  List<PlatoJobsCacheInfo> getAll() {
    return _cache.values.toList();
  }

  /// Clear all cache info
  Future<void> clear() async {
    _cache.clear();
    await save();
  }

  /// Update access info
  Future<void> updateAccess(String key) async {
    final info = _cache[key];
    if (info != null) {
      _cache[key] = info.copyWith(
        lastAccessed: DateTime.now(),
        accessCount: info.accessCount + 1,
      );
      await save();
    }
  }
}

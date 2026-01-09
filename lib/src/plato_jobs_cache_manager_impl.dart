import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'plato_jobs_cache_config.dart';
import 'plato_jobs_cache_stats.dart';
import 'plato_jobs_cache_strategy.dart';
import 'plato_jobs_cache_info.dart';
import 'plato_jobs_cache_repository.dart';
import 'plato_jobs_file_response.dart';

/// A powerful cache manager for Flutter with enhanced features
class PlatoJobsCacheManager {
  static final Map<String, PlatoJobsCacheManager> _instances = {};

  final String key;
  final PlatoJobsCacheConfig config;
  final PlatoJobsCacheStrategy strategy;
  late final PlatoJobsCacheRepository _repository;
  final PlatoJobsCacheStats _stats = PlatoJobsCacheStats();
  Timer? _cleanupTimer;
  final Map<String, Completer<File>> _downloadCompleters = {};
  int _activeDownloads = 0;
  late final Directory _cacheDir;
  final http.Client _httpClient = http.Client();

  /// Create or get a cache manager instance
  factory PlatoJobsCacheManager({
    String? key,
    PlatoJobsCacheConfig? config,
    PlatoJobsCacheStrategy? strategy,
  }) {
    final cacheKey = key ?? 'plato_jobs_default';
    if (!_instances.containsKey(cacheKey)) {
      _instances[cacheKey] = PlatoJobsCacheManager._internal(
        key: cacheKey,
        config: config ?? const PlatoJobsCacheConfig(),
        strategy: strategy ?? const PlatoJobsCacheStrategy(),
      );
    }
    return _instances[cacheKey]!;
  }

  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  PlatoJobsCacheManager._internal({
    required this.key,
    required this.config,
    required this.strategy,
  }) {
    _initializeCacheManager();
  }

  Future<void> _initializeCacheManager() async {
    if (_initialized) return;
    if (_initCompleter.isCompleted) {
      await _initCompleter.future;
      return;
    }

    try {
      _cacheDir = await _getCacheDirectory();
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }

      _repository = PlatoJobsCacheRepository(
        databaseName: 'plato_jobs_${key}_cache.json',
        cacheDir: _cacheDir,
      );

      await _repository.load();

      if (config.autoCleanup) {
        _startCleanupTimer();
      }

      _initialized = true;
      _initCompleter.complete();
    } catch (e) {
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initializeCacheManager();
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(config.cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// Get platform version
  Future<String?> getPlatformVersion() async {
    try {
      return Platform.operatingSystemVersion;
    } catch (e) {
      return null;
    }
  }

  /// Get a file from cache or download it
  Future<File> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool force = false,
  }) async {
    await _ensureInitialized();
    final cacheKey = key ?? url;
    final now = DateTime.now();

    // Check if already downloading
    if (_downloadCompleters.containsKey(cacheKey)) {
      return _downloadCompleters[cacheKey]!.future;
    }

    try {
      File? file;

      if (!force) {
        // Try to get from cache
        final cacheInfo = _repository.get(cacheKey);
        if (cacheInfo != null && cacheInfo.isValid) {
          file = cacheInfo.file;
          if (await PlatoJobsCacheFileHelper.isValidFile(file)) {
            // Update access info
            await _repository.updateAccess(cacheKey);
            if (config.enableStats) {
              _stats.hits++;
            }
            return file;
          } else {
            // File is invalid, remove from cache
            await _repository.remove(cacheKey);
            try {
              await file.delete();
            } catch (e) {
              // Ignore deletion errors
            }
          }
        }
      }

      if (config.enableStats) {
        _stats.misses++;
      }

      // Wait for available download slot
      await _waitForDownloadSlot();

      // Download file
      final completer = Completer<File>();
      _downloadCompleters[cacheKey] = completer;

      try {
        _activeDownloads++;
        if (config.enableStats) {
          _stats.downloads++;
        }

        file = await _downloadFile(url, cacheKey, headers ?? config.headers);

        // Rename file with plato_jobs prefix if needed
        file = await _ensurePlatoJobsPrefix(file, cacheKey);

        // Save cache info
        final cacheInfo = PlatoJobsCacheInfo(
          key: cacheKey,
          file: file,
          validTill: now.add(config.maxAge),
          lastAccessed: now,
          accessCount: 1,
          fileSize: await file.length(),
          url: url,
        );
        await _repository.put(cacheInfo);

        completer.complete(file);
        return file;
      } finally {
        _activeDownloads--;
        _downloadCompleters.remove(cacheKey);
      }
    } catch (e) {
      if (config.enableStats) {
        _stats.misses++;
      }
      rethrow;
    }
  }

  /// Download file from URL
  Future<File> _downloadFile(
    String url,
    String cacheKey,
    Map<String, String>? headers,
  ) async {
    final uri = Uri.parse(url);
    final request = http.Request('GET', uri);
    
    if (headers != null) {
      request.headers.addAll(headers);
    }

    final response = await _httpClient.send(request);
    
    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to download file: ${response.statusCode}',
        uri: uri,
      );
    }

    // Generate file name
    final fileName = _generateFileName(cacheKey, url, response);
    final file = File(path.join(_cacheDir.path, fileName));

    // Write file
    final sink = file.openWrite();
    try {
      await response.stream.forEach((chunk) {
        sink.add(chunk);
      });
    } finally {
      await sink.close();
    }

    return file;
  }

  /// Generate file name for cache
  String _generateFileName(String key, String url, http.StreamedResponse response) {
    // Try to get file name from URL
    final uri = Uri.parse(url);
    var fileName = path.basename(uri.path);
    
    // If no extension, try to get from content-type
    if (!fileName.contains('.')) {
      final contentType = response.headers['content-type'];
      if (contentType != null) {
        final ext = _getExtensionFromContentType(contentType);
        fileName = 'plato_jobs_${_hashKey(key)}$ext';
      } else {
        fileName = 'plato_jobs_${_hashKey(key)}';
      }
    } else {
      fileName = 'plato_jobs_$fileName';
    }

    // Ensure unique file name
    return fileName;
  }

  String _hashKey(String key) {
    return key.hashCode.toUnsigned(20).toRadixString(16);
  }

  String _getExtensionFromContentType(String contentType) {
    final parts = contentType.split(';');
    final type = parts[0].trim();
    
    final extensions = {
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/gif': '.gif',
      'image/webp': '.webp',
      'application/json': '.json',
      'application/pdf': '.pdf',
      'text/html': '.html',
      'text/plain': '.txt',
    };

    return extensions[type] ?? '.bin';
  }

  /// Get file stream (for progressive download)
  Stream<PlatoJobsFileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    await _ensureInitialized();
    final cacheKey = key ?? url;

    // Check cache first
    final cacheInfo = _repository.get(cacheKey);
    if (cacheInfo != null && cacheInfo.isValid) {
      await _repository.updateAccess(cacheKey);
      if (config.enableStats) {
        _stats.hits++;
      }
      yield PlatoJobsFileInfo(
        file: cacheInfo.file,
        url: url,
        validTill: cacheInfo.validTill,
      );
      return;
    }

    if (config.enableStats) {
      _stats.misses++;
    }

    // Download with progress
    final uri = Uri.parse(url);
    final request = http.Request('GET', uri);
    
    if (headers != null) {
      request.headers.addAll(headers);
    } else if (config.headers != null) {
      request.headers.addAll(config.headers!);
    }

    final response = await _httpClient.send(request);
    
    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to download file: ${response.statusCode}',
        uri: uri,
      );
    }

    final contentLength = response.contentLength ?? 0;
    final fileName = _generateFileName(cacheKey, url, response);
    final file = File(path.join(_cacheDir.path, fileName));
    final sink = file.openWrite();

    int downloaded = 0;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;

        if (withProgress && contentLength > 0) {
          yield PlatoJobsDownloadProgress(
            url: url,
            downloaded: downloaded,
            total: contentLength,
          );
        }
      }
    } finally {
      await sink.close();
    }

    // Save cache info
    final now = DateTime.now();
    final cacheInfoNew = PlatoJobsCacheInfo(
      key: cacheKey,
      file: file,
      validTill: now.add(config.maxAge),
      lastAccessed: now,
      accessCount: 1,
      fileSize: await file.length(),
      url: url,
    );
    await _repository.put(cacheInfoNew);

    yield PlatoJobsFileInfo(
      file: file,
      url: url,
      validTill: cacheInfoNew.validTill,
    );
  }

  /// Preload files in background
  Future<void> preloadFiles(List<String> urls) async {
    if (!strategy.enablePreload) return;

    for (final url in urls) {
      // Don't wait for completion, just trigger download
      getFile(url).catchError((_) {
        // Ignore errors in preload
        return File('');
      });
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await _ensureInitialized();
    final allKeys = _repository.getAllKeys();
    for (final key in allKeys) {
      final info = _repository.get(key);
      if (info != null) {
        try {
          await info.file.delete();
        } catch (e) {
          // Ignore deletion errors
        }
      }
    }
    await _repository.clear();
    _downloadCompleters.clear();
    if (config.enableStats) {
      _stats.reset();
    }
  }

  /// Remove a specific file from cache
  Future<void> removeFile(String key) async {
    await _ensureInitialized();
    final info = _repository.get(key);
    if (info != null) {
      try {
        await info.file.delete();
      } catch (e) {
        // Ignore deletion errors
      }
    }
    await _repository.remove(key);
  }

  /// Get cache statistics
  PlatoJobsCacheStats getStats() {
    if (!config.enableStats) {
      throw StateError('Statistics are not enabled');
    }
    return _stats;
  }

  /// Get cache info for a specific key
  Future<PlatoJobsCacheInfo?> getCacheInfo(String key) async {
    await _ensureInitialized();
    return _repository.get(key);
  }

  /// Get all cached file keys
  Future<List<String>> getCachedKeys() async {
    await _ensureInitialized();
    return _repository.getAllKeys();
  }

  /// Get total cache size
  Future<int> getCacheSize() async {
    await _ensureInitialized();
    try {
      if (!await _cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in _cacheDir.list(recursive: true)) {
        if (entity is File && entity.path.contains('plato_jobs')) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Perform manual cleanup
  Future<void> cleanup() async {
    await _ensureInitialized();
    await _performCleanup();
  }

  Future<void> _performCleanup() async {
    try {
      final now = DateTime.now();
      final allInfo = _repository.getAll();
      final filesToDelete = <PlatoJobsCacheInfo>[];

      for (final info in allInfo) {
        // Check if file is expired
        if (!info.isValid || now.isAfter(info.validTill)) {
          filesToDelete.add(info);
          continue;
        }

        // Check cache size limit
        if (config.maxCacheSize != null) {
          final currentSize = await getCacheSize();
          if (currentSize > config.maxCacheSize!) {
            // Add to eviction list based on strategy
            filesToDelete.addAll(
              await _getFilesToEvict(allInfo, currentSize),
            );
            break;
          }
        }
      }

      // Check max number of cache objects
      if (allInfo.length > config.maxNrOfCacheObjects) {
        final sorted = _sortForEviction(allInfo);
        final toRemove = sorted.take(
          allInfo.length - config.maxNrOfCacheObjects,
        ).toList();
        filesToDelete.addAll(toRemove);
      }

      // Delete files
      for (final info in filesToDelete) {
        try {
          await info.file.delete();
          await _repository.remove(info.key);
          if (config.enableStats) {
            _stats.evictions++;
          }
        } catch (e) {
          // Ignore deletion errors
        }
      }

      if (config.enableStats) {
        _stats.lastCleanup = now;
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  List<PlatoJobsCacheInfo> _sortForEviction(List<PlatoJobsCacheInfo> files) {
    switch (strategy.evictionStrategy) {
      case PlatoJobsCacheEvictionStrategy.lru:
        files.sort((a, b) {
          final aTime = a.lastAccessed ?? a.validTill;
          final bTime = b.lastAccessed ?? b.validTill;
          return aTime.compareTo(bTime);
        });
        break;
      case PlatoJobsCacheEvictionStrategy.lfu:
        files.sort((a, b) => a.accessCount.compareTo(b.accessCount));
        break;
      case PlatoJobsCacheEvictionStrategy.fifo:
        files.sort((a, b) => a.validTill.compareTo(b.validTill));
        break;
      case PlatoJobsCacheEvictionStrategy.size:
        files.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
    }
    return files;
  }

  Future<List<PlatoJobsCacheInfo>> _getFilesToEvict(
    List<PlatoJobsCacheInfo> allInfo,
    int currentSize,
  ) async {
    final sorted = _sortForEviction(List.from(allInfo));
    final toEvict = <PlatoJobsCacheInfo>[];
    int sizeToFree = currentSize - (config.maxCacheSize ?? 0);

    for (final info in sorted) {
      if (sizeToFree <= 0) break;
      toEvict.add(info);
      sizeToFree -= info.fileSize;
    }

    return toEvict;
  }

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getTemporaryDirectory();
    return Directory(path.join(appDir.path, config.cacheDir));
  }

  Future<File> _ensurePlatoJobsPrefix(File file, String key) async {
    final fileName = path.basename(file.path);
    if (fileName.startsWith('plato_jobs_')) {
      return file;
    }

    final newFileName = 'plato_jobs_$fileName';
    final newPath = path.join(path.dirname(file.path), newFileName);
    try {
      return await file.rename(newPath);
    } catch (e) {
      // If rename fails, return original file
      return file;
    }
  }

  Future<void> _waitForDownloadSlot() async {
    while (_activeDownloads >= config.maxConcurrentDownloads) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _downloadCompleters.clear();
    _httpClient.close();
    _instances.remove(key);
  }
}

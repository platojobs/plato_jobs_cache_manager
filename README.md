# PlatoJobs Cache Manager

A powerful, standalone cache manager plugin for Flutter, supporting Android and iOS platforms with enhanced features. This plugin is completely independent and does not rely on `flutter_cache_manager`, providing a lightweight and efficient caching solution.

## Features

- ✅ **File Caching**: Download and cache files from URLs
- ✅ **Automatic Cache Management**: Automatic cleanup of expired files
- ✅ **Cache Statistics**: Track cache hits, misses, downloads, and evictions
- ✅ **Configurable Cache Strategy**: Support for LRU, LFU, FIFO, and size-based eviction
- ✅ **Concurrent Downloads**: Control maximum concurrent downloads
- ✅ **Custom Headers**: Support for custom HTTP headers
- ✅ **Cache Size Limits**: Set maximum cache size
- ✅ **File Preloading**: Preload files in background
- ✅ **Progressive Download**: Stream file downloads with progress
- ✅ **Unified File Naming**: All cached files are prefixed with `plato_jobs_`

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  plato_jobs_cache_manager:
    path: ../plato_jobs_cache_manager
```

Or if published to pub.dev:

```yaml
dependencies:
  plato_jobs_cache_manager: ^1.0.0
```

## Usage

### Basic Usage

```dart
import 'package:plato_jobs_cache_manager/plato_jobs_cache_manager.dart';

// Create a cache manager instance
final cacheManager = PlatoJobsCacheManager();

// Download and cache a file
final file = await cacheManager.getFile('https://example.com/image.jpg');

// Use the cached file
print('File path: ${file.path}');
```

### Advanced Configuration

```dart
import 'package:plato_jobs_cache_manager/plato_jobs_cache_manager.dart';

// Create a cache manager with custom configuration
final cacheManager = PlatoJobsCacheManager(
  key: 'my_cache',
  config: PlatoJobsCacheConfig(
    maxAge: Duration(days: 30),
    maxNrOfCacheObjects: 500,
    maxCacheSize: 100 * 1024 * 1024, // 100 MB
    enableStats: true,
    autoCleanup: true,
    cleanupInterval: Duration(hours: 12),
    maxConcurrentDownloads: 10,
    headers: {
      'Authorization': 'Bearer token',
    },
  ),
  strategy: PlatoJobsCacheStrategy(
    evictionStrategy: PlatoJobsCacheEvictionStrategy.lru,
    validationStrategy: PlatoJobsCacheValidationStrategy.ageBased,
    enablePreload: true,
    enableBackgroundDownload: true,
  ),
);
```

### Get File with Stream (Progressive Download)

```dart
final stream = cacheManager.getFileStream(
  'https://example.com/large-file.zip',
  withProgress: true,
);

await for (final response in stream) {
  if (response is DownloadProgress) {
    print('Progress: ${response.progress}');
  } else if (response is FileInfo) {
    print('File downloaded: ${response.file.path}');
  }
}
```

### Cache Statistics

```dart
final stats = cacheManager.getStats();
print('Cache hits: ${stats.hits}');
print('Cache misses: ${stats.misses}');
print('Hit rate: ${(stats.hitRate * 100).toStringAsFixed(2)}%');
print('Total downloads: ${stats.downloads}');
print('Total evictions: ${stats.evictions}');
```

### Preload Files

```dart
// Preload multiple files in background
await cacheManager.preloadFiles([
  'https://example.com/image1.jpg',
  'https://example.com/image2.jpg',
  'https://example.com/image3.jpg',
]);
```

### Cache Management

```dart
// Get cache size
final size = await cacheManager.getCacheSize();
print('Cache size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');

// Clear all cache
await cacheManager.clearCache();

// Remove specific file
await cacheManager.removeFile('https://example.com/image.jpg');

// Manual cleanup
await cacheManager.cleanup();
```

## Configuration Options

### PlatoJobsCacheConfig

- `maxAge`: Maximum age for cached files (default: 7 days)
- `maxNrOfCacheObjects`: Maximum number of cache objects (default: 200)
- `maxCacheSize`: Maximum cache size in bytes (null = unlimited)
- `cacheDir`: Cache directory name (default: 'plato_jobs_cache')
- `enableStats`: Enable cache statistics (default: true)
- `autoCleanup`: Enable automatic cache cleanup (default: true)
- `cleanupInterval`: Cleanup interval (default: 24 hours)
- `maxConcurrentDownloads`: Maximum concurrent downloads (default: 5)
- `headers`: Custom HTTP headers for requests

### PlatoJobsCacheStrategy

- `evictionStrategy`: Cache eviction strategy (LRU, LFU, FIFO, Size)
- `validationStrategy`: Cache validation strategy (Always, Never, AgeBased)
- `enablePreload`: Enable file preloading (default: false)
- `enableBackgroundDownload`: Enable background downloads (default: false)

## Platform Support

- ✅ Android (minSdk: 24)
- ✅ iOS (minVersion: 13.0)
- ✅ Swift Package Manager (iOS)

## Key Features

1. **Standalone Implementation**: No dependency on `flutter_cache_manager` - completely independent
2. **Lightweight**: Minimal dependencies, only uses `http`, `path_provider`, and `path` packages
3. **Enhanced Features**: Cache statistics, preloading, and advanced eviction strategies
4. **Better Performance**: Optimized for concurrent downloads and efficient cache management
5. **Unified Naming**: All cached files are prefixed with `plato_jobs_` for easy identification
6. **More Configuration Options**: More granular control over cache behavior
7. **Better Error Handling**: Improved error handling and recovery
8. **JSON-based Metadata**: Simple JSON file-based cache metadata storage

## License

See LICENSE file for details.

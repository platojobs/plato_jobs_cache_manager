import 'dart:io';

/// Cache eviction strategy
enum PlatoJobsCacheEvictionStrategy {
  /// Least Recently Used - evict least recently used files first
  lru,

  /// Least Frequently Used - evict least frequently used files first
  lfu,

  /// First In First Out - evict oldest files first
  fifo,

  /// Size-based - evict largest files first
  size,
}

/// Cache validation strategy
enum PlatoJobsCacheValidationStrategy {
  /// Always validate cache (check if file exists and is valid)
  always,

  /// Never validate (trust cache)
  never,

  /// Validate based on file age
  ageBased,
}

/// Cache strategy configuration
class PlatoJobsCacheStrategy {
  /// Eviction strategy
  final PlatoJobsCacheEvictionStrategy evictionStrategy;

  /// Validation strategy
  final PlatoJobsCacheValidationStrategy validationStrategy;

  /// Whether to preload frequently accessed files
  final bool enablePreload;

  /// Whether to enable background download
  final bool enableBackgroundDownload;

  const PlatoJobsCacheStrategy({
    this.evictionStrategy = PlatoJobsCacheEvictionStrategy.lru,
    this.validationStrategy = PlatoJobsCacheValidationStrategy.ageBased,
    this.enablePreload = false,
    this.enableBackgroundDownload = false,
  });

  /// Create a copy with modified values
  PlatoJobsCacheStrategy copyWith({
    PlatoJobsCacheEvictionStrategy? evictionStrategy,
    PlatoJobsCacheValidationStrategy? validationStrategy,
    bool? enablePreload,
    bool? enableBackgroundDownload,
  }) {
    return PlatoJobsCacheStrategy(
      evictionStrategy: evictionStrategy ?? this.evictionStrategy,
      validationStrategy: validationStrategy ?? this.validationStrategy,
      enablePreload: enablePreload ?? this.enablePreload,
      enableBackgroundDownload:
          enableBackgroundDownload ?? this.enableBackgroundDownload,
    );
  }
}

/// Helper class for cache file operations
class PlatoJobsCacheFileHelper {
  /// Get file size in bytes
  static Future<int> getFileSize(File file) async {
    try {
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      // Ignore errors
    }
    return 0;
  }

  /// Get file last modified time
  static Future<DateTime?> getLastModified(File file) async {
    try {
      if (await file.exists()) {
        return await file.lastModified();
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  /// Check if file is valid (exists and not empty)
  static Future<bool> isValidFile(File file) async {
    try {
      if (await file.exists()) {
        final size = await file.length();
        return size > 0;
      }
    } catch (e) {
      // Ignore errors
    }
    return false;
  }
}

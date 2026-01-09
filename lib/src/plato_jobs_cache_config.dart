/// Cache configuration for PlatoJobsCacheManager
class PlatoJobsCacheConfig {
  /// Maximum age for cached files
  final Duration maxAge;

  /// Maximum number of cache objects
  final int maxNrOfCacheObjects;

  /// Maximum cache size in bytes (null means unlimited)
  final int? maxCacheSize;

  /// Cache directory name (will be prefixed with plato_jobs_)
  final String cacheDir;

  /// Whether to enable cache statistics
  final bool enableStats;

  /// Whether to enable automatic cache cleanup
  final bool autoCleanup;

  /// Cleanup interval
  final Duration cleanupInterval;

  /// Maximum concurrent downloads
  final int maxConcurrentDownloads;

  /// Custom headers for HTTP requests
  final Map<String, String>? headers;

  const PlatoJobsCacheConfig({
    this.maxAge = const Duration(days: 7),
    this.maxNrOfCacheObjects = 200,
    this.maxCacheSize,
    this.cacheDir = 'plato_jobs_cache',
    this.enableStats = true,
    this.autoCleanup = true,
    this.cleanupInterval = const Duration(hours: 24),
    this.maxConcurrentDownloads = 5,
    this.headers,
  });

  /// Create a copy with modified values
  PlatoJobsCacheConfig copyWith({
    Duration? maxAge,
    int? maxNrOfCacheObjects,
    int? maxCacheSize,
    String? cacheDir,
    bool? enableStats,
    bool? autoCleanup,
    Duration? cleanupInterval,
    int? maxConcurrentDownloads,
    Map<String, String>? headers,
  }) {
    return PlatoJobsCacheConfig(
      maxAge: maxAge ?? this.maxAge,
      maxNrOfCacheObjects: maxNrOfCacheObjects ?? this.maxNrOfCacheObjects,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      cacheDir: cacheDir ?? this.cacheDir,
      enableStats: enableStats ?? this.enableStats,
      autoCleanup: autoCleanup ?? this.autoCleanup,
      cleanupInterval: cleanupInterval ?? this.cleanupInterval,
      maxConcurrentDownloads: maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      headers: headers ?? this.headers,
    );
  }
}

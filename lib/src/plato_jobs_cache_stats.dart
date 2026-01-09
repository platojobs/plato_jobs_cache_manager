/// Cache statistics for monitoring cache performance
class PlatoJobsCacheStats {
  /// Total number of cache hits
  int hits = 0;

  /// Total number of cache misses
  int misses = 0;

  /// Total number of files downloaded
  int downloads = 0;

  /// Total number of files evicted
  int evictions = 0;

  /// Total cache size in bytes
  int totalSize = 0;

  /// Number of cached files
  int fileCount = 0;

  /// Last cleanup time
  DateTime? lastCleanup;

  /// Cache hit rate (hits / (hits + misses))
  double get hitRate {
    final total = hits + misses;
    if (total == 0) return 0.0;
    return hits / total;
  }

  /// Reset all statistics
  void reset() {
    hits = 0;
    misses = 0;
    downloads = 0;
    evictions = 0;
    totalSize = 0;
    fileCount = 0;
    lastCleanup = null;
  }

  /// Get statistics as a map
  Map<String, dynamic> toMap() {
    return {
      'hits': hits,
      'misses': misses,
      'downloads': downloads,
      'evictions': evictions,
      'totalSize': totalSize,
      'fileCount': fileCount,
      'hitRate': hitRate,
      'lastCleanup': lastCleanup?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PlatoJobsCacheStats('
        'hits: $hits, '
        'misses: $misses, '
        'downloads: $downloads, '
        'evictions: $evictions, '
        'totalSize: ${(totalSize / 1024 / 1024).toStringAsFixed(2)}MB, '
        'fileCount: $fileCount, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(2)}%)';
  }
}

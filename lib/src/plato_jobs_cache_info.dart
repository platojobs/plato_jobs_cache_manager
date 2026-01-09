import 'dart:io';

/// Cache information for a cached file
class PlatoJobsCacheInfo {
  /// The URL or key of the cached file
  final String key;

  /// The cached file
  final File file;

  /// When the file was cached
  final DateTime validTill;

  /// When the file was last accessed
  final DateTime? lastAccessed;

  /// Number of times the file was accessed
  final int accessCount;

  /// File size in bytes
  final int fileSize;

  /// Original URL
  final String? url;

  PlatoJobsCacheInfo({
    required this.key,
    required this.file,
    required this.validTill,
    this.lastAccessed,
    this.accessCount = 0,
    this.fileSize = 0,
    this.url,
  });

  /// Check if the cache is still valid
  bool get isValid {
    return DateTime.now().isBefore(validTill) && file.existsSync();
  }

  /// Create from JSON
  factory PlatoJobsCacheInfo.fromJson(Map<String, dynamic> json, File file) {
    return PlatoJobsCacheInfo(
      key: json['key'] as String,
      file: file,
      validTill: DateTime.parse(json['validTill'] as String),
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'] as String)
          : null,
      accessCount: json['accessCount'] as int? ?? 0,
      fileSize: json['fileSize'] as int? ?? 0,
      url: json['url'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'filePath': file.path,
      'validTill': validTill.toIso8601String(),
      'lastAccessed': lastAccessed?.toIso8601String(),
      'accessCount': accessCount,
      'fileSize': fileSize,
      'url': url,
    };
  }

  /// Create a copy with updated values
  PlatoJobsCacheInfo copyWith({
    String? key,
    File? file,
    DateTime? validTill,
    DateTime? lastAccessed,
    int? accessCount,
    int? fileSize,
    String? url,
  }) {
    return PlatoJobsCacheInfo(
      key: key ?? this.key,
      file: file ?? this.file,
      validTill: validTill ?? this.validTill,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      accessCount: accessCount ?? this.accessCount,
      fileSize: fileSize ?? this.fileSize,
      url: url ?? this.url,
    );
  }
}

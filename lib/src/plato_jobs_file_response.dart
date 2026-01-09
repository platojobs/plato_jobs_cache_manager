import 'dart:io';

/// Response type for file stream
abstract class PlatoJobsFileResponse {}

/// File info response
class PlatoJobsFileInfo extends PlatoJobsFileResponse {
  final File file;
  final String url;
  final DateTime validTill;
  final String? eTag;

  PlatoJobsFileInfo({
    required this.file,
    required this.url,
    required this.validTill,
    this.eTag,
  });
}

/// Download progress response
class PlatoJobsDownloadProgress extends PlatoJobsFileResponse {
  final String url;
  final int downloaded;
  final int total;
  final double progress;

  PlatoJobsDownloadProgress({
    required this.url,
    required this.downloaded,
    required this.total,
  }) : progress = total > 0 ? downloaded / total : 0.0;
}

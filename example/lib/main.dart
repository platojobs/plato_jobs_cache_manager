import 'package:flutter/material.dart';
import 'dart:io';
import 'package:plato_jobs_cache_manager/plato_jobs_cache_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _cacheManager = PlatoJobsCacheManager();
  String _status = 'Ready';
  String? _cachedFilePath;
  bool _isLoading = false;
  double _downloadProgress = 0.0;

  // Example image URL
  final String _testImageUrl =
      'https://picsum.photos/800/600'; // Random image for testing

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PlatoJobs Cache Manager Demo'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: $_status',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoading) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(value: _downloadProgress),
                        const SizedBox(height: 8),
                        Text(
                          'Progress: ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _downloadFile,
                icon: const Icon(Icons.download),
                label: const Text('Download & Cache File'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCachedFile,
                icon: const Icon(Icons.file_download),
                label: const Text('Get Cached File'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCacheStats,
                icon: const Icon(Icons.analytics),
                label: const Text('Get Cache Statistics'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _clearCache,
                icon: const Icon(Icons.delete),
                label: const Text('Clear Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCacheSize,
                icon: const Icon(Icons.storage),
                label: const Text('Get Cache Size'),
              ),
              if (_cachedFilePath != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cached File:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _cachedFilePath!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        if (_cachedFilePath!.endsWith('.jpg') ||
                            _cachedFilePath!.endsWith('.png') ||
                            _cachedFilePath!.endsWith('.jpeg'))
                          Image.file(
                            File(_cachedFilePath!),
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isLoading = true;
      _status = 'Downloading...';
      _downloadProgress = 0.0;
    });

    try {
      final file = await _cacheManager.getFile(_testImageUrl);
      setState(() {
        _cachedFilePath = file.path;
        _status = 'File cached successfully!';
        _isLoading = false;
        _downloadProgress = 1.0;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCachedFile() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting cached file...';
    });

    try {
      final file = await _cacheManager.getFile(_testImageUrl);
      setState(() {
        _cachedFilePath = file.path;
        _status = 'File retrieved from cache!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCacheStats() async {
    try {
      final stats = _cacheManager.getStats();
      setState(() {
        _status = 'Cache Statistics:\n${stats.toString()}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _isLoading = true;
      _status = 'Clearing cache...';
    });

    try {
      await _cacheManager.clearCache();
      setState(() {
        _cachedFilePath = null;
        _status = 'Cache cleared successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCacheSize() async {
    setState(() {
      _isLoading = true;
      _status = 'Calculating cache size...';
    });

    try {
      final size = await _cacheManager.getCacheSize();
      final sizeInMB = size / 1024 / 1024;
      setState(() {
        _status = 'Cache Size: ${sizeInMB.toStringAsFixed(2)} MB';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }
}

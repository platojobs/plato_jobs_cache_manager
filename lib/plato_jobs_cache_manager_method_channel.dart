import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'plato_jobs_cache_manager_platform_interface.dart';

/// An implementation of [PlatoJobsCacheManagerPlatform] that uses method channels.
class MethodChannelPlatoJobsCacheManager extends PlatoJobsCacheManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('plato_jobs_cache_manager');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

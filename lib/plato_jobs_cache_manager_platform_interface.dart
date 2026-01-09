import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'plato_jobs_cache_manager_method_channel.dart';

abstract class PlatoJobsCacheManagerPlatform extends PlatformInterface {
  /// Constructs a PlatoJobsCacheManagerPlatform.
  PlatoJobsCacheManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static PlatoJobsCacheManagerPlatform _instance = MethodChannelPlatoJobsCacheManager();

  /// The default instance of [PlatoJobsCacheManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelPlatoJobsCacheManager].
  static PlatoJobsCacheManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PlatoJobsCacheManagerPlatform] when
  /// they register themselves.
  static set instance(PlatoJobsCacheManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

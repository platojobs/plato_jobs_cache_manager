import 'package:flutter_test/flutter_test.dart';
import 'package:plato_jobs_cache_manager/plato_jobs_cache_manager_platform_interface.dart';
import 'package:plato_jobs_cache_manager/plato_jobs_cache_manager_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPlatoJobsCacheManagerPlatform
    with MockPlatformInterfaceMixin
    implements PlatoJobsCacheManagerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PlatoJobsCacheManagerPlatform initialPlatform = PlatoJobsCacheManagerPlatform.instance;

  test('$MethodChannelPlatoJobsCacheManager is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPlatoJobsCacheManager>());
  });

  test('getPlatformVersion directly from platform', () async {
    // Test the platform interface directly
    MockPlatoJobsCacheManagerPlatform fakePlatform = MockPlatoJobsCacheManagerPlatform();
    PlatoJobsCacheManagerPlatform.instance = fakePlatform;

    expect(await PlatoJobsCacheManagerPlatform.instance.getPlatformVersion(), '42');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:screen_time_api_ios/screen_time_api_ios.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_method_channel.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

class MockScreenTimeApiIosPlatform
    with MockPlatformInterfaceMixin
    implements ScreenTimeApiIosPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Map<String, dynamic>> requestAuthorization() => Future.value({});

  @override
  Future<Map<String, dynamic>> getAuthorizationStatus() => Future.value({});

  @override
  Future<FamilyActivitySelection> selectAppsToDiscourage() =>
      Future.value(FamilyActivitySelection.empty());

  @override
  Future<FamilyActivitySelection> getDiscouragedApps() =>
      Future.value(FamilyActivitySelection.empty());

  @override
  Future<void> encourageAll() => Future.value();
}

void main() {
  final initialPlatform = ScreenTimeApiIosPlatform.instance;

  test('$MethodChannelScreenTimeApiIos is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelScreenTimeApiIos>());
  });

  test('getPlatformVersion', () async {
    final screenTimeApiIosPlugin = ScreenTimeApiIos();
    final fakePlatform = MockScreenTimeApiIosPlatform();
    ScreenTimeApiIosPlatform.instance = fakePlatform;

    expect(await screenTimeApiIosPlugin.getPlatformVersion(), '42');
  });
}

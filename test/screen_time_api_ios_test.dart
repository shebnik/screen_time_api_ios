import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:screen_time_api_ios/screen_time_api_ios.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_method_channel.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

class MockScreenTimeApiIosPlatform
    with MockPlatformInterfaceMixin
    implements ScreenTimeApiIosPlatform {
  @override
  Future<Map<String, dynamic>> requestAuthorization() => Future.value({});

  @override
  Future<Map<String, dynamic>> getAuthorizationStatus() => Future.value({});

  @override
  Future<FamilyActivitySelection?> showFamilyActivityPicker(
    Map<String, dynamic>? uiConfig, [
    FamilyActivitySelection? preSelectedApps,
  ]) => Future.value(FamilyActivitySelection.empty());

  @override
  Future<bool> discourageApps(FamilyActivitySelection selection) =>
      Future.value(true);

  @override
  Future<FamilyActivitySelection> getDiscouragedApps() =>
      Future.value(FamilyActivitySelection.empty());

  @override
  Future<void> setAdultWebsiteBlocking({required bool enabled}) =>
      Future.value();

  @override
  Future<bool> getAdultWebsiteBlocking() => Future.value(false);

  @override
  Future<void> encourageAll() => Future.value();

  @override
  Future<void> encourage(FamilyActivitySelection selection) => Future.value();

  @override
  Future<bool> setAppQuotas(QuotaConfiguration quotaConfig) =>
      Future.value(true);

  @override
  Future<QuotaConfiguration> getAppQuotas() =>
      Future.value(QuotaConfiguration.empty());

  @override
  Future<Map<String, dynamic>> configure({
    String? appGroupIdentifier,
    String? logFilePath,
  }) => Future.value({
    'appGroupIdentifier': appGroupIdentifier,
    'logFilePath': logFilePath,
  });

  @override
  Future<WebContentBlockingConfiguration> setWebContentBlocking({
    required bool adultContentBlocked,
    List<String> blockedDomains = const [],
  }) async {
    // Simulate setting web content blocking and return the configuration
    return WebContentBlockingConfiguration(
      adultContentBlocked: adultContentBlocked,
      blockedDomains: blockedDomains,
    );
  }

  @override
  Future<Map<String, dynamic>> getWebContentBlocking() {
    // Simulate getting web content blocking configuration
    return Future.value({
      'adultContentBlocked': false,
    });
  }
}

void main() {
  final initialPlatform = ScreenTimeApiIosPlatform.instance;

  setUp(() {
    ScreenTimeApiIosPlatform.instance = MockScreenTimeApiIosPlatform();
  });

  test('$MethodChannelScreenTimeApiIos is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelScreenTimeApiIos>());
  });

  test('ScreenTimeApiIos throws when not configured', () {
    expect(() => ScreenTimeApiIos(), throwsStateError);
  });

  test('ScreenTimeApiIos can be created after configuration', () async {
    // Configure the plugin
    final config = await ScreenTimeApiIos.configure(
      appGroupIdentifier: 'group.test.example',
      logFilePath: '/test/path',
    );

    expect(config, isNotNull);
    expect(ScreenTimeApiIos.isConfigured, isTrue);
    expect(ScreenTimeApiIos.globalConfiguration, isNotNull);

    // Should be able to create instances now
    expect(() => ScreenTimeApiIos(), returnsNormally);
  });
}

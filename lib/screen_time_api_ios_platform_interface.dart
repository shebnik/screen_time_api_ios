import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:screen_time_api_ios/models/family_activity_selection.dart';
import 'package:screen_time_api_ios/models/quota_configuration.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_method_channel.dart';

abstract class ScreenTimeApiIosPlatform extends PlatformInterface {
  /// Constructs a ScreenTimeApiIosPlatform.
  ScreenTimeApiIosPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScreenTimeApiIosPlatform _instance = MethodChannelScreenTimeApiIos();

  /// The default instance of [ScreenTimeApiIosPlatform] to use.
  ///
  /// Defaults to [MethodChannelScreenTimeApiIos].
  static ScreenTimeApiIosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScreenTimeApiIosPlatform] when
  /// they register themselves.
  static set instance(ScreenTimeApiIosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Configure the plugin with various settings
  /// [appGroupIdentifier] - The app group identifier to use for shared data
  /// [logFilePath] - Optional path for log files
  /// Returns a map with configuration results
  Future<Map<String, dynamic>> configure({
    String? appGroupIdentifier,
    String? logFilePath,
  }) {
    throw UnimplementedError('configure() has not been implemented.');
  }

  Future<bool> configureLogging({required String logFilePath}) {
    throw UnimplementedError('configureLogging() has not been implemented.');
  }

  Future<String> getLogContent() {
    throw UnimplementedError('getLogContent() has not been implemented.');
  }

  Future<bool> clearLogs() {
    throw UnimplementedError('clearLogs() has not been implemented.');
  }

  Future<Map<String, dynamic>> requestAuthorization() {
    throw UnimplementedError(
      'requestAuthorization() has not been implemented.',
    );
  }

  Future<Map<String, dynamic>> getAuthorizationStatus() {
    throw UnimplementedError(
      'getAuthorizationStatus() has not been implemented.',
    );
  }

  Future<FamilyActivitySelection> showFamilyActivityPicker([
    Map<String, dynamic>? uiConfig,
  ]) {
    throw UnimplementedError(
      'showFamilyActivityPicker() has not been implemented.',
    );
  }

  Future<FamilyActivitySelection> getSelectedApps() {
    throw UnimplementedError('getSelectedApps() has not been implemented.');
  }

  Future<bool> discourageApps(FamilyActivitySelection selection) {
    throw UnimplementedError('discourageApps() has not been implemented.');
  }

  Future<FamilyActivitySelection> getDiscouragedApps() {
    throw UnimplementedError('getDiscouragedApps() has not been implemented.');
  }

  Future<void> encourageAll() {
    throw UnimplementedError('encourageAll() has not been implemented.');
  }

  Future<void> setAdultWebsiteBlocking({required bool enabled}) {
    throw UnimplementedError(
      'setAdultWebsiteBlocking() has not been implemented.',
    );
  }

  Future<bool> getAdultWebsiteBlocking() {
    throw UnimplementedError(
      'getAdultWebsiteBlocking() has not been implemented.',
    );
  }

  /// Set blocked domains and adult website blocking together
  /// [adultContentEnabled] - Whether to enable the built-in adult content filter
  /// [blockedDomains] - List of specific domains to block (max 50)
  Future<void> setWebContentBlocking({
    required bool adultContentEnabled,
    List<String> blockedDomains = const [],
  }) {
    throw UnimplementedError(
      'setWebContentBlocking() has not been implemented.',
    );
  }

  /// Get current web content blocking configuration
  /// Returns a map with current settings
  Future<Map<String, dynamic>> getWebContentBlocking() {
    throw UnimplementedError(
      'getWebContentBlocking() has not been implemented.',
    );
  }

  Future<bool> setAppQuotas(QuotaConfiguration quotaConfig) {
    throw UnimplementedError('setAppQuotas() has not been implemented.');
  }

  Future<QuotaConfiguration> getAppQuotas() {
    throw UnimplementedError('getAppQuotas() has not been implemented.');
  }
}

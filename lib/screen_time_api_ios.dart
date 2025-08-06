import 'package:screen_time_api_ios/models/authorization_response.dart';
import 'package:screen_time_api_ios/models/family_activity_selection.dart';
import 'package:screen_time_api_ios/models/quota_configuration.dart';
import 'package:screen_time_api_ios/models/ui_customization.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

// Export models for external use
export 'models/app_quota.dart';
export 'models/authorization_response.dart';
export 'models/authorization_status.dart';
export 'models/family_activity_selection.dart';
export 'models/quota_configuration.dart';
export 'models/token_type.dart';
export 'models/ui_customization.dart';
// Export widgets
export 'widgets/app_label_view.dart';

class ScreenTimeApiIos {
  Future<String?> getPlatformVersion() {
    return ScreenTimeApiIosPlatform.instance.getPlatformVersion();
  }

  /// Configure the plugin with various settings
  /// [appGroupIdentifier] - The app group identifier to use for shared data
  /// between app and extension
  /// [logFilePath] - Optional path where log files should be written
  /// Returns a map containing configuration results and current settings
  Future<Map<String, dynamic>> configure({
    String? appGroupIdentifier,
    String? logFilePath,
  }) {
    return ScreenTimeApiIosPlatform.instance.configure(
      appGroupIdentifier: appGroupIdentifier,
      logFilePath: logFilePath,
    );
  }

  /// Configure logging for the iOS plugin
  /// [logFilePath] - The absolute path where log files should be written
  /// Returns true if logging was configured successfully, false otherwise
  Future<bool> configureLogging({required String logFilePath}) {
    return ScreenTimeApiIosPlatform.instance.configureLogging(
      logFilePath: logFilePath,
    );
  }

  /// Get the current log file content
  /// Returns the content of the log file as a string
  Future<String> getLogContent() {
    return ScreenTimeApiIosPlatform.instance.getLogContent();
  }

  /// Clear all log content
  /// Returns true if logs were cleared successfully, false otherwise
  Future<bool> clearLogs() {
    return ScreenTimeApiIosPlatform.instance.clearLogs();
  }

  /// Request authorization for Screen Time API access
  /// Returns an AuthorizationResponse indicating the result
  Future<AuthorizationResponse> requestAuthorization() async {
    final result = await ScreenTimeApiIosPlatform.instance
        .requestAuthorization();
    return AuthorizationResponse.fromMap(result);
  }

  /// Get the current authorization status for Screen Time API
  /// Returns an AuthorizationResponse with the current status
  Future<AuthorizationResponse> getAuthorizationStatus() async {
    final result = await ScreenTimeApiIosPlatform.instance
        .getAuthorizationStatus();
    return AuthorizationResponse.fromMap(result);
  }

  /// Check if the user is authorized to use Screen Time API
  /// Returns true if authorized, false otherwise
  Future<bool> isAuthorized() async {
    final response = await getAuthorizationStatus();
    return response.status.isAuthorized;
  }

  /// Present the family activity picker with UI customization options
  /// Requires prior authorization - call requestAuthorization() first
  /// Returns a FamilyActivitySelection with separated token types
  /// Throws an exception if not authorized
  ///
  /// [uiCustomization] Optional UICustomization object for customizing the UI
  /// appearance
  Future<FamilyActivitySelection> showFamilyActivityPicker([
    UICustomization? uiCustomization,
  ]) async {
    return ScreenTimeApiIosPlatform.instance.showFamilyActivityPicker(
      uiCustomization?.toMap(),
    );
  }

  /// Get the currently saved/selected apps and categories
  /// Returns the persistent selection that was last saved
  Future<FamilyActivitySelection> getSelectedApps() async {
    return ScreenTimeApiIosPlatform.instance.getSelectedApps();
  }

  /// Apply restrictions to specific apps using provided [selection]
  /// [selection] contains applicationTokens, categoryTokens, or webDomainTokens
  /// Returns true if successful, false otherwise
  Future<bool> discourageApps(FamilyActivitySelection selection) async {
    return ScreenTimeApiIosPlatform.instance.discourageApps(selection);
  }

  /// Get the list of currently discouraged apps/categories
  /// Returns a FamilyActivitySelection with separated token types
  Future<FamilyActivitySelection> getDiscouragedApps() async {
    return ScreenTimeApiIosPlatform.instance.getDiscouragedApps();
  }

  /// Remove all app restrictions and encourage all apps
  Future<void> encourageAll() async {
    return ScreenTimeApiIosPlatform.instance.encourageAll();
  }

  /// Enable or disable adult website blocking
  /// Requires prior authorization - call requestAuthorization() first
  /// [enabled] - true to block adult websites, false to allow them
  Future<void> setAdultWebsiteBlocking({required bool enabled}) async {
    return ScreenTimeApiIosPlatform.instance.setAdultWebsiteBlocking(
      enabled: enabled,
    );
  }

  /// Get the current adult website blocking status
  /// Returns true if adult websites are currently blocked, false otherwise
  Future<bool> getAdultWebsiteBlocking() async {
    return ScreenTimeApiIosPlatform.instance.getAdultWebsiteBlocking();
  }

  /// Set comprehensive web content blocking including custom domains
  /// [adultContentEnabled] - Enable built-in adult content filter
  /// [blockedDomains] - List of specific domains to block (max 50)
  ///
  /// Example usage:
  /// ```dart
  /// await api.setWebContentBlocking(
  ///   adultContentEnabled: true,
  ///   blockedDomains: ['facebook.com', 'twitter.com'],
  /// );
  /// ```
  Future<void> setWebContentBlocking({
    required bool adultContentEnabled,
    List<String> blockedDomains = const [],
  }) async {
    return ScreenTimeApiIosPlatform.instance.setWebContentBlocking(
      adultContentEnabled: adultContentEnabled,
      blockedDomains: blockedDomains,
    );
  }

  /// Get current web content blocking configuration
  /// Returns a map containing:
  /// - 'adultContentEnabled': bool
  /// - 'blockedDomains': List<String>
  Future<Map<String, dynamic>> getWebContentBlocking() async {
    return ScreenTimeApiIosPlatform.instance.getWebContentBlocking();
  }

  /// Apply quotas to specific apps instead of completely blocking them
  /// [quotaConfig] contains the quota configuration for each app
  /// Returns true if successful, false otherwise
  Future<bool> setAppQuotas(QuotaConfiguration quotaConfig) async {
    return ScreenTimeApiIosPlatform.instance.setAppQuotas(quotaConfig);
  }

  /// Get the current quota configuration for apps
  /// Returns a QuotaConfiguration with current app quotas
  Future<QuotaConfiguration> getAppQuotas() async {
    return ScreenTimeApiIosPlatform.instance.getAppQuotas();
  }
}

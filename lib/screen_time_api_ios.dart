import 'package:screen_time_api_ios/models/authorization_response.dart';
import 'package:screen_time_api_ios/models/family_activity_selection.dart';
import 'package:screen_time_api_ios/models/plugin_configuration.dart';
import 'package:screen_time_api_ios/models/quota_configuration.dart';
import 'package:screen_time_api_ios/models/ui_customization.dart';
import 'package:screen_time_api_ios/models/web_content_blocking_configuration.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

// Export models for external use
export 'models/app_quota.dart';
export 'models/authorization_response.dart';
export 'models/authorization_status.dart';
export 'models/family_activity_selection.dart';
export 'models/plugin_configuration.dart';
export 'models/quota_configuration.dart';
export 'models/token_type.dart';
export 'models/ui_customization.dart';
export 'models/web_content_blocking_configuration.dart';
// Export widgets
export 'widgets/app_label_view.dart';

class ScreenTimeApiIos {
  /// Constructor that ensures the plugin is configured
  /// If no global configuration exists, this will throw an exception
  ScreenTimeApiIos() {
    if (!_isConfigured) {
      throw StateError(
        'ScreenTimeApiIos must be configured before use. '
        'Call ScreenTimeApiIos.configure() first.',
      );
    }
  }
  // Static configuration state
  static PluginConfiguration? _globalConfiguration;
  static bool _isConfigured = false;

  /// Configure the app's internal settings needed for Screen Time APIs
  ///
  /// This is a static method that configures the plugin globally.
  /// All instances of ScreenTimeApiIos will use this configuration.
  ///
  /// [appGroupIdentifier] is the app group ID configured in Apple Developer Portal
  /// that allows data sharing between the main app and device activity monitor extension
  ///
  /// [logFilePath] specifies where to store plugin logs (optional)
  ///
  /// Returns a [PluginConfiguration] object indicating success or failure
  /// with relevant configuration details
  static Future<PluginConfiguration> configure({
    required String appGroupIdentifier,
    String? logFilePath,
  }) async {
    final result = await ScreenTimeApiIosPlatform.instance.configure(
      appGroupIdentifier: appGroupIdentifier,
      logFilePath: logFilePath,
    );
    _globalConfiguration = PluginConfiguration.fromMap(result);
    _isConfigured = true;
    return _globalConfiguration!;
  }

  /// Get the current global configuration if available
  static PluginConfiguration? get globalConfiguration => _globalConfiguration;

  /// Check if the plugin has been configured globally
  static bool get isConfigured => _isConfigured;

  /// Get configuration status information
  /// Returns a formatted string with current configuration details
  static String getConfigurationStatus() {
    if (!_isConfigured || _globalConfiguration == null) {
      return 'Plugin not configured. Call ScreenTimeApiIos.configure() first.';
    }

    final config = _globalConfiguration!;
    return 'Plugin configured successfully. '
        'App Group: ${config.appGroupIdentifier ?? 'unknown'}. '
        'Is Configured: ${config.isConfigured}. '
        'Log Path: ${config.logFilePath ?? 'not set'}.';
  }

  /// Show the native iOS family activity picker to let users select apps/categories to restrict.
  ///
  /// [uiCustomization] can be used to customize the appearance of the picker
  /// [preSelectedApps] allows showing the picker with pre-selected apps/categories
  ///
  /// Returns the selected apps/categories if user saves, null if user cancels or dismisses.
  /// If user taps reset, it only clears the current selection without closing the picker.
  ///
  /// Example:
  /// ```dart
  /// final selection = await screenTimeApi.showFamilyActivityPicker();
  /// if (selection != null) {
  ///   // User saved a selection
  ///   await screenTimeApi.discourageApps(selection);
  /// } else {
  ///   // User cancelled or dismissed
  /// }
  /// ```
  Future<FamilyActivitySelection?> showFamilyActivityPicker({
    UICustomization? uiCustomization,
    FamilyActivitySelection? preSelectedApps,
  }) async {
    return ScreenTimeApiIosPlatform.instance.showFamilyActivityPicker(
      uiCustomization?.toMap(),
      preSelectedApps,
    );
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

  /// Remove restrictions for specific apps/categories
  /// [selection] contains the apps/categories to remove restrictions from
  ///
  /// This allows you to selectively remove restrictions without affecting other
  /// discouraged apps. Use this when you want to encourage specific apps while
  /// keeping restrictions on others.
  ///
  /// Example:
  /// ```dart
  /// // Remove restrictions only for selected apps
  /// await screenTimeApi.encourage(selectedApps);
  /// ```
  Future<void> encourage(FamilyActivitySelection selection) async {
    return ScreenTimeApiIosPlatform.instance.encourage(selection);
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
  /// [adultContentBlocked] - Enable built-in adult content filter
  /// [blockedDomains] - List of specific domains to block (max 50)
  ///
  /// Returns the current configuration after applying the changes.
  ///
  /// Example usage:
  /// ```dart
  /// final config = await api.setWebContentBlocking(
  ///   adultContentBlocked: true,
  ///   blockedDomains: ['facebook.com', 'twitter.com'],
  /// );
  /// print('Adult content blocked: ${config.adultContentBlocked}');
  /// ```
  Future<WebContentBlockingConfiguration> setWebContentBlocking({
    required bool adultContentBlocked,
    List<String> blockedDomains = const [],
  }) async {
    return ScreenTimeApiIosPlatform.instance.setWebContentBlocking(
      adultContentBlocked: adultContentBlocked,
      blockedDomains: blockedDomains,
    );
  }

  /// Get current web content blocking configuration
  /// Returns a WebContentBlockingConfiguration containing:
  /// - adultContentBlocked: bool
  /// - blockedDomains: List<String>
  Future<WebContentBlockingConfiguration> getWebContentBlocking() async {
    final result = await ScreenTimeApiIosPlatform.instance
        .getWebContentBlocking();
    return WebContentBlockingConfiguration.fromMap(result);
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

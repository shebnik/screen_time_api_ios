import 'package:screen_time_api_ios/models/app_quota.dart';
import 'package:screen_time_api_ios/models/authorization_response.dart';
import 'package:screen_time_api_ios/models/family_activity_selection.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

export 'models/app_quota.dart';
export 'models/authorization_response.dart';
// Export models for external use
export 'models/authorization_status.dart';
export 'models/family_activity_selection.dart';
export 'models/token_type.dart';
// Export widgets
export 'widgets/app_label_view.dart';

class ScreenTimeApiIos {
  Future<String?> getPlatformVersion() {
    return ScreenTimeApiIosPlatform.instance.getPlatformVersion();
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

  /// Present the app selection UI to discourage specific apps
  /// Requires prior authorization - call requestAuthorization() first
  /// Returns a FamilyActivitySelection with separated token types
  /// Throws an exception if not authorized
  Future<FamilyActivitySelection> selectAppsToDiscourage() async {
    return ScreenTimeApiIosPlatform.instance.selectAppsToDiscourage();
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

  /// Set daily quotas for selected apps
  /// [quotas] - Collection of app quotas with daily limits
  /// This method saves the configuration but does not immediately apply
  /// blocking
  /// Call applyQuotaSettings() to enforce the quotas
  Future<void> setAppQuotas(AppQuotaCollection quotas) async {
    return ScreenTimeApiIosPlatform.instance.setAppQuotas(quotas);
  }

  /// Get current app quotas configuration
  /// Returns the saved app quotas with current usage counts
  Future<AppQuotaCollection> getAppQuotas() async {
    return ScreenTimeApiIosPlatform.instance.getAppQuotas();
  }

  /// Apply quota-based blocking to configured apps
  /// Only blocks apps that have exceeded their daily quotas
  /// Should be called after setting quotas and when you want to enforce them
  Future<void> applyQuotaSettings() async {
    return ScreenTimeApiIosPlatform.instance.applyQuotaSettings();
  }

  /// Simulate app usage for testing purposes
  /// [index] - The index of the app/category to simulate usage for
  Future<void> simulateAppUsage(int index) async {
    return ScreenTimeApiIosPlatform.instance.simulateAppUsage(index);
  }

  /// Select apps for quota configuration without immediately blocking them
  /// This replaces the immediate blocking behavior of selectAppsToDiscourage()
  /// Returns the selected apps that can then be configured with quotas
  Future<FamilyActivitySelection> selectAppsForQuotaConfiguration() async {
    return ScreenTimeApiIosPlatform.instance.selectAppsForQuotaConfiguration();
  }
}

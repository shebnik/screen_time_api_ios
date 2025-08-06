import 'package:screen_time_api_ios/models/authorization_response.dart';
import 'package:screen_time_api_ios/models/family_activity_selection.dart';
import 'package:screen_time_api_ios/models/ui_customization.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

// Export models for external use
export 'models/authorization_response.dart';
export 'models/authorization_status.dart';
export 'models/family_activity_selection.dart';
export 'models/token_type.dart';
export 'models/ui_customization.dart';
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
}

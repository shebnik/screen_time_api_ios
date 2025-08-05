import 'package:screen_time_api_ios/models/authorization_response.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

export 'models/authorization_response.dart';
// Export models for external use
export 'models/authorization_status.dart';

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
  /// Returns a list of selected app/category tokens
  /// Throws an exception if not authorized
  Future<List<String>> selectAppsToDiscourage() async {
    return ScreenTimeApiIosPlatform.instance.selectAppsToDiscourage();
  }

  /// Get the list of currently discouraged apps/categories
  /// Returns a list of app/category tokens
  Future<List<String>> getDiscouragedApps() async {
    return ScreenTimeApiIosPlatform.instance.getDiscouragedApps();
  }

  /// Remove all app restrictions and encourage all apps
  Future<void> encourageAll() async {
    return ScreenTimeApiIosPlatform.instance.encourageAll();
  }
}

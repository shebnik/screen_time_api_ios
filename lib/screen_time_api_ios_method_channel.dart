import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_time_api_ios/models/family_activity_selection.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

/// An implementation of [ScreenTimeApiIosPlatform] that uses method channels.
class MethodChannelScreenTimeApiIos extends ScreenTimeApiIosPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('screen_time_api_ios');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<Map<String, dynamic>> requestAuthorization() async {
    final result = await methodChannel.invokeMethod('requestAuthorization');
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return {'status': 'unknown'};
  }

  @override
  Future<Map<String, dynamic>> getAuthorizationStatus() async {
    final result = await methodChannel.invokeMethod('getAuthorizationStatus');
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return {'status': 'unknown'};
  }

  @override
  Future<FamilyActivitySelection> selectAppsToDiscourage() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'selectAppsToDiscourage',
      );
      if (result != null) {
        return FamilyActivitySelection.fromMap(
          Map<String, dynamic>.from(result),
        );
      }
      return FamilyActivitySelection.empty();
    } catch (e) {
      debugPrint('Error in selectAppsToDiscourage: $e');
      return FamilyActivitySelection.empty();
    }
  }

  @override
  Future<FamilyActivitySelection> getDiscouragedApps() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getDiscouragedApps',
      );
      if (result != null) {
        return FamilyActivitySelection.fromMap(
          Map<String, dynamic>.from(result),
        );
      }
      return FamilyActivitySelection.empty();
    } catch (e) {
      debugPrint('Error in getDiscouragedApps: $e');
      return FamilyActivitySelection.empty();
    }
  }

  @override
  Future<void> encourageAll() async {
    await methodChannel.invokeMethod('encourageAll');
  }
}

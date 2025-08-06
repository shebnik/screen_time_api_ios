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
  Future<FamilyActivitySelection> showFamilyActivityPicker([
    Map<String, dynamic>? uiConfig,
  ]) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'showFamilyActivityPicker',
        uiConfig,
      );
      if (result != null) {
        return FamilyActivitySelection.fromMap(
          Map<String, dynamic>.from(result),
        );
      }
      return FamilyActivitySelection.empty();
    } catch (e) {
      debugPrint('Error in showFamilyActivityPicker: $e');
      return FamilyActivitySelection.empty();
    }
  }

  @override
  Future<FamilyActivitySelection> getSelectedApps() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getSelectedApps',
      );
      if (result != null) {
        return FamilyActivitySelection.fromMap(
          Map<String, dynamic>.from(result),
        );
      }
      return FamilyActivitySelection.empty();
    } catch (e) {
      debugPrint('Error in getSelectedApps: $e');
      return FamilyActivitySelection.empty();
    }
  }

  @override
  Future<bool> discourageApps(FamilyActivitySelection selection) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'discourageApps',
        selection.toMap(),
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error in discourageApps: $e');
      return false;
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

  @override
  Future<void> setAdultWebsiteBlocking({required bool enabled}) async {
    await methodChannel.invokeMethod('setAdultWebsiteBlocking', {
      'enabled': enabled,
    });
  }

  @override
  Future<bool> getAdultWebsiteBlocking() async {
    final result = await methodChannel.invokeMethod<bool>(
      'getAdultWebsiteBlocking',
    );
    return result ?? false;
  }
}
